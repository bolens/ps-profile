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

- `Get-GitCurrentBranch` — Register Git helpers as lightweight stubs. They will call `git` at runtime
- `Get-GitStatusShort` — Git status short - show concise status
- `Format-PromptGitSegment` — Git prompt segment - show current branch in prompt

Aliases
-------

- `Git-CurrentBranch` — Register Git helpers as lightweight stubs. They will call `git` at runtime (alias for `Get-GitCurrentBranch`)
- `Git-StatusShort` — Git status short - show concise status (alias for `Get-GitStatusShort`)
- `Prompt-GitSegment` — Git prompt segment - show current branch in prompt (alias for `Format-PromptGitSegment`)

Dependencies
------------

None explicit; see the fragment for runtime checks and optional tooling dependencies.

Notes
-----

Keep this fragment idempotent and avoid heavy probes at dot-source. Prefer provider-first checks and lazy enablers like Enable-* helpers.
