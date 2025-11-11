# Wrapper module to provide scripts/utils/Common.psm1 for legacy imports

$repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$commonModulePath = Join-Path $repoRoot 'scripts\lib\Common.psm1'

if (-not (Test-Path -LiteralPath $commonModulePath)) {
    throw "Common module not found at $commonModulePath"
}

Import-Module -Name $commonModulePath -DisableNameChecking -ErrorAction Stop

Export-ModuleMember -Function * -Alias *
