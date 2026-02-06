@external(javascript, "./checklist_ffi.mjs", "readLocalstorage")
pub fn read_localstorage(key: String) -> Result(String, Nil)

@external(javascript, "./checklist_ffi.mjs", "writeLocalstorage")
pub fn write_localstorage(key: String, value: String) -> Nil

@external(javascript, "./checklist_ffi.mjs", "downloadText")
pub fn download_text(
  filename: String,
  content: String,
  mime: String,
) -> Nil

@external(javascript, "./checklist_ffi.mjs", "selectFile")
pub fn select_file(callback: fn(String) -> Nil) -> Nil

@external(javascript, "./checklist_ffi.mjs", "startInterval")
pub fn start_interval(interval_ms: Int, callback: fn() -> Nil) -> Nil
