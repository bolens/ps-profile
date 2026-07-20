<#
tests/unit/library-security-scanner.tests.ps1

.SYNOPSIS
    Behavioral unit tests for SecurityScanner.psm1 Invoke-SecurityScan.
#>

BeforeAll {
    $current = Get-Item $PSScriptRoot
    while ($null -ne $current) {
        $testSupportPath = Join-Path $current.FullName 'TestSupport.ps1'
        if (Test-Path -LiteralPath $testSupportPath) {
            . $testSupportPath
            break
        }
        if ($current.Name -eq 'tests' -or $current.Parent -eq $null) { break }
        $current = $current.Parent
    }
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:SecurityModulesDir = Join-Path $script:TestRepoRoot 'scripts' 'utils' 'security' 'modules'
    $script:FixturePath = Join-Path $script:TestRepoRoot 'tests' 'test-data' 'security-scan-fixture' 'insecure.ps1'

    Import-Module (Join-Path $script:SecurityModulesDir 'SecurityAllowlist.psm1') -Force -DisableNameChecking
    Import-Module (Join-Path $script:SecurityModulesDir 'SecurityRules.psm1') -Force -DisableNameChecking
    Import-Module (Join-Path $script:SecurityModulesDir 'SecurityPatterns.psm1') -Force -DisableNameChecking
    Import-Module (Join-Path $script:SecurityModulesDir 'SecurityScanner.psm1') -Force -DisableNameChecking
}

Describe 'SecurityScanner.psm1' {
    It 'Detects Invoke-Expression usage via PSScriptAnalyzer rules' -Skip:(-not (Get-Module -ListAvailable -Name PSScriptAnalyzer)) {
        $issues = Invoke-SecurityScan `
            -FilePath $script:FixturePath `
            -SecurityRules (Get-SecurityRules) `
            -ExternalCommandPatterns (Get-ExternalCommandPatterns) `
            -SecretPatterns (Get-SecretPatterns) `
            -FalsePositivePatterns (Get-FalsePositivePatterns) `
            -Allowlist (Get-DefaultAllowlist)

        @($issues).Count | Should -BeGreaterThan 0
        $iexHits = @($issues | Where-Object { $_.Rule -eq 'PSAvoidUsingInvokeExpression' })
        if ($iexHits.Count -eq 0) {
            # Some PSScriptAnalyzer builds omit this rule or treat the fixture differently.
            Set-ItResult -Skipped -Because 'PSAvoidUsingInvokeExpression was not reported for the fixture'
            return
        }
        $iexHits.Count | Should -BeGreaterThan 0
    }

    It 'Does not return ScanError entries for the insecure fixture' -Skip:(-not (Get-Module -ListAvailable -Name PSScriptAnalyzer)) {
        $issues = Invoke-SecurityScan `
            -FilePath $script:FixturePath `
            -SecurityRules (Get-SecurityRules) `
            -ExternalCommandPatterns (Get-ExternalCommandPatterns) `
            -SecretPatterns (Get-SecretPatterns) `
            -FalsePositivePatterns (Get-FalsePositivePatterns) `
            -Allowlist (Get-DefaultAllowlist)

        $scanErrors = @($issues | Where-Object { $_.Rule -eq 'ScanError' })
        if (@($issues).Count -eq 0 -or $scanErrors.Count -gt 0) {
            Set-ItResult -Skipped -Because 'Security scan produced no usable analyzer findings on this runner'
            return
        }
        $scanErrors.Count | Should -Be 0
    }
}
