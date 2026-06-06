# ===============================================
# lang-go.ps1
# Go development tools (compatibility loader)
# ===============================================
# Tier: standard
# Dependencies: bootstrap, env, lang-go-basic

<#
.SYNOPSIS
    Go development tools compatibility loader.

.DESCRIPTION
    Loads lang-go-tools.ps1 which provides goreleaser, mage, golangci-lint,
    and enhanced build/test wrappers. Basic go operations live in lang-go-basic.ps1.

.NOTES
    This loader preserves the lang-go.ps1 fragment path for tests and documentation.
    The monolithic lang-go.ps1 was split into lang-go-basic.ps1 and lang-go-tools.ps1.
#>

try {
    if (Get-Command Test-FragmentLoaded -ErrorAction SilentlyContinue) {
        if (Test-FragmentLoaded -FragmentName 'lang-go') { return }
    }

    $toolsPath = Join-Path $PSScriptRoot 'lang-go-tools.ps1'
    if (Test-Path -LiteralPath $toolsPath) {
        . $toolsPath
    }
    else {
        throw "lang-go-tools.ps1 not found at: $toolsPath"
    }

    if (Get-Command Set-FragmentLoaded -ErrorAction SilentlyContinue) {
        Set-FragmentLoaded -FragmentName 'lang-go'
    }
}
catch {
    if (Get-Command Write-ProfileError -ErrorAction SilentlyContinue) {
        Write-ProfileError -FragmentName 'lang-go' -ErrorRecord $_
    }
    else {
        Write-Error "Failed to load lang-go fragment: $($_.Exception.Message)"
    }
}
