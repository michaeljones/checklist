import gleam/dynamic/decode.{type Decoder}
import gleam/int
import gleam/json.{type Json}
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/order
import gleam/result
import gleam/string
import rada/date.{type Date}

pub type Checklist {
  Checklist(
    id: Int,
    name: String,
    refresh_mode: RefreshMode,
    items: List(Item),
  )
}

pub type Item {
  Item(name: String, checked: Option(Date), links: List(Link))
}

pub type Link {
  Link(name: String, url: String)
}

pub type RefreshMode {
  Daily
  OnCompletion
}

pub fn new(id: Int, name: String) -> Checklist {
  Checklist(id:, name:, refresh_mode: Daily, items: [])
}

pub fn add_item(checklist: Checklist, name: String) -> Checklist {
  let item = Item(name:, checked: None, links: [])
  Checklist(..checklist, items: list.append(checklist.items, [item]))
}

pub fn set_item(
  checklist: Checklist,
  index: Int,
  checked: Option(Date),
) -> Checklist {
  let items =
    list.index_map(checklist.items, fn(item, i) {
      case i == index {
        True -> Item(..item, checked:)
        False -> item
      }
    })
  Checklist(..checklist, items:)
}

pub fn refresh(checklist: Checklist, today: Date) -> Checklist {
  case checklist.refresh_mode {
    Daily -> refresh_daily(checklist, today)
    OnCompletion -> refresh_on_completion(checklist)
  }
}

fn refresh_daily(checklist: Checklist, today: Date) -> Checklist {
  let items =
    list.map(checklist.items, fn(item) {
      case item.checked {
        None -> item
        Some(checked_date) ->
          case date.compare(checked_date, today) {
            // Checked before today — reset
            order.Lt -> Item(..item, checked: None)
            // Checked today or in the future — keep
            _ -> item
          }
      }
    })
  Checklist(..checklist, items:)
}

fn refresh_on_completion(checklist: Checklist) -> Checklist {
  let all_checked =
    checklist.items != []
    && list.all(checklist.items, fn(item) { option.is_some(item.checked) })
  case all_checked {
    True ->
      Checklist(
        ..checklist,
        items: list.map(checklist.items, fn(item) {
          Item(..item, checked: None)
        }),
      )
    False -> checklist
  }
}

pub fn url(id: Int) -> String {
  "/checklists/" <> int.to_string(id)
}

// --- JSON encoding ---

pub fn encode(checklist: Checklist) -> Json {
  json.object([
    #("id", json.int(checklist.id)),
    #("name", json.string(checklist.name)),
    #("refresh", encode_refresh_mode(checklist.refresh_mode)),
    #("items", json.array(checklist.items, encode_item)),
  ])
}

fn encode_refresh_mode(mode: RefreshMode) -> Json {
  case mode {
    Daily -> json.string("daily")
    OnCompletion -> json.string("on-completion")
  }
}

fn encode_item(item: Item) -> Json {
  json.object([
    #("name", json.string(item.name)),
    #("checked", json.nullable(item.checked, fn(d) {
      json.string(date.to_iso_string(d))
    })),
    #("links", json.array(item.links, encode_link)),
  ])
}

fn encode_link(link: Link) -> Json {
  json.object([
    #("name", json.string(link.name)),
    #("url", json.string(link.url)),
  ])
}

pub fn encode_data(checklists: List(Checklist)) -> String {
  json.object([
    #("version", json.int(1)),
    #("checklists", json.array(checklists, encode)),
  ])
  |> json.to_string
}

// --- JSON decoding ---

pub fn decoder() -> Decoder(Checklist) {
  use id <- decode.field("id", decode.int)
  use name <- decode.field("name", decode.string)
  use refresh_mode <- decode.optional_field(
    "refresh",
    Daily,
    refresh_mode_decoder(),
  )
  use items <- decode.field("items", decode.list(item_decoder()))
  decode.success(Checklist(id:, name:, refresh_mode:, items:))
}

fn refresh_mode_decoder() -> Decoder(RefreshMode) {
  use value <- decode.then(decode.string)
  case value {
    "daily" -> decode.success(Daily)
    "on-completion" -> decode.success(OnCompletion)
    _ -> decode.failure(Daily, "RefreshMode")
  }
}

fn item_decoder() -> Decoder(Item) {
  use name <- decode.field("name", decode.string)
  use checked <- decode.field("checked", checked_decoder())
  use links <- decode.optional_field("links", [], decode.list(link_decoder()))
  decode.success(Item(name:, checked:, links:))
}

fn checked_decoder() -> Decoder(Option(Date)) {
  decode.one_of(
    // Primary: null or date/datetime string
    decode.optional(date_decoder()),
    // Fallback: legacy bool format (false -> None)
    [decode.map(decode.bool, fn(_) { None })],
  )
}

fn date_decoder() -> Decoder(Date) {
  use value <- decode.then(decode.string)
  // Handle both "2019-03-30" and "2019-03-30T18:30:00.000Z" formats
  // by taking only the date portion (first 10 chars) before parsing
  let date_str = case string.split(value, "T") {
    [date_part, ..] -> date_part
    _ -> value
  }
  case date.from_iso_string(date_str) {
    Ok(d) -> decode.success(d)
    Error(_) -> decode.failure(date.from_calendar_date(2000, date.Jan, 1), "ISO date")
  }
}

fn link_decoder() -> Decoder(Link) {
  use name <- decode.field("name", decode.string)
  use url <- decode.field("url", decode.string)
  decode.success(Link(name:, url:))
}

pub fn decode_data(json_string: String) -> Result(List(Checklist), String) {
  let data_decoder = {
    use checklists <- decode.field("checklists", decode.list(decoder()))
    decode.success(checklists)
  }
  json.parse(json_string, data_decoder)
  |> result.map_error(fn(err) { string.inspect(err) })
}
