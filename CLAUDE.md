# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Development Commands

- `gleam build` — Compile the project
- `gleam test` — Run tests
- `gleam run -m lustre/dev start` — Dev server (via lustre_dev_tools)
- `gleam deps download` — Download dependencies
- `gleam format src/ test/` — Format Gleam source files

## Architecture

This is a single-page Gleam application targeting JavaScript with the Lustre framework, for managing recurring checklists that auto-reset on a schedule. Deployed to GitHub Pages at `https://michaeljones.github.io/checklist`.

Uses path-based routing via modem (`/` for home, `/checklists/<id>` for detail). Date handling uses the `rada` library (dates only, no times/timezones).

### Key Modules

**`src/checklist.gleam`** — Entry point. Creates a `lustre.application` and starts it on `#app`.

**`src/checklist/data.gleam`** — Domain model. A `Checklist` has a `RefreshMode`:
- **Daily** — Items checked before today are reset to unchecked
- **OnCompletion** — All items reset when every item has been checked

Contains types (`Checklist`, `Item`, `Link`, `RefreshMode`), refresh logic, and full JSON encode/decode for persistence. Backward compatible with the old Elm app's ISO 8601 datetime format (extracts date portion from timestamps).

**`src/checklist/model.gleam`** — Model, Msg, Route types plus `init` and `update` functions. Reads localStorage on startup (with fallback from legacy "checklists" key). A 60-second interval timer triggers refresh via `Tick`.

**`src/checklist/view.gleam`** — View function rendering based on current route. Home page shows checklist links and add/download/load controls. Checklist page shows items with checkboxes.

**`src/checklist/effects.gleam`** — Lustre Effect wrappers for save, download, file select, and timer.

**`src/checklist/ffi.gleam`** + **`src/checklist/checklist_ffi.mjs`** — Browser FFI for localStorage, file download/upload, and setInterval.

### Data Flow

Model updates → `effects.save` → FFI writes to localStorage as `{version: 1, checklists: [...]}`. On startup, `init` reads localStorage via FFI and parses JSON. File download/upload provides JSON backup/restore.

### Tests

`test/checklist/data_test.gleam` — Tests for `data.refresh` covering both refresh modes with various date scenarios. Run with `gleam test`.
