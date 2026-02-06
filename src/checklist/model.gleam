import checklist/data.{type Checklist}
import checklist/effects
import checklist/ffi
import gleam/dict.{type Dict}
import gleam/int
import gleam/list
import gleam/option.{None, Some}
import gleam/result
import gleam/string
import gleam/uri.{type Uri}
import lustre/effect.{type Effect}
import modem
import rada/date.{type Date}

pub type Model {
  Model(
    checklists: Dict(Int, Checklist),
    name: String,
    route: Route,
    today: Date,
    error: option.Option(String),
  )
}

pub type Route {
  Home
  ChecklistPage(id: Int)
  NotFound
}

pub type Msg {
  OnRouteChange(Uri)
  Tick
  SetName(String)
  AddChecklist
  AddItem(Int)
  CheckItem(checklist_id: Int, item_index: Int, checked: Bool)
  Download
  Load
  FileLoaded(String)
}

pub fn init(_flags: Nil) -> #(Model, Effect(Msg)) {
  let today = date.today()

  let checklists_result = load_checklists(today)

  let initial_route = case modem.initial_uri() {
    Ok(uri) -> parse_route(uri)
    Error(_) -> Home
  }

  let #(checklists, error) = case checklists_result {
    Ok(cls) -> #(cls, None)
    Error(err) -> #(dict.new(), Some(err))
  }

  let model = Model(checklists:, name: "", route: initial_route, today:, error:)

  let eff =
    effect.batch([modem.init(OnRouteChange), effects.setup_timer(Tick)])

  #(model, eff)
}

fn load_checklists(today: Date) -> Result(Dict(Int, Checklist), String) {
  case ffi.read_localstorage("data") {
    Error(_) ->
      // Try legacy key
      case ffi.read_localstorage("checklists") {
        Error(_) -> Ok(dict.new())
        Ok(raw) -> {
          let wrapped =
            "{\"version\":1,\"checklists\":" <> raw <> "}"
          parse_and_refresh(wrapped, today)
        }
      }
    Ok(raw) -> parse_and_refresh(raw, today)
  }
}

fn parse_and_refresh(
  json_string: String,
  today: Date,
) -> Result(Dict(Int, Checklist), String) {
  data.decode_data(json_string)
  |> result.map(fn(cls) {
    cls
    |> list.map(fn(c) { data.refresh(c, today) })
    |> list.map(fn(c) { #(c.id, c) })
    |> dict.from_list
  })
}

fn parse_route(uri: Uri) -> Route {
  let segments = uri.path_segments(uri.path)
  case segments {
    [] -> Home
    ["checklists", id_str] ->
      case int.parse(id_str) {
        Ok(id) -> ChecklistPage(id)
        Error(_) -> NotFound
      }
    _ -> NotFound
  }
}

pub fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    OnRouteChange(uri) -> {
      let route = parse_route(uri)
      #(Model(..model, route:, name: ""), effect.none())
    }

    Tick -> {
      let today = date.today()
      let checklists =
        dict.map_values(model.checklists, fn(_id, c) {
          data.refresh(c, today)
        })
      #(Model(..model, today:, checklists:), effect.none())
    }

    SetName(name) -> #(Model(..model, name:), effect.none())

    AddChecklist -> {
      case string.is_empty(model.name) {
        True -> #(model, effect.none())
        False -> {
          let id = next_id(model.checklists)
          let checklist = data.new(id, model.name)
          let checklists = dict.insert(model.checklists, id, checklist)
          let new_model = Model(..model, checklists:, name: "")
          #(
            new_model,
            effect.batch([
              modem.push(data.url(id), None, None),
              effects.save(new_model.checklists),
            ]),
          )
        }
      }
    }

    AddItem(checklist_id) -> {
      case string.is_empty(model.name) {
        True -> #(model, effect.none())
        False -> {
          let checklists =
            dict.upsert(model.checklists, checklist_id, fn(existing) {
              case existing {
                Some(c) -> data.add_item(c, model.name)
                None -> data.new(checklist_id, "Unknown")
              }
            })
          let new_model = Model(..model, checklists:, name: "")
          #(new_model, effects.save(new_model.checklists))
        }
      }
    }

    CheckItem(checklist_id, item_index, checked) -> {
      let checked_date = case checked {
        True -> Some(model.today)
        False -> None
      }
      let checklists =
        dict.upsert(model.checklists, checklist_id, fn(existing) {
          case existing {
            Some(c) -> data.set_item(c, item_index, checked_date)
            None -> data.new(checklist_id, "Unknown")
          }
        })
      let new_model = Model(..model, checklists:)
      #(new_model, effects.save(new_model.checklists))
    }

    Download -> {
      let date_part = date.format(model.today, "y-MMM-d")
      #(model, effects.download(model.checklists, date_part))
    }

    Load -> {
      #(model, effects.select_file(FileLoaded))
    }

    FileLoaded(content) -> {
      case data.decode_data(content) {
        Ok(cls) -> {
          let checklists =
            cls
            |> list.map(fn(c) { #(c.id, c) })
            |> dict.from_list
          let new_model = Model(..model, checklists:)
          #(new_model, effects.save(new_model.checklists))
        }
        Error(_) -> #(model, effect.none())
      }
    }
  }
}

fn next_id(checklists: Dict(Int, Checklist)) -> Int {
  dict.size(checklists) + 1
}
