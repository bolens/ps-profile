profile.d/16-clipboard.ps1
==========================

Purpose
-------

Clipboard helpers (cross-platform via pwsh)

Usage
-----

See the fragment source: `16-clipboard.ps1` for examples and usage notes.

Functions
---------

- `Copy-ToClipboard` — Copies input to the clipboard.
- `Get-FromClipboard` — Pastes content from the clipboard.

Aliases
-------

- `cb` — Copies input to the clipboard. (alias for `Copy-ToClipboard`)
- `pb` — Pastes content from the clipboard. (alias for `Get-FromClipboard`)

Dependencies
------------

None explicit; see the fragment for runtime checks and optional tooling dependencies.

Notes
-----

Keep this fragment idempotent and avoid heavy probes at dot-source. Prefer provider-first checks and lazy enablers like Enable-* helpers.
