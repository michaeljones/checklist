# Recurring

A single-page app for managing recurring checklists that auto-reset on a schedule. Built with [Gleam](https://gleam.run) and [Lustre](https://hexdocs.pm/lustre/), targeting JavaScript.

Deployed at https://michaeljones.github.io/checklist

## Features

- Create named checklists with items
- Two refresh modes:
  - **Daily** — items checked before today are automatically unchecked
  - **On Completion** — all items reset when every item has been checked
- Data persisted to localStorage
- JSON backup download and restore

## Development

Requires [Gleam](https://gleam.run) and [Node.js](https://nodejs.org).

```sh
gleam build              # Compile
gleam test               # Run tests
gleam run -m lustre/dev start  # Dev server
```

## Deployment

Deployed to GitHub Pages with a `404.html` redirect for SPA path-based routing.
