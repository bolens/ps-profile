<#
tests/unit/utility-validate-dependencies.tests.ps1

.SYNOPSIS
    Behavioral unit tests for validate-dependencies.ps1 with isolated requirements fixtures.
#>

function global:New-ValidateDependenciesRequirementsFile {
    param(
        [switch]$RequireMissingModule
    )

    $requirementsPath = Join-Path (New-TestTempDirectory -Prefix 'ValidateDepsReq') 'requirements.psd1'
    if ($RequireMissingModule) {
        $content = @'
@{
    Modules = @{
        'Definitely-Not-Installed-Module-12345' = @{
            Version = '1.0.0'
            Required = $true
        }
    }
}
'@
    }
    else {
        $content = @'
@{
    PowerShellVersion = '5.1'
    Modules = @{
        'Microsoft.PowerShell.Utility' = @{
            Version = '0.0.0'
            Required = $false
        }
    }
}
'@
    }

    Set-Content -LiteralPath $requirementsPath -Value $content -Encoding UTF8
    return $requirementsPath
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
    $script:ValidateDependenciesScript = Join-Path $script:TestRepoRoot 'scripts' 'utils' 'dependencies' 'validate-dependencies.ps1'
    $ConfirmPreference = 'None'
}

Describe 'validate-dependencies.ps1 execution' {
    It 'Passes when the requirements fixture only contains optional satisfied dependencies' {
        $requirementsFile = New-ValidateDependenciesRequirementsFile
        try {
            $result = Invoke-TestScriptFile -ScriptPath $script:ValidateDependenciesScript -ArgumentList @(
                '-RequirementsFile', $requirementsFile
            )
            $result.ExitCode | Should -Be 0
        }
        finally {
            $parent = Split-Path -Parent $requirementsFile
            if (Test-Path -LiteralPath $parent) {
                Remove-Item -LiteralPath $parent -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }

    It 'Fails when a required module from the requirements fixture is missing' {
        $requirementsFile = New-ValidateDependenciesRequirementsFile -RequireMissingModule
        try {
            $result = Invoke-TestScriptFile -ScriptPath $script:ValidateDependenciesScript -ArgumentList @(
                '-RequirementsFile', $requirementsFile
            )
            $result.ExitCode | Should -BeIn @(1, 2)
            $result.Output | Should -Match 'Definitely-Not-Installed-Module-12345|missing|Missing'
        }
        finally {
            $parent = Split-Path -Parent $requirementsFile
            if (Test-Path -LiteralPath $parent) {
                Remove-Item -LiteralPath $parent -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }

    It 'Fails setup when the requirements file path does not exist' {
        $missingRequirements = Join-Path (New-TestTempDirectory -Prefix 'ValidateDepsMissing') 'missing-requirements.psd1'
        try {
            $result = Invoke-TestScriptFile -ScriptPath $script:ValidateDependenciesScript -ArgumentList @(
                '-RequirementsFile', $missingRequirements
            )

            $result.ExitCode | Should -Be 2
            $result.Output | Should -Match 'Requirements file not found|missing-requirements\.psd1'
        }
        finally {
            $parent = Split-Path -Parent $missingRequirements
            if (Test-Path -LiteralPath $parent) {
                Remove-Item -LiteralPath $parent -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }
}
