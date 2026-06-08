<#
tests/unit/profile-tool-wrapper-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for Register-ToolWrapper forwarding and command types.
#>

BeforeAll {
    . (Join-Path $PSScriptRoot '..\TestSupport.ps1')

    $script:BootstrapDir = Get-TestPath -RelativePath 'profile.d\bootstrap' -StartPath $PSScriptRoot -EnsureExists
    . (Join-Path $script:BootstrapDir 'GlobalState.ps1')
    . (Join-Path $script:BootstrapDir 'CommandCache.ps1')
    . (Join-Path $script:BootstrapDir 'MissingToolWarnings.ps1')
    . (Join-Path $script:BootstrapDir 'FunctionRegistration.ps1')

    $script:TempDir = New-TestTempDirectory -Prefix 'ToolWrapperExtended'
}

AfterAll {
    if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
        Clear-TestCachedCommandCache | Out-Null
    }

    if ($script:TempDir -and (Test-Path -LiteralPath $script:TempDir)) {
        Remove-Item -LiteralPath $script:TempDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Describe 'Register-ToolWrapper extended scenarios' {
    BeforeEach {
        $script:WrapperName = "ExtendedWrapper_$(Get-Random)"
        $script:SourceName = "ExtendedSource_$(Get-Random)"
    }

    AfterEach {
        Remove-Item -Path "Function:\global:$script:WrapperName" -Force -ErrorAction SilentlyContinue
        Remove-Item -Path "Function:\global:$script:SourceName" -Force -ErrorAction SilentlyContinue
    }

    Context 'Register-ToolWrapper' {
        It 'Forwards arguments to an underlying function command' {
            Set-Item -Path "Function:\global:$script:SourceName" -Value {
                param([string]$Value)
                "received:$Value"
            }.GetNewClosure() -Force

            Register-ToolWrapper -FunctionName $script:WrapperName -CommandName $script:SourceName -CommandType Function |
                Should -Be $true

            & $script:WrapperName 'payload' | Should -Be 'received:payload'
        }

        It 'Returns false when attempting to register duplicate wrapper names' {
            Register-ToolWrapper -FunctionName $script:WrapperName -CommandName 'pwsh' | Should -Be $true
            Register-ToolWrapper -FunctionName $script:WrapperName -CommandName 'pwsh' | Should -Be $false
        }

        It 'Accepts InstallPackageName for missing-tool messaging' {
            $missingCmd = "MissingCmd_$(Get-Random)"

            Register-ToolWrapper -FunctionName $script:WrapperName `
                -CommandName $missingCmd `
                -InstallPackageName 'custom-package' |
                Should -Be $true

            Get-Command $script:WrapperName -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Returns false for whitespace function names without creating a wrapper' {
            Register-ToolWrapper -FunctionName '   ' -CommandName 'pwsh' | Should -Be $false
            Get-Command '   ' -ErrorAction SilentlyContinue | Should -BeNullOrEmpty
        }
    }
}
