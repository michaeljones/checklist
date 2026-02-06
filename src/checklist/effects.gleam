import checklist/data.{type Checklist}
import checklist/ffi
import gleam/dict.{type Dict}
import lustre/effect.{type Effect}

pub fn save(checklists: Dict(Int, Checklist)) -> Effect(msg) {
  effect.from(fn(_dispatch) {
    let checklist_list = dict.values(checklists)
    let json_string = data.encode_data(checklist_list)
    ffi.write_localstorage("data", json_string)
  })
}

pub fn download(checklists: Dict(Int, Checklist), date_part: String) -> Effect(msg) {
  effect.from(fn(_dispatch) {
    let checklist_list = dict.values(checklists)
    let json_string = data.encode_data(checklist_list)
    let filename = "recurring-" <> date_part <> ".json"
    ffi.download_text(filename, json_string, "application/json")
  })
}

pub fn select_file(to_msg: fn(String) -> msg) -> Effect(msg) {
  effect.from(fn(dispatch) {
    ffi.select_file(fn(content) { dispatch(to_msg(content)) })
  })
}

pub fn setup_timer(msg: msg) -> Effect(msg) {
  effect.from(fn(dispatch) {
    ffi.start_interval(60_000, fn() { dispatch(msg) })
  })
}
