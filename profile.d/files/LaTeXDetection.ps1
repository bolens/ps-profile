# ===============================================
# LaTeXDetection.ps1
# LaTeX engine detection utilities
# ===============================================

<#
.SYNOPSIS
    Tests whether a supported LaTeX engine is available.
.DESCRIPTION
    Checks for pdflatex, xelatex, or luatex in the current environment and returns
    the first engine found so callers can select an appropriate --pdf-engine.
.OUTPUTS
    [string] - The name of the LaTeX engine if found; otherwise $null.
#>
function Test-DocumentLatexEngineAvailable {
    # Check PATH first
    if (Get-Command pdflatex -ErrorAction SilentlyContinue) { return 'pdflatex' }
    if (Get-Command xelatex -ErrorAction SilentlyContinue) { return 'xelatex' }
    if (Get-Command luatex -ErrorAction SilentlyContinue) { return 'luatex' }
    
    # Check Scoop MiKTeX installation if not in PATH
    # Check both global ($env:SCOOP_GLOBAL) and local ($env:SCOOP) Scoop installations
    if ($env:SCOOP_GLOBAL -or $env:SCOOP) {
        $scoopMiktexBinPaths = @()
        
        # If MiKTeX is installed in the global scoop directory
        if ($env:SCOOP_GLOBAL -and (Test-Path "$env:SCOOP_GLOBAL\apps\miktex\current")) {
            $scoopMiktexBinPaths += @(
                "$env:SCOOP_GLOBAL\apps\miktex\current\texmfs\install\miktex\bin\x64",
                "$env:SCOOP_GLOBAL\apps\miktex\current\texmfs\install\miktex\bin",
                "$env:SCOOP_GLOBAL\apps\miktex\current\miktex\bin\x64",
                "$env:SCOOP_GLOBAL\apps\miktex\current\miktex\bin"
            )
        }
        # If MiKTeX is installed in the local scoop directory
        if ($env:SCOOP -and (Test-Path "$env:SCOOP\apps\miktex\current")) {
            $scoopMiktexBinPaths += @(
                "$env:SCOOP\apps\miktex\current\texmfs\install\miktex\bin\x64",
                "$env:SCOOP\apps\miktex\current\texmfs\install\miktex\bin",
                "$env:SCOOP\apps\miktex\current\miktex\bin\x64",
                "$env:SCOOP\apps\miktex\current\miktex\bin"
            )
        }
        
        foreach ($binPath in $scoopMiktexBinPaths) {
            if ($binPath -and -not [string]::IsNullOrWhiteSpace($binPath) -and (Test-Path -LiteralPath $binPath)) {
                # Check for engines in this directory
                if (Test-Path (Join-Path $binPath 'pdflatex.exe')) { return 'pdflatex' }
                if (Test-Path (Join-Path $binPath 'xelatex.exe')) { return 'xelatex' }
                if (Test-Path (Join-Path $binPath 'luatex.exe')) { return 'luatex' }
            }
        }
    }
    
    return $null
}

<#
.SYNOPSIS
    Ensures a LaTeX engine is available for PDF conversions.
.DESCRIPTION
    Invokes Test-DocumentLatexEngineAvailable and, when no engine is present,
    raises Write-MissingToolWarning with MiKTeX installation guidance before throwing.
.OUTPUTS
    [string] - The detected LaTeX engine name.
.NOTES
    The project assumes Scoop is installed; MiKTeX can be installed via `scoop install miktex`.
#>
function Ensure-DocumentLatexEngine {
    $engine = Test-DocumentLatexEngineAvailable
    if (-not $engine) {
        if (Get-Command Write-MissingToolWarning -ErrorAction SilentlyContinue) {
            Write-MissingToolWarning -Tool 'MiKTeX (pdflatex)' -InstallHint "scoop install miktex"
        }
        throw "LaTeX engine (pdflatex/xelatex/luatex) not found. Install MiKTeX via 'scoop install miktex' or configure pandoc with --pdf-engine."
    }

    return $engine
}

