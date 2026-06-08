<#
tests/unit/test-runner-test-interactive-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for Select-TestsInteractively selection modes.
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
    $modulePath = Join-Path (Get-TestRepoRoot -StartPath $PSScriptRoot) 'scripts/utils/code-quality/modules'
    Import-Module (Join-Path $modulePath 'TestInteractive.psm1') -Force -Global

    $script:TempDir = New-TestTempDirectory -Prefix 'TestInteractiveExtended'
    $script:SampleFile = Join-Path $script:TempDir 'interactive-sample.tests.ps1'
    Set-Content -LiteralPath $script:SampleFile -Value @"
Describe 'Interactive sample' {
    It 'Alpha test case' { `$true | Should -Be `$true }
    It 'Beta test case' { `$true | Should -Be `$true }
}
"@ -Encoding UTF8

    function script:New-SampleTestList {
        return @{
            TestFiles = @($script:SampleFile)
            TestCount = 2
            Tests     = @(
                @{
                    Name     = 'Alpha test case'
                    File     = $script:SampleFile
                    Describe = 'Interactive sample'
                    Context  = ''
                },
                @{
                    Name     = 'Beta test case'
                    File     = $script:SampleFile
                    Describe = 'Interactive sample'
                    Context  = ''
                }
            )
        }
    }
}

AfterAll {
    if ($script:TempDir -and (Test-Path -LiteralPath $script:TempDir)) {
        Remove-Item -LiteralPath $script:TempDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Describe 'TestInteractive extended scenarios' {
    AfterEach {
        if (Get-Command Restore-TestTerminalStubs -ErrorAction SilentlyContinue) {
            Restore-TestTerminalStubs
        }

        Remove-Item Env:\PS_PROFILE_NONINTERACTIVE -ErrorAction SilentlyContinue
        Remove-Item Env:\CI -ErrorAction SilentlyContinue
        Remove-Item Env:\GITHUB_ACTIONS -ErrorAction SilentlyContinue
    }

    Context 'Select-TestsInteractively' {
        BeforeEach {
            Remove-Item Env:\PS_PROFILE_NONINTERACTIVE -ErrorAction SilentlyContinue
            Remove-Item Env:\CI -ErrorAction SilentlyContinue
            Remove-Item Env:\GITHUB_ACTIONS -ErrorAction SilentlyContinue
        }

        It 'Selects tests by file index' {
            Set-TestReadHostResponse -Response '1'
            $result = Select-TestsInteractively -TestList (New-SampleTestList)

            $result.Canceled | Should -Be $false
            @($result.SelectedTests).Count | Should -Be 2
            @($result.SelectedFiles).Count | Should -Be 1
        }

        It 'Cancels when filter pattern matches no tests' {
            Set-TestReadHostResponse -Response 'filter ZZZNoMatch'
            $result = Select-TestsInteractively -TestList (New-SampleTestList)

            $result.Canceled | Should -Be $true
            @($result.SelectedTests).Count | Should -Be 0
        }

        It 'Disables selection when GitHub Actions CI is detected' {
            Mock-EnvironmentVariable -Name 'GITHUB_ACTIONS' -Value 'true'
            $result = Select-TestsInteractively -TestList (New-SampleTestList)

            $result.Canceled | Should -Be $true
            @($result.SelectedTests).Count | Should -Be 0
        }

        It 'Cancels when file index selection is invalid' {
            Set-TestReadHostResponse -Response '999'
            $result = Select-TestsInteractively -TestList (New-SampleTestList)

            $result.Canceled | Should -Be $true
        }
    }
}
