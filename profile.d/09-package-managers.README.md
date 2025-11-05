profile.d/09-package-managers.ps1
=================================

Purpose
-------
Package manager helper shorthands (Scoop, uv, pnpm, etc.)

Usage
-----
See the fragment source: `09-package-managers.ps1` for examples and usage notes.

Functions
---------
- `Install-ScoopPackage` — Installs packages using Scoop.
- `Find-ScoopPackage` — Searches for packages in Scoop.
- `Update-ScoopPackage` — Updates packages using Scoop.
- `Update-ScoopAll` — Updates all installed Scoop packages.
- `Uninstall-ScoopPackage` — Uninstalls packages using Scoop.
- `Get-ScoopPackage` — Lists installed Scoop packages.
- `Get-ScoopPackageInfo` — Shows information about Scoop packages.
- `Clear-ScoopCache` — Cleans up Scoop cache and old versions.
- `Install-UVTool` — Installs Python tools using UV.
- `Invoke-UVRun` — Runs Python commands with UV.
- `Invoke-UVTool` — Runs tools installed with UV.
- `Add-UVDependency` — Adds dependencies to UV project.
- `Sync-UVDependencies` — Syncs UV project dependencies.
- `Install-PnpmPackage` — Installs dependencies using PNPM.
- `Add-PnpmPackage` — Adds packages using PNPM.
- `Add-PnpmDevPackage` — Adds dev dependencies using PNPM.
- `Invoke-PnpmScript` — Runs scripts using PNPM.
- `Start-PnpmProject` — Starts the project using PNPM.
- `Build-PnpmProject` — Builds the project using PNPM.
- `Test-PnpmProject` — Runs tests using PNPM.
- `Start-PnpmDev` — Runs development server using PNPM.

Aliases
-------
- `sinstall` — Installs packages using Scoop. (alias for `Install-ScoopPackage`)
- `ss` — Searches for packages in Scoop. (alias for `Find-ScoopPackage`)
- `su` — Updates packages using Scoop. (alias for `Update-ScoopPackage`)
- `suu` — Updates all installed Scoop packages. (alias for `Update-ScoopAll`)
- `sr` — Uninstalls packages using Scoop. (alias for `Uninstall-ScoopPackage`)
- `slist` — Lists installed Scoop packages. (alias for `Get-ScoopPackage`)
- `sh` — Shows information about Scoop packages. (alias for `Get-ScoopPackageInfo`)
- `scleanup` — Cleans up Scoop cache and old versions. (alias for `Clear-ScoopCache`)
- `uvi` — Installs Python tools using UV. (alias for `Install-UVTool`)
- `uvr` — Runs Python commands with UV. (alias for `Invoke-UVRun`)
- `uvx` — Runs tools installed with UV. (alias for `Invoke-UVTool`)
- `uva` — Adds dependencies to UV project. (alias for `Add-UVDependency`)
- `uvs` — Syncs UV project dependencies. (alias for `Sync-UVDependencies`)
- `pni` — Installs dependencies using PNPM. (alias for `Install-PnpmPackage`)
- `pna` — Adds packages using PNPM. (alias for `Add-PnpmPackage`)
- `pnd` — Adds dev dependencies using PNPM. (alias for `Add-PnpmDevPackage`)
- `pnr` — Runs scripts using PNPM. (alias for `Invoke-PnpmScript`)
- `pns` — Starts the project using PNPM. (alias for `Start-PnpmProject`)
- `pnb` — Builds the project using PNPM. (alias for `Build-PnpmProject`)
- `pnt` — Runs tests using PNPM. (alias for `Test-PnpmProject`)
- `pndev` — Runs development server using PNPM. (alias for `Start-PnpmDev`)

Dependencies
------------
None explicit; see the fragment for runtime checks and optional tooling dependencies.

Notes
-----
Keep this fragment idempotent and avoid heavy probes at dot-source. Prefer provider-first checks and lazy enablers like Enable-* helpers.
