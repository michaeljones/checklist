import checklist/data
import checklist/model.{
  type Model, type Msg, AddChecklist, AddItem, CheckItem, ChecklistPage,
  Download, Home, Load, NotFound, SetName,
}
import gleam/dict
import gleam/list
import gleam/option
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html
import lustre/event

pub fn view(model: Model) -> Element(Msg) {
  case model.error {
    option.Some(err) -> error_view(err)
    option.None -> route_view(model)
  }
}

fn error_view(err: String) -> Element(Msg) {
  html.div([attribute.class("error-container")], [
    html.div([attribute.class("error-box")], [html.text(err)]),
  ])
}

fn route_view(model: Model) -> Element(Msg) {
  case model.route {
    Home -> home_view(model)
    ChecklistPage(id) -> checklist_view(model, id)
    NotFound -> not_found_view()
  }
}

fn header_el() -> Element(Msg) {
  html.header([attribute.class("header")], [
    html.a([attribute.href("/"), attribute.class("header-link")], [
      html.h1([attribute.class("header-title")], [html.text("Recurring")]),
    ]),
  ])
}

fn home_view(model: Model) -> Element(Msg) {
  let checklist_items =
    dict.values(model.checklists)
    |> list.map(fn(checklist) {
      html.li([], [
        html.a([attribute.href(data.url(checklist.id))], [
          html.text(checklist.name),
        ]),
      ])
    })

  html.div([], [
    header_el(),
    html.main([attribute.class("main-content")], [
      html.ul([], checklist_items),
      html.input([
        attribute.type_("text"),
        attribute.value(model.name),
        event.on_input(SetName),
      ]),
      html.button(
        [event.on_click(AddChecklist), attribute.class("action-button")],
        [html.text("Add Checklist")],
      ),
      html.button(
        [event.on_click(Download), attribute.class("action-button")],
        [html.text("Download")],
      ),
      html.button(
        [event.on_click(Load), attribute.class("action-button")],
        [html.text("Load/Restore")],
      ),
    ]),
  ])
}

fn checklist_view(model: Model, id: Int) -> Element(Msg) {
  case dict.get(model.checklists, id) {
    Ok(checklist) -> {
      let items =
        list.index_map(checklist.items, fn(item, index) {
          let is_checked = option.is_some(item.checked)
          let links =
            list.map(item.links, fn(link) {
              html.li([], [
                html.a([attribute.href(link.url)], [html.text(link.name)]),
              ])
            })
          html.li([], [
            html.label([], [
              html.input([
                attribute.type_("checkbox"),
                attribute.checked(is_checked),
                event.on_check(fn(checked) {
                  CheckItem(checklist_id: id, item_index: index, checked:)
                }),
              ]),
              html.text(item.name),
            ]),
            case links {
              [] -> html.text("")
              _ -> html.ul([], links)
            },
          ])
        })

      html.div([], [
        header_el(),
        html.main([attribute.class("main-content")], [
          html.h2([attribute.class("checklist-title")], [
            html.text(checklist.name),
          ]),
          html.ul([], items),
          html.input([
            attribute.type_("text"),
            attribute.value(model.name),
            event.on_input(SetName),
          ]),
          html.button(
            [
              event.on_click(AddItem(checklist.id)),
              attribute.class("action-button"),
            ],
            [html.text("Add Item")],
          ),
        ]),
      ])
    }
    Error(_) -> not_found_view()
  }
}

fn not_found_view() -> Element(Msg) {
  html.div([], [header_el(), html.main([], [html.text("404 - Page Not Found")])])
}
