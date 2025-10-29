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
- `confirm` — gum confirm (yes/no prompt)
- `choose` — gum choose (select from list)
- `input` — gum input (text input)
- `spin` — gum spin (spinner for long operations)
- `style` — gum style (style text output)
- `Invoke-GumConfirm` — Confirm with gum
- `Invoke-GumChoose` — Choose from list with gum
- `Invoke-GumInput` — Input with gum
- `Invoke-GumSpin` — Spin with gum
- `Invoke-GumStyle` — Style text with gum

Dependencies
------------
- gum (install with: scoop install gum)

Notes
-----
Gum provides beautiful terminal UI components. Use these functions in scripts for better user interaction.
