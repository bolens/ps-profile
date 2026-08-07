<#
tests/unit/utility-validate-dependencies.tests.ps1

.SYNOPSIS
    Behavioral unit tests for validate-dependencies.ps1 with isolated requirements fixtures.
#>

function global:New-ValidateDependenciesRequirementsFile {
    param(
        [switch]$RequireMissingModule,

        [string]$MissingModuleName = 'Definitely-Not-Installed-Module-12345'
    )

    $requirementsPath = Join-Path (New-TestTempDirectory -Prefix 'ValidateDepsReq') 'requirements.psd1'
    if ($RequireMissingModule) {
        $content = @'
@{
    PowerShellVersion = '5.1'
    Modules = @{
        '__MISSING_MODULE__' = @{
            Version = '1.0.0'
            Required = $true
        }
    }
    ExternalTools = @{}
}
'@
        $content = $content.Replace('__MISSING_MODULE__', $MissingModuleName)
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
    ExternalTools = @{}
}
'@
    }

    Set-Content -LiteralPath $requirementsPath -Value $content -Encoding UTF8
    return $requirementsPath
}

function global:Invoke-ValidateDependenciesInProcess {
    param(
        [Parameter(Mandatory)]
        [string]$RequirementsFile,

        [switch]$InstallMissing,

        [scriptblock]$ModuleInstallAction = { param($ModuleName) },

        [scriptblock]$ModuleLookupAction = { param($ModuleName) $null },

        [scriptblock]$CommandTestAction = { param($CommandName) $false }
    )

    $records = @(& $script:ValidateDependenciesScript -RequirementsFile $RequirementsFile -InstallMissing:$InstallMissing `
            -ModuleInstallAction $ModuleInstallAction -ModuleLookupAction $ModuleLookupAction `
            -CommandTestAction $CommandTestAction -PassThru *>&1)
    $exitResult = $records | Where-Object { $_.PSObject.Properties.Name -contains 'ExitCode' } | Select-Object -Last 1
    $output = @($records | Where-Object { $_ -ne $exitResult }) | Out-String -Width 4096
    if ($exitResult.Message) {
        $output = "$output$($exitResult.Message)"
    }

    [PSCustomObject]@{
        ExitCode = $exitResult.ExitCode
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
    $script:ValidateDependenciesScript = Join-Path $script:TestRepoRoot 'scripts' 'utils' 'dependencies' 'validate-dependencies.ps1'
    $ConfirmPreference = 'None'
}

Describe 'validate-dependencies.ps1 execution' {
    It 'Passes when the requirements fixture only contains optional satisfied dependencies' {
        $requirementsFile = New-ValidateDependenciesRequirementsFile
        $result = Invoke-ValidateDependenciesInProcess -RequirementsFile $requirementsFile
        $result.ExitCode | Should -Be 0
        $result.Output | Should -Match 'Dependencies|validation|passed|success'
    }

    It 'Fails when a required module from the requirements fixture is missing' {
        $requirementsFile = New-ValidateDependenciesRequirementsFile -RequireMissingModule
        $result = Invoke-ValidateDependenciesInProcess -RequirementsFile $requirementsFile
        $result.ExitCode | Should -Be 1
        $result.Output | Should -Match 'Definitely-Not-Installed-Module-12345|missing|Missing'
    }

    It 'Completes after the supplied installer handles a missing required module' {
        $moduleName = 'Definitely-Not-Installed-Module-Installer-12345'
        $requirementsFile = New-ValidateDependenciesRequirementsFile -RequireMissingModule -MissingModuleName $moduleName

        $result = Invoke-ValidateDependenciesInProcess -RequirementsFile $requirementsFile -InstallMissing `
            -ModuleInstallAction { param($ModuleName) }

        $result.ExitCode | Should -Be 0
        $result.Output | Should -Match 'installed|validation passed'
    }

    It 'Fails setup when the requirements file path does not exist' {
        $missingRequirements = Join-Path (New-TestTempDirectory -Prefix 'ValidateDepsMissing') 'missing-requirements.psd1'
        $result = Invoke-ValidateDependenciesInProcess -RequirementsFile $missingRequirements

        $result.ExitCode | Should -Be 2
        $result.Output | Should -Match 'Requirements file not found|missing-requirements\.psd1'
    }

    It 'Treats a module lookup error as a missing required dependency' {
        $moduleName = 'Unqueryable-Required-Module-12345'
        $requirementsFile = New-ValidateDependenciesRequirementsFile -RequireMissingModule -MissingModuleName $moduleName
        $moduleLookup = {
            param($ModuleName)
            throw "Lookup failed for $ModuleName"
        }

        $result = Invoke-ValidateDependenciesInProcess -RequirementsFile $requirementsFile `
            -ModuleLookupAction $moduleLookup

        $result.ExitCode | Should -Be 1
        $result.Output | Should -Match 'Unqueryable-Required-Module-12345|Lookup failed'
    }

    It 'Fails setup when the requirements data file is invalid' {
        $requirementsFile = Join-Path (New-TestTempDirectory -Prefix 'ValidateDepsInvalid') 'requirements.psd1'
        Set-Content -LiteralPath $requirementsFile -Value '@{ Invalid =' -Encoding UTF8

        $result = Invoke-ValidateDependenciesInProcess -RequirementsFile $requirementsFile

        $result.ExitCode | Should -Be 2
        $result.Output | Should -Match 'Failed to load requirements file|requirements\.psd1'
    }

    It 'Reports version mismatches and required and optional external tools' {
        $requirementsFile = Join-Path (New-TestTempDirectory -Prefix 'ValidateDepsTools') 'requirements.psd1'
        @'
@{
    PowerShellVersion = '99.0'
    Modules = @{
        'Microsoft.PowerShell.Utility' = @{
            Version = '99.0.0'
            Required = $true
        }
    }
    ExternalTools = @{
        'pwsh' = @{
            Required = $true
        }
        'Definitely-Not-A-Required-Tool-12345' = @{
            Required = $true
            InstallCommand = 'install-required-tool'
        }
        'Definitely-Not-An-Optional-Tool-12345' = @{
            Required = $false
            InstallCommand = @{
                Windows = 'install-optional-tool-windows'
                Linux = 'install-optional-tool-linux'
                macOS = 'install-optional-tool-macos'
            }
        }
    }
}
'@ | Set-Content -LiteralPath $requirementsFile -Encoding UTF8

        $result = Invoke-ValidateDependenciesInProcess -RequirementsFile $requirementsFile

        $result.ExitCode | Should -Be 1
        $result.Output | Should -Match 'PowerShell version mismatch|Version mismatch'
        $result.Output | Should -Match 'Definitely-Not-A-Required-Tool-12345'
        $result.Output | Should -Match 'Definitely-Not-An-Optional-Tool-12345'
        $result.Output | Should -Match 'install-required-tool|install-optional-tool'
    }

}
