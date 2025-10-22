# ===============================================
# 01-paths.ps1
# Normalize PATH and add common developer tool directories safely and idempotently.
# Loaded early to ensure other fragments see updated PATH.
# ===============================================

# Only run on Windows (this workspace is Windows-focused); keep safe guards for cross-platform
if ($IsWindows) {
  # Scoop installs under %USERPROFILE%\scoop by default (or %SCOOP%)
  if ($env:SCOOP) {
    $scoopRoot = $env:SCOOP
    if ($scoopRoot) {
      $scoopBin = Join-Path $scoopRoot 'shims'
      if ($scoopBin -and (Test-Path $scoopBin) -and $env:Path -and -not ($env:Path -split ';' | Where-Object { $_ -ieq $scoopBin })) {
        $env:Path = "$scoopBin;$env:Path"
      }
    }
  } else {
    # Common fallback locations (only build them if USERPROFILE exists)
    $possible = @()
    if ($env:USERPROFILE) {
      $possible = @(
        "$env:USERPROFILE\scoop\shims",
        "$env:USERPROFILE\scoop\apps\scoop\current\shims"
      )
    }
    foreach ($p in $possible) {
      if (Test-Path $p -PathType Container -ErrorAction SilentlyContinue) {
        if ($env:Path -and -not ($env:Path -split ';' | Where-Object { $_ -ieq $p })) { $env:Path = "$p;$env:Path" }
      }
    }
  }

  # Add VS Code user bin (if installed via system installer)
  if ($env:LOCALAPPDATA) {
    $vscodePath = Join-Path $env:LOCALAPPDATA 'Programs\Microsoft VS Code\bin'
    if (Test-Path $vscodePath -PathType Container -ErrorAction SilentlyContinue) {
      if ($env:Path -and -not ($env:Path -split ';' | Where-Object { $_ -ieq $vscodePath })) { $env:Path = "$vscodePath;$env:Path" }
    }
  }

  # Add user-local bin (common for tools like pipx, cargo's bin, etc.)
  if ($env:USERPROFILE) {
    $userLocal = Join-Path $env:USERPROFILE '.local\bin'
    if (Test-Path $userLocal -PathType Container -ErrorAction SilentlyContinue) {
      if ($env:Path -and -not ($env:Path -split ';' | Where-Object { $_ -ieq $userLocal })) { $env:Path = "$userLocal;$env:Path" }
    }
  }

  # Add user's npm global bin (if npm is installed and location exists)
  try {
    # Keep PATH modifications minimal and cheap at dot-source. Add the
    # most common user-local bins (scoop shims, user-local .local\bin)
    # and VS Code's bin if present. Defer npm prefix discovery to
    # `Enable-NpmPaths` which runs only when explicitly requested.

    if ($env:USERPROFILE) {
      $userLocal = Join-Path $env:USERPROFILE '.local\bin'
      if (Test-Path $userLocal -PathType Container -ErrorAction SilentlyContinue) {
        if ($env:Path -and -not ($env:Path -split ';' | Where-Object { $_ -ieq $userLocal })) {
          $env:Path = "$userLocal;$env:Path"
        }
      }
    }

    # VS Code system installer bin
    if ($env:LOCALAPPDATA) {
      $vscodePath = Join-Path $env:LOCALAPPDATA 'Programs\Microsoft VS Code\bin'
      if (Test-Path $vscodePath -PathType Container -ErrorAction SilentlyContinue) {
        if ($env:Path -and -not ($env:Path -split ';' | Where-Object { $_ -ieq $vscodePath })) {
          $env:Path = "$vscodePath;$env:Path"
        }
      }
    }

    # Provide an on-demand helper for npm prefix discovery to keep
    # dot-source cheap. Users can call Enable-NpmPaths if they want
    # npm's global bin discovered into PATH.
    # Temporarily disabled due to npm config issues
    # if (-not (Test-Path 'Function:Enable-NpmPaths')) {
    #   New-Item -Path 'Function:Enable-NpmPaths' -Value {
    #     param()
    #     try {
    #       if (Test-HasCommand -Name 'npm') {
    #         $npmPrefix = (& npm config get prefix 2>$null) -as [string]
    #         if ($npmPrefix) {
    #           $npmBin = Join-Path $npmPrefix 'bin'
    #           if ($npmBin -and (Test-Path $npmBin -PathType Container -ErrorAction SilentlyContinue)) {
    #             if ($env:Path -and -not ($env:Path -split ';' | Where-Object { $_ -ieq $npmBin })) {
    #               $env:Path = "$npmBin;$env:Path"
    #               return $true
    #             }
    #           }
    #         }
    #       }
    #     } catch { Write-Verbose "Failed to add Windows PATH entry: $($_.Exception.Message)" }
    #     return $false
    #   } -Force | Out-Null
    # }
  } catch { Write-Verbose "Failed to set up Windows PATH: $($_.Exception.Message)" }
} else {
  # Cross-platform fallback for non-Windows shells (minimal): ensure ~/.local/bin is on PATH
  # Only proceed if HOME and PATH are present in the environment to avoid null argument errors
  if ($env:HOME -and $env:PATH) {
    $localBin = Join-Path $env:HOME '.local/bin'
    if (Test-Path $localBin -PathType Container -ErrorAction SilentlyContinue) {
      if (-not ($env:PATH -split ':' | Where-Object { $_ -eq $localBin })) {
        # Use explicit concatenation to avoid ambiguous parsing of environment variables
        $env:PATH = $localBin + ':' + $env:PATH
      }
    }
  }
}


