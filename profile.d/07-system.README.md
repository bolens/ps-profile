profile.d/07-system.ps1
=======================

Purpose
-------

System utilities (shell-like helpers adapted for PowerShell)

Usage
-----

See the fragment source: `07-system.ps1` for examples and usage notes.

Functions
---------

- `Get-CommandInfo` — Shows information about commands.
- `Find-String` — Searches for patterns in files.
- `New-EmptyFile` — Creates empty files.
- `New-Directory` — Creates directories.
- `Remove-ItemCustom` — Removes files and directories.
- `Copy-ItemCustom` — Copies files and directories.
- `Move-ItemCustom` — Moves files and directories.
- `Find-File` — Searches for files recursively.
- `Get-DiskUsage` — Shows disk usage information.
- `Get-TopProcesses` — Shows top CPU-consuming processes.
- `Get-NetworkPorts` — Shows network port information.
- `Test-NetworkConnection` — Tests network connectivity.
- `Resolve-DnsNameCustom` — Resolves DNS names.
- `Invoke-RestApi` — Makes REST API calls.
- `Invoke-WebRequestCustom` — Makes HTTP web requests.
- `Expand-ArchiveCustom` — Extracts ZIP archives.
- `Compress-ArchiveCustom` — Creates ZIP archives.
- `Open-VSCode` — Opens files in Visual Studio Code.
- `Open-Neovim` — Opens files in Neovim.
- `Open-NeovimVi` — Opens files in Neovim (vi mode).

Aliases
-------

- `which` — Shows information about commands. (alias for `Get-CommandInfo`)
- `pgrep` — Searches for patterns in files. (alias for `Find-String`)
- `touch` — Creates empty files. (alias for `New-EmptyFile`)
- `search` — Searches for files recursively. (alias for `Find-File`)
- `df` — Shows disk usage information. (alias for `Get-DiskUsage`)
- `htop` — Shows top CPU-consuming processes. (alias for `Get-TopProcesses`)
- `ports` — Shows network port information. (alias for `Get-NetworkPorts`)
- `ptest` — Tests network connectivity. (alias for `Test-NetworkConnection`)
- `dns` — Resolves DNS names. (alias for `Resolve-DnsNameCustom`)
- `rest` — Makes REST API calls. (alias for `Invoke-RestApi`)
- `web` — Makes HTTP web requests. (alias for `Invoke-WebRequestCustom`)
- `unzip` — Extracts ZIP archives. (alias for `Expand-ArchiveCustom`)
- `zip` — Creates ZIP archives. (alias for `Compress-ArchiveCustom`)
- `code` — Opens files in Visual Studio Code. (alias for `Open-VSCode`)
- `vim` — Opens files in Neovim. (alias for `Open-Neovim`)
- `vi` — Opens files in Neovim (vi mode). (alias for `Open-NeovimVi`)

Dependencies
------------

None explicit; see the fragment for runtime checks and optional tooling dependencies.

Notes
-----

Keep this fragment idempotent and avoid heavy probes at dot-source. Prefer provider-first checks and lazy enablers like Enable-* helpers.
