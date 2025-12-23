$libPath = 'scripts\lib'
$testPath = 'tests\unit'

$modules = Get-ChildItem $libPath\*.psm1 | ForEach-Object { $_.BaseName }
$testFiles = Get-ChildItem $testPath\library-*.tests.ps1 | ForEach-Object { $_.BaseName }

# Map test file names to module names
$testToModule = @{
    'library-path-resolution' = 'PathResolution'
    'library-module-import' = 'ModuleImport'
    'library-fragment-error-handling' = 'FragmentErrorHandling'
    'library-fragment-loading' = 'FragmentLoading'
    'library-fragment-idempotency' = 'FragmentIdempotency'
    'library-fragment-config' = 'FragmentConfig'
    'library-path-validation' = 'PathValidation'
    'library-path-utilities' = 'PathUtilities'
    'library-file-content' = 'FileContent'
    'library-file-filtering' = 'FileFiltering'
    'library-json-utilities' = 'JsonUtilities'
    'library-json-utilities-extended' = 'JsonUtilities'
    'library-powershell-detection' = 'PowerShellDetection'
    'library-codeanalysis' = 'CodeMetrics'  # May cover multiple code analysis modules
    'library-performance' = 'PerformanceMeasurement'  # May cover multiple performance modules
    'library-metrics' = 'MetricsSnapshot'  # May cover multiple metrics modules
    'library-path' = 'PathResolution'  # May be duplicate
}

$testedModules = @()
foreach ($testFile in $testFiles) {
    $testName = $testFile -replace 'library-', '' -replace '\.tests', ''
    if ($testToModule.ContainsKey($testName)) {
        $testedModules += $testToModule[$testName]
    }
    else {
        # Try to match by name (e.g., library-cache -> Cache)
        $moduleName = $testName -replace '-', ''
        $moduleName = $moduleName.Substring(0,1).ToUpper() + $moduleName.Substring(1)
        if ($modules -contains $moduleName) {
            $testedModules += $moduleName
        }
        else {
            # Try exact match with dashes
            $moduleName = $testName -replace '-', '-'
            $parts = $moduleName -split '-'
            $moduleName = ($parts | ForEach-Object { $_.Substring(0,1).ToUpper() + $_.Substring(1) }) -join ''
            if ($modules -contains $moduleName) {
                $testedModules += $moduleName
            }
        }
    }
}

$testedModules = $testedModules | Select-Object -Unique
$missing = $modules | Where-Object { $testedModules -notcontains $_ }

Write-Host "Total modules: $($modules.Count)"
Write-Host "Total test files: $($testFiles.Count)"
Write-Host "Modules with tests: $($testedModules.Count)"
Write-Host "`nMissing tests for:"
$missing | Sort-Object | ForEach-Object { Write-Host "  - $_" }
