<#
tests/unit/test-runner-test-interactive.tests.ps1

.SYNOPSIS
    Unit tests for TestInteractive module.
#>

BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1

    $modulePath = Join-Path $PSScriptRoot '../../scripts/utils/code-quality/modules'
    Import-Module (Join-Path $modulePath 'TestInteractive.psm1') -Force -Global

    $script:TempDir = New-TestTempDirectory -Prefix 'TestInteractive'
    $script:SampleFile = Join-Path $script:TempDir 'interactive-sample.tests.ps1'
    Set-Content -LiteralPath $script:SampleFile -Value @"
Describe 'Interactive sample' {
    It 'Alpha test case' { `$true | Should -Be `$true }
    It 'Beta test case' { `$true | Should -Be `$true }
}
"@ -Encoding UTF8

    function script:New-SampleTestList {
        $tests = @(
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

        return @{
            TestFiles = @($script:SampleFile)
            TestCount = 2
            Tests     = $tests
        }
    }
}

AfterAll {
    if ($script:TempDir -and (Test-Path -LiteralPath $script:TempDir)) {
        Remove-Item -LiteralPath $script:TempDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Describe 'TestInteractive Module' {
    AfterEach {
        if (Get-Command Restore-TestTerminalStubs -ErrorAction SilentlyContinue) {
            Restore-TestTerminalStubs
        }

        Remove-Item Env:\PS_PROFILE_NONINTERACTIVE -ErrorAction SilentlyContinue
    }

    Context 'Select-TestsInteractively' {
        It 'Returns canceled when no tests are available' {
            $result = Select-TestsInteractively -TestList @{
                TestFiles = @()
                TestCount = 0
                Tests     = @()
            }

            $result.Canceled | Should -Be $false
            @($result.SelectedTests).Count | Should -Be 0
        }

        It 'Disables selection in non-interactive mode' {
            $env:PS_PROFILE_NONINTERACTIVE = '1'
            $result = Select-TestsInteractively -TestList (New-SampleTestList)

            $result.Canceled | Should -Be $true
            @($result.SelectedTests).Count | Should -Be 0
        }

        It 'Selects all tests when user enters all' {
            Set-TestReadHostResponse -Response 'all'
            $result = Select-TestsInteractively -TestList (New-SampleTestList)

            $result.Canceled | Should -Be $false
            @($result.SelectedTests).Count | Should -Be 2
            @($result.SelectedFiles).Count | Should -Be 1
        }

        It 'Filters tests by name pattern' {
            Set-TestReadHostResponse -Response 'filter Alpha'
            $result = Select-TestsInteractively -TestList (New-SampleTestList)

            $result.Canceled | Should -Be $false
            $selected = @($result.SelectedTests)
            $selected.Count | Should -Be 1
            $selected[0]['Name'] | Should -Be 'Alpha test case'
        }

        It 'Cancels when user submits blank input' {
            Set-TestReadHostResponse -Response ''
            $result = Select-TestsInteractively -TestList (New-SampleTestList)

            $result.Canceled | Should -Be $true
        }
    }
}
