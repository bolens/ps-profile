Param(
    [Parameter(Mandatory = $true)][string]$ReportPath,
    [Parameter(Mandatory = $false)][string]$ReviewdogLevel = 'error'
)

if (-not (Test-Path $ReportPath)) {
    Write-Output "Report not found: $ReportPath"
    exit 1
}

$items = Get-Content $ReportPath -Raw | ConvertFrom-Json
$diagnostics = @()
foreach ($it in $items) {
    $severity = switch ($it.Severity) {
        'Error' { 'ERROR' }
        'Warning' { 'WARNING' }
        default { 'INFO' }
    }
    $diag = [PSCustomObject]@{
        message  = $it.Message
        severity = $severity
        code     = $it.RuleName
        location = [PSCustomObject]@{
            path      = $it.FilePath
            positions = [PSCustomObject]@{
                begin = [PSCustomObject]@{ line = ($it.Line -as [int]); column = ($it.Column -as [int]) }
                end   = [PSCustomObject]@{ line = ($it.Line -as [int]); column = ($it.Column -as [int]) }
            }
        }
    }
    $diagnostics += $diag
}

$rdjson = [PSCustomObject]@{
    source      = 'PSScriptAnalyzer'
    diagnostics = $diagnostics
}

$outPath = '.\psa_for_reviewdog.rdjson'
$rdjson | ConvertTo-Json -Depth 10 | Out-File -FilePath $outPath -Encoding utf8
Write-Output "Converted $($diagnostics.Count) items to $outPath"
exit 0
