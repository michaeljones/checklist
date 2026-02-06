import { Ok, Error } from "../../prelude.mjs";

export function readLocalstorage(key) {
  const value = globalThis.localStorage.getItem(key);
  if (value === null) {
    return new Error(undefined);
  }
  return new Ok(value);
}

export function writeLocalstorage(key, value) {
  globalThis.localStorage.setItem(key, value);
}

export function downloadText(filename, content, mime) {
  const blob = new Blob([content], { type: mime });
  const url = URL.createObjectURL(blob);
  const a = document.createElement("a");
  a.href = url;
  a.download = filename;
  document.body.appendChild(a);
  a.click();
  document.body.removeChild(a);
  URL.revokeObjectURL(url);
}

export function selectFile(callback) {
  const input = document.createElement("input");
  input.type = "file";
  input.accept = "application/json";
  input.onchange = (event) => {
    const file = event.target.files[0];
    if (!file) return;
    const reader = new FileReader();
    reader.onload = (e) => {
      callback(e.target.result);
    };
    reader.readAsText(file);
  };
  input.click();
}

export function startInterval(intervalMs, callback) {
  setInterval(callback, intervalMs);
}
