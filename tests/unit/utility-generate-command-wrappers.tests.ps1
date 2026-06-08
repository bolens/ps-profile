<#
tests/unit/utility-generate-command-wrappers.tests.ps1

.SYNOPSIS
    Behavioral unit tests for generate-command-wrappers.ps1.
#>

BeforeAll {
    . (Join-Path $PSScriptRoot '..\TestSupport.ps1')

    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:GenerateScript = Join-Path $script:TestRepoRoot 'scripts' 'utils' 'fragment' 'generate-command-wrappers.ps1'
    $script:RegistryModulePath = Join-Path $script:TestRepoRoot 'scripts' 'lib' 'fragment' 'FragmentCommandRegistry.psm1'

    Import-Module $script:RegistryModulePath -DisableNameChecking -Force -ErrorAction Stop
    if (-not (Get-Variable -Name 'FragmentCommandRegistry' -Scope Global -ErrorAction SilentlyContinue)) {
        $global:FragmentCommandRegistry = @{}
    }
}

Describe 'generate-command-wrappers.ps1 execution' {
    BeforeEach {
        if (Get-Variable -Name 'FragmentCommandRegistry' -Scope Global -ErrorAction SilentlyContinue) {
            $global:FragmentCommandRegistry.Clear()
        }
    }

    AfterAll {
        if (Get-Variable -Name 'FragmentCommandRegistry' -Scope Global -ErrorAction SilentlyContinue) {
            $global:FragmentCommandRegistry.Clear()
        }
    }

    It 'Fails validation when the registry has no commands' {
        $outputDir = New-TestTempDirectory -Prefix 'WrapperEmpty'
        try {
            & pwsh -NoProfile -File $script:GenerateScript -OutputPath $outputDir 2>&1 | Out-Null
            $LASTEXITCODE | Should -Be 1
        }
        finally {
            if (Test-Path -LiteralPath $outputDir) {
                Remove-Item -LiteralPath $outputDir -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }

    It 'DryRun reports a wrapper plan for a registered function command' {
        $null = Register-FragmentCommand -CommandName 'Invoke-WrapperTest' -FragmentName 'bootstrap' -CommandType 'Function'
        $outputDir = New-TestTempDirectory -Prefix 'WrapperDryRun'

        try {
            $output = & $script:GenerateScript -DryRun -CommandName 'Invoke-WrapperTest' -OutputPath $outputDir *>&1 | Out-String
            $LASTEXITCODE | Should -Be 0
            $output | Should -Match '\[GENERATE\] Invoke-WrapperTest'
            $expectedPath = [regex]::Escape((Join-Path $outputDir 'Invoke-WrapperTest.ps1'))
            $output | Should -Match $expectedPath
            Test-Path -LiteralPath (Join-Path $outputDir 'Invoke-WrapperTest.ps1') | Should -Be $false
        }
        finally {
            if (Test-Path -LiteralPath $outputDir) {
                Remove-Item -LiteralPath $outputDir -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }
}
