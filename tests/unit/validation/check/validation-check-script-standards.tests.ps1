<#
tests/unit/validation-check-script-standards.tests.ps1

.SYNOPSIS
    Behavioral unit tests for check-script-standards.ps1 with isolated script fixtures.
#>

function global:New-ScriptStandardsFixture {
    param(
        [switch]$IncludeDirectExit
    )

    # Outside tests/ so Filter-Files -ExcludeTests does not skip fixture scripts.
    $repo = New-TestExternalTempDirectory -Prefix 'ScriptStandardsRepo'
    $scriptsDir = Join-Path $repo 'scripts' 'utils'
    New-Item -ItemType Directory -Path $scriptsDir -Force | Out-Null

    Set-Content -LiteralPath (Join-Path $scriptsDir 'compliant.ps1') -Value @'
<#
.SYNOPSIS
    Compliant fixture script.
#>
param()
Write-Output 'ok'
'@

    if ($IncludeDirectExit) {
        Set-Content -LiteralPath (Join-Path $scriptsDir 'noncompliant.ps1') -Value @'
<#
.SYNOPSIS
    Noncompliant fixture script.
#>
param()
exit 2
'@
    }

    return @{
        RepositoryRoot = $repo
        ScriptsPath    = $scriptsDir
    }
}

function global:Invoke-ScriptStandardsCheck {
    param(
        [string]$ScriptsPath
    )

    $output = & pwsh -NoProfile -File $script:ScriptStandardsScript -Path $ScriptsPath 2>&1 | Out-String
    return [pscustomobject]@{
        ExitCode = $LASTEXITCODE
        Output   = $output
    }
}

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
    $script:ScriptStandardsScript = Join-Path $script:TestRepoRoot 'scripts' 'checks' 'check-script-standards.ps1'
    $ConfirmPreference = 'None'
}

Describe 'check-script-standards.ps1 execution' {
    It 'Passes when scripts only have informational findings' {
        $fixture = New-ScriptStandardsFixture
        Invoke-ScriptStandardsCheck -ScriptsPath $fixture.ScriptsPath | Select-Object -ExpandProperty ExitCode | Should -Be 0
    }

    It 'Fails when a script uses a direct exit call' {
        $fixture = New-ScriptStandardsFixture -IncludeDirectExit
        $result = Invoke-ScriptStandardsCheck -ScriptsPath $fixture.ScriptsPath

        $result.ExitCode | Should -BeIn @(1, 2)
        $result.Output | Should -Match 'noncompliant|direct exit|exit call'
    }

    It 'Fails parameter validation when the requested path does not exist' {
        $missingPath = Join-Path (New-TestTempDirectory -Prefix 'ScriptStandardsMissingPath') 'does-not-exist'
        $result = Invoke-ScriptStandardsCheck -ScriptsPath $missingPath

        $result.ExitCode | Should -Not -Be 0
        $result.Output | Should -Match 'Path does not exist|does not exist'
    }
}
