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

function global:New-ValidateDependenciesCustomRequirementsFile {
    param(
        [Parameter(Mandatory)]
        [string]$Content
    )

    $requirementsPath = Join-Path (New-TestTempDirectory -Prefix 'ValidateDepsCustom') 'requirements.psd1'
    Set-Content -LiteralPath $requirementsPath -Value $Content -Encoding UTF8
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

    It 'Uses the default module lookup for a built-in module' {
        $requirementsFile = New-ValidateDependenciesRequirementsFile
        $records = @(& $script:ValidateDependenciesScript -RequirementsFile $requirementsFile -PassThru *>&1)
        $exitResult = $records | Where-Object { $_.PSObject.Properties.Name -contains 'ExitCode' } | Select-Object -Last 1

        $exitResult.ExitCode | Should -Be 0
        ($records | Out-String -Width 4096) | Should -Match 'Microsoft.PowerShell.Utility.*Installed'
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

    It 'Covers installed modules and available and failed tool lookups' {
        $requirementsFile = New-ValidateDependenciesCustomRequirementsFile -Content @'
@{
    PowerShellVersion = '5.1'
    Modules = @{
        'Current-Module-For-Validation' = @{ Version = '1.0.0'; Required = $true }
        'Outdated-Module-For-Validation' = @{ Version = '2.0.0'; Required = $true }
    }
    ExternalTools = @{
        'Available-Tool-For-Validation' = @{ Required = $true }
        'Lookup-Error-Tool-For-Validation' = @{ Required = $true }
    }
}
'@
        $moduleLookup = {
            param($ModuleName)
            switch ($ModuleName) {
                'Current-Module-For-Validation' { [PSCustomObject]@{ Version = [version]'1.0.0' } }
                'Outdated-Module-For-Validation' { [PSCustomObject]@{ Version = [version]'1.0.0' } }
                default { $null }
            }
        }
        $commandLookup = {
            param($CommandName)
            if ($CommandName -eq 'Lookup-Error-Tool-For-Validation') {
                throw 'tool lookup failed'
            }
            return $true
        }

        $previousDebug = $env:PS_PROFILE_DEBUG
        try {
            $env:PS_PROFILE_DEBUG = '3'
            $result = Invoke-ValidateDependenciesInProcess -RequirementsFile $requirementsFile `
                -ModuleLookupAction $moduleLookup -CommandTestAction $commandLookup
        }
        finally {
            $env:PS_PROFILE_DEBUG = $previousDebug
        }

        $result.ExitCode | Should -Be 1
        $result.Output | Should -Match 'Current-Module-For-Validation.*Installed'
        $result.Output | Should -Match 'Outdated-Module-For-Validation.*Version mismatch'
        $result.Output | Should -Match 'Available-Tool-For-Validation.*Available'
        $result.Output | Should -Match 'tool lookup failed|Lookup-Error-Tool-For-Validation'
    }

    It 'Reports a failed automatic module installation' {
        $moduleName = 'Failed-Install-Module-For-Validation'
        $requirementsFile = New-ValidateDependenciesRequirementsFile -RequireMissingModule -MissingModuleName $moduleName

        $result = Invoke-ValidateDependenciesInProcess -RequirementsFile $requirementsFile -InstallMissing `
            -ModuleInstallAction { param($ModuleName) throw "install failed for $ModuleName" }

        $result.ExitCode | Should -Be 1
        $result.Output | Should -Match 'install failed|Failed-Install-Module-For-Validation'
    }

}
