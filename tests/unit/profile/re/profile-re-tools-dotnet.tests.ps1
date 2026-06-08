# ===============================================
# profile-re-tools-dotnet.tests.ps1
# Unit tests for Decompile-DotNet function
# ===============================================

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
    $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
    . (Join-Path $script:ProfileDir 'bootstrap.ps1')
    . (Join-Path $script:ProfileDir 're-tools.ps1')
    $script:TestWorkDir = New-TestTempDirectory -Prefix 'DecompileDotNet'
    $script:TestDllFile = Join-Path $script:TestWorkDir 'test.dll'
    Set-Content -Path $script:TestDllFile -Value 'fake dll' -Encoding utf8
}

Describe 're-tools.ps1 - Decompile-DotNet' {
    BeforeEach {
        Clear-TestCommandInvocationCapture

        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }

        Mark-TestCommandsUnavailable -CommandNames @('dnspyex', 'dnspy')
    }

    Context 'Tool not available' {
        It 'Returns null when neither dnspyex nor dnspy is available' {
            $result = Decompile-DotNet -InputFile $script:TestDllFile -ErrorAction SilentlyContinue

            $result | Should -BeNullOrEmpty
        }
    }

    Context 'Tool preference' {
        It 'Prefers dnspyex over dnspy when both are available' {
            Setup-CapturingCommandMock -CommandName 'dnspyex' -ExitCode 0
            Set-TestCommandAvailabilityState -CommandName 'dnspy' -Available $true

            Decompile-DotNet -InputFile $script:TestDllFile -OutputPath $script:TestWorkDir -ErrorAction SilentlyContinue | Out-Null

            $global:TestCommandInvocationCaptures.Count | Should -Be 1
            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain '-o'
            $args | Should -Contain $script:TestDllFile
        }

        It 'Falls back to dnspy when dnspyex is not available' {
            Setup-CapturingCommandMock -CommandName 'dnspy' -ExitCode 0
            Mark-TestCommandsUnavailable -CommandNames 'dnspyex'

            Decompile-DotNet -InputFile $script:TestDllFile -OutputPath $script:TestWorkDir -ErrorAction SilentlyContinue | Out-Null

            $global:TestCommandInvocationCaptures.Count | Should -Be 1
        }
    }

    Context 'Tool available' {
        It 'Calls tool with input file and output path' {
            Setup-CapturingCommandMock -CommandName 'dnspyex' -ExitCode 0

            Decompile-DotNet -InputFile $script:TestDllFile -OutputPath $script:TestWorkDir -ErrorAction SilentlyContinue | Out-Null

            $global:TestCommandInvocationCaptures.Count | Should -Be 1
            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain '-o'
            $args | Should -Contain $script:TestDllFile
        }

        It 'Uses IL format when specified' {
            Setup-CapturingCommandMock -CommandName 'dnspyex' -ExitCode 0

            $result = Decompile-DotNet -InputFile $script:TestDllFile -OutputPath $script:TestWorkDir -OutputFormat 'il' -ErrorAction SilentlyContinue

            $result | Should -Match '\.il$'
        }

        It 'Handles missing input file' {
            Setup-CapturingCommandMock -CommandName 'dnspyex'
            $missingFile = Join-Path $script:TestWorkDir 'missing.dll'

            $result = Decompile-DotNet -InputFile $missingFile -ErrorAction SilentlyContinue

            $result | Should -BeNullOrEmpty
        }
    }
}
