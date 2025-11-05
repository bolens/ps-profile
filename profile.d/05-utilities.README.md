profile.d/05-utilities.ps1
==========================

Purpose
-------

Utility functions migrated from utilities.ps1

Usage
-----

See the fragment source: `05-utilities.ps1` for examples and usage notes.

Functions
---------

- `Reload-Profile` — Reloads the PowerShell profile.
- `Edit-Profile` — Opens the profile in VS Code.
- `Get-Weather` — Shows weather information.
- `Get-MyIP` — Shows public IP address.
- `Start-SpeedTest` — Runs internet speed test.
- `Get-History` — Shows recent command history.
- `Find-History` — Searches command history.
- `New-RandomPassword` — Generates a random password.
- `ConvertTo-UrlEncoded` — URL-encodes a string.
- `ConvertFrom-UrlEncoded` — URL-decodes a string.
- `ConvertFrom-Epoch` — Converts Unix timestamp to DateTime.
- `ConvertTo-Epoch` — Converts DateTime to Unix timestamp.
- `Get-Epoch` — Gets current Unix timestamp.
- `Get-DateTime` — Shows current date and time.
- `Open-Explorer` — Opens current directory in File Explorer.
- `Get-Functions` — Lists user-defined functions.
- `Backup-Profile` — Creates a backup of the profile.
- `Get-EnvVar` — Gets an environment variable value from the registry.
- `Set-EnvVar` — Sets an environment variable value in the registry.
- `Publish-EnvVar` — Broadcasts environment variable changes to all windows.
- `Remove-Path` — Removes a directory from the PATH environment variable.
- `Add-Path` — Adds a directory to the PATH environment variable.

Aliases
-------

- `reload` — Reloads the PowerShell profile. (alias for `Reload-Profile`)
- `edit-profile` — Opens the profile in VS Code. (alias for `Edit-Profile`)
- `weather` — Shows weather information. (alias for `Get-Weather`)
- `myip` — Shows public IP address. (alias for `Get-MyIP`)
- `speedtest` — Runs internet speed test. (alias for `Start-SpeedTest`)
- `hg` — Searches command history. (alias for `Find-History`)
- `pwgen` — Generates a random password. (alias for `New-RandomPassword`)
- `url-encode` — URL-encodes a string. (alias for `ConvertTo-UrlEncoded`)
- `url-decode` — URL-decodes a string. (alias for `ConvertFrom-UrlEncoded`)
- `from-epoch` — Converts Unix timestamp to DateTime. (alias for `ConvertFrom-Epoch`)
- `to-epoch` — Converts DateTime to Unix timestamp. (alias for `ConvertTo-Epoch`)
- `epoch` — Gets current Unix timestamp. (alias for `Get-Epoch`)
- `now` — Shows current date and time. (alias for `Get-DateTime`)
- `open-explorer` — Opens current directory in File Explorer. (alias for `Open-Explorer`)
- `list-functions` — Lists user-defined functions. (alias for `Get-Functions`)
- `backup-profile` — Creates a backup of the profile. (alias for `Backup-Profile`)

Dependencies
------------

None explicit; see the fragment for runtime checks and optional tooling dependencies.

Notes
-----

Keep this fragment idempotent and avoid heavy probes at dot-source. Prefer provider-first checks and lazy enablers like Enable-* helpers.
