profile.d/54-modern-cli.ps1
===========================

Purpose
-------
Modern CLI tools helpers (guarded)

Usage
-----
See the fragment source: `54-modern-cli.ps1` for examples and usage notes.

Functions
---------
- `bat` — bat - cat clone with syntax highlighting and Git integration
- `fd` — fd - find files and directories
- `http` — http - command-line HTTP client
- `zoxide` — zoxide - smarter cd command
- `delta` — delta - syntax-highlighting pager for git
- `tldr` — tldr - simplified man pages
- `procs` — procs - modern replacement for ps
- `dust` — dust - more intuitive du command

Dependencies
------------
None explicit; see the fragment for runtime checks and optional tooling dependencies.

Notes
-----
Keep this fragment idempotent and avoid heavy probes at dot-source. Prefer provider-first checks and lazy enablers like Enable-* helpers.

