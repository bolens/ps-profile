# ===============================================
# profile-re-tools-pe.tests.ps1
# Unit tests for Analyze-PE function
# ===============================================

BeforeAll {
    . (Join-Path $PSScriptRoot '..\TestSupport.ps1')
    $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
    . (Join-Path $script:ProfileDir 'bootstrap.ps1')
    . (Join-Path $script:ProfileDir 're-tools.ps1')
    $script:TestWorkDir = New-TestTempDirectory -Prefix 'AnalyzePE'
    $script:TestExeFile = Join-Path $script:TestWorkDir 'test.exe'
    Set-Content -Path $script:TestExeFile -Value 'fake exe' -Encoding utf8
}

Describe 're-tools.ps1 - Analyze-PE' {
    BeforeEach {
        Clear-TestCommandInvocationCapture

        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }

        Mark-TestCommandsUnavailable -CommandNames @('pe-bear', 'exeinfo-pe', 'detect-it-easy')
    }

    Context 'Tool not available' {
        It 'Returns null when no PE analysis tools are available' {
            $result = Analyze-PE -InputFile $script:TestExeFile -ErrorAction SilentlyContinue

            $result | Should -BeNullOrEmpty
        }
    }

    Context 'Tool preference' {
        It 'Prefers pe-bear over other tools' {
            Setup-CapturingCommandMock -CommandName 'pe-bear' -Output 'Analysis started'
            Set-TestCommandAvailabilityState -CommandName 'exeinfo-pe' -Available $true
            Set-TestCommandAvailabilityState -CommandName 'detect-it-easy' -Available $true

            Analyze-PE -InputFile $script:TestExeFile -ErrorAction SilentlyContinue | Out-Null

            $global:TestCommandInvocationCaptures.Count | Should -Be 1
            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain $script:TestExeFile
        }

        It 'Falls back to exeinfo-pe when pe-bear is not available' {
            Setup-CapturingCommandMock -CommandName 'exeinfo-pe' -Output 'Analysis results'
            Mark-TestCommandsUnavailable -CommandNames @('pe-bear', 'detect-it-easy')

            Test-CachedCommand 'exeinfo-pe' | Should -Be $true

            Analyze-PE -InputFile $script:TestExeFile -ErrorAction SilentlyContinue | Out-Null

            $global:TestCommandInvocationCaptures.Count | Should -Be 1
        }

        It 'Falls back to detect-it-easy when pe-bear and exeinfo-pe are not available' {
            Setup-CapturingCommandMock -CommandName 'detect-it-easy' -Output 'Analysis started'
            Mark-TestCommandsUnavailable -CommandNames @('pe-bear', 'exeinfo-pe')

            Test-CachedCommand 'detect-it-easy' | Should -Be $true

            Analyze-PE -InputFile $script:TestExeFile -ErrorAction SilentlyContinue | Out-Null

            $global:TestCommandInvocationCaptures.Count | Should -Be 1
        }
    }

    Context 'Tool available' {
        It 'Calls pe-bear with input file' {
            Setup-CapturingCommandMock -CommandName 'pe-bear' -Output 'Analysis started'

            $result = Analyze-PE -InputFile $script:TestExeFile -ErrorAction SilentlyContinue

            $global:TestCommandInvocationCaptures.Count | Should -Be 1
            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain $script:TestExeFile
            $result | Should -Match 'GUI tool'
        }

        It 'Calls exeinfo-pe with output path when specified' {
            $script:OutputFile = Join-Path $script:TestWorkDir 'output.txt'
            if (Test-Path -LiteralPath $script:OutputFile) {
                Remove-Item -LiteralPath $script:OutputFile -Force
            }

            Setup-CapturingCommandMock -CommandName 'exeinfo-pe' -Output 'Analysis results' -OnInvoke {
                Set-Content -Path $script:OutputFile -Value 'analysis' -Force
            }
            Mark-TestCommandsUnavailable -CommandNames @('pe-bear', 'detect-it-easy')

            $result = Analyze-PE -InputFile $script:TestExeFile -OutputPath $script:OutputFile -ErrorAction SilentlyContinue

            $global:TestCommandInvocationCaptures.Count | Should -Be 1
            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain '-o'
            $args | Should -Contain $script:OutputFile
            $result | Should -Be $script:OutputFile
        }

        It 'Handles missing input file' {
            Setup-CapturingCommandMock -CommandName 'pe-bear'
            $missingFile = Join-Path $script:TestWorkDir 'missing.exe'

            $result = Analyze-PE -InputFile $missingFile -ErrorAction SilentlyContinue

            $result | Should -BeNullOrEmpty
        }
    }
}
