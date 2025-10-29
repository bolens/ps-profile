# profile.d/63-gum.ps1
====================

Purpose
-------
Provides terminal UI helpers using gum for interactive prompts and styling.

Usage
-----
See the fragment source: `63-gum.ps1` for examples and usage notes.

Functions
---------
- `Invoke-GumConfirm` — Shows confirmation prompt using gum
- `Invoke-GumChoose` — Shows interactive selection menu using gum
- `Invoke-GumInput` — Shows input prompt using gum
- `Invoke-GumSpin` — Shows spinner while executing script block
- `Invoke-GumStyle` — Styles text output using gum

Aliases
-------
- `confirm` — Invoke-GumConfirm
- `choose` — Invoke-GumChoose
- `input` — Invoke-GumInput
- `spin` — Invoke-GumSpin
- `style` — Invoke-GumStyle

Dependencies
------------
- gum (install with: scoop install gum)

Notes
-----
Gum provides beautiful terminal UI components. Use these functions in scripts for better user interaction.
