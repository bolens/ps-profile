profile.d/63-gum.ps1
====================

Purpose
-------
Terminal UI helpers with gum

Usage
-----
See the fragment source: `63-gum.ps1` for examples and usage notes.

Functions
---------
- `Invoke-GumConfirm` — Shows a confirmation prompt using gum.
- `Invoke-GumChoose` — Shows an interactive selection menu using gum.
- `Invoke-GumInput` — Shows an input prompt using gum.
- `Invoke-GumSpin` — Shows a spinner while executing a script block using gum.
- `Invoke-GumStyle` — Styles text output using gum.

Aliases
-------
- `confirm` — Shows a confirmation prompt using gum. (alias for `Invoke-GumConfirm`)
- `choose` — Shows an interactive selection menu using gum. (alias for `Invoke-GumChoose`)
- `input` — Shows an input prompt using gum. (alias for `Invoke-GumInput`)
- `spin` — Shows a spinner while executing a script block using gum. (alias for `Invoke-GumSpin`)
- `style` — Styles text output using gum. (alias for `Invoke-GumStyle`)

Dependencies
------------
None explicit; see the fragment for runtime checks and optional tooling dependencies.

Notes
-----
Keep this fragment idempotent and avoid heavy probes at dot-source. Prefer provider-first checks and lazy enablers like Enable-* helpers.
