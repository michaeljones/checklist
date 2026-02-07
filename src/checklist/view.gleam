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
  html.div(
    [attribute.class("flex w-full justify-center items-center min-h-screen")],
    [
      html.div([attribute.class("bg-red/20 p-5 rounded-lg text-maroon")], [
        html.text(err),
      ]),
    ],
  )
}

fn route_view(model: Model) -> Element(Msg) {
  case model.route {
    Home -> home_view(model)
    ChecklistPage(id) -> checklist_view(model, id)
    NotFound -> not_found_view()
  }
}

fn header_el() -> Element(Msg) {
  html.header([attribute.class("p-5 border-b border-surface0 bg-mantle")], [
    html.a([attribute.href("/"), attribute.class("no-underline text-text")], [
      html.h1([attribute.class("m-0 text-3xl")], [html.text("Recurring")]),
    ]),
  ])
}

fn home_view(model: Model) -> Element(Msg) {
  let checklist_items =
    dict.values(model.checklists)
    |> list.map(fn(checklist) {
      html.li([attribute.class("py-1")], [
        html.a(
          [
            attribute.href(data.url(checklist.id)),
            attribute.class("text-blue hover:text-sapphire"),
          ],
          [html.text(checklist.name)],
        ),
      ])
    })

  html.div([], [
    header_el(),
    html.main([attribute.class("flex flex-col p-5 gap-3")], [
      html.ul([attribute.class("list-none p-0 m-0")], checklist_items),
      html.input([
        attribute.type_("text"),
        attribute.value(model.name),
        event.on_input(SetName),
        attribute.class(
          "bg-surface0 text-text border border-surface1 rounded px-3 py-2 outline-none focus:border-mauve",
        ),
      ]),
      html.button(
        [
          event.on_click(AddChecklist),
          attribute.class(
            "bg-surface0 text-text hover:bg-surface1 rounded px-3 py-2 border border-surface1 cursor-pointer",
          ),
        ],
        [html.text("Add Checklist")],
      ),
      html.button(
        [
          event.on_click(Download),
          attribute.class(
            "bg-surface0 text-text hover:bg-surface1 rounded px-3 py-2 border border-surface1 cursor-pointer",
          ),
        ],
        [html.text("Download")],
      ),
      html.button(
        [
          event.on_click(Load),
          attribute.class(
            "bg-surface0 text-text hover:bg-surface1 rounded px-3 py-2 border border-surface1 cursor-pointer",
          ),
        ],
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
                html.a(
                  [
                    attribute.href(link.url),
                    attribute.class("text-blue hover:text-sapphire"),
                  ],
                  [html.text(link.name)],
                ),
              ])
            })
          html.li([attribute.class("py-1")], [
            html.label([attribute.class("flex items-center gap-2")], [
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
              _ -> html.ul([attribute.class("ml-6 mt-1")], links)
            },
          ])
        })

      html.div([], [
        header_el(),
        html.main([attribute.class("flex flex-col p-5 gap-3")], [
          html.h2([attribute.class("m-0 text-subtext1")], [
            html.text(checklist.name),
          ]),
          html.ul([attribute.class("list-none p-0 m-0")], items),
          html.input([
            attribute.type_("text"),
            attribute.value(model.name),
            event.on_input(SetName),
            attribute.class(
              "bg-surface0 text-text border border-surface1 rounded px-3 py-2 outline-none focus:border-mauve",
            ),
          ]),
          html.button(
            [
              event.on_click(AddItem(checklist.id)),
              attribute.class(
                "bg-surface0 text-text hover:bg-surface1 rounded px-3 py-2 border border-surface1 cursor-pointer",
              ),
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
  html.div([], [
    header_el(),
    html.main([attribute.class("flex flex-col p-5 text-subtext0")], [
      html.text("404 - Page Not Found"),
    ]),
  ])
}
