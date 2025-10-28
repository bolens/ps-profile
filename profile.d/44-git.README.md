profile.d/44-git.ps1
====================

Purpose
-------
Contains Git helper functions and (optionally) completion registration.

Usage
-----
See the fragment source: `44-git.ps1` for examples and usage notes.

Functions
---------
- `Git-CurrentBranch` — Git current branch - get current branch name
- `Git-StatusShort` — Git status short - show concise status
- `Prompt-GitSegment` — Git prompt segment - show current branch in prompt

Dependencies
------------
None explicit; see the fragment for runtime checks and optional tooling dependencies.

Notes
-----
Keep this fragment idempotent and avoid heavy probes at dot-source. Prefer provider-first checks and lazy enablers like Enable-* helpers.

