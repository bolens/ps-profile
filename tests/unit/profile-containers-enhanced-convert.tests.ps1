# ===============================================
# profile-containers-enhanced-convert.tests.ps1
# Unit tests for Convert-ComposeToK8s function
# ===============================================

BeforeAll {
    . (Join-Path $PSScriptRoot '..\TestSupport.ps1')
    $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
    . (Join-Path $script:ProfileDir 'bootstrap.ps1')
    . (Join-Path $script:ProfileDir 'containers-enhanced.ps1')

    $script:TestComposeDir = New-TestTempDirectory -Prefix 'KomposeCompose'
    $script:TestComposeFile = Join-Path $script:TestComposeDir 'docker-compose.yml'
    Set-Content -Path $script:TestComposeFile -Value 'version: "3"'
    $script:TestOutputDir = New-TestTempDirectory -Prefix 'KomposeOutput'
}

Describe 'containers-enhanced.ps1 - Convert-ComposeToK8s' {
    BeforeEach {
        Clear-TestCommandInvocationCapture

        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }

        Set-TestCommandAvailabilityState -CommandName 'kompose' -Available $false
        Remove-Item -Path 'Function:\kompose' -Force -ErrorAction SilentlyContinue
        Remove-Item -Path 'Function:\global:kompose' -Force -ErrorAction SilentlyContinue
    }

    Context 'Tool not available' {
        It 'Returns null when kompose is not available' {
            $result = Convert-ComposeToK8s -ComposeFile $script:TestComposeFile -ErrorAction SilentlyContinue

            $result | Should -BeNullOrEmpty
        }
    }

    Context 'Compose file validation' {
        It 'Returns error when compose file does not exist' {
            Setup-AvailableCommandMock -CommandName 'kompose'
            $missingFile = Join-Path (New-TestTempDirectory -Prefix 'KomposeMissing') 'nonexistent.yml'

            { Convert-ComposeToK8s -ComposeFile $missingFile -ErrorAction Stop } | Should -Throw
        }
    }

    Context 'Tool available' {
        It 'Calls kompose with correct arguments' {
            Setup-CapturingCommandMock -CommandName 'kompose' -Output ''

            $result = Convert-ComposeToK8s -ComposeFile $script:TestComposeFile -OutputPath $script:TestOutputDir -Confirm:$false -ErrorAction SilentlyContinue

            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain 'convert'
            $args | Should -Contain '-f'
            $args | Should -Contain $script:TestComposeFile
            $args | Should -Contain '-o'
            $args | Should -Contain $script:TestOutputDir
            $result | Should -Be $script:TestOutputDir
        }

        It 'Calls kompose with JSON format' {
            Setup-CapturingCommandMock -CommandName 'kompose' -Output ''

            Convert-ComposeToK8s -ComposeFile $script:TestComposeFile -OutputPath $script:TestOutputDir -Format 'json' -Confirm:$false -ErrorAction SilentlyContinue | Out-Null

            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain '--json'
        }

        It 'Returns output path on success' {
            Setup-CapturingCommandMock -CommandName 'kompose' -Output ''

            $result = Convert-ComposeToK8s -ComposeFile $script:TestComposeFile -OutputPath $script:TestOutputDir -Confirm:$false -ErrorAction SilentlyContinue

            $result | Should -Be $script:TestOutputDir
        }

        It 'Handles kompose execution errors' {
            Setup-CapturingCommandMock -CommandName 'kompose' -Output '' -ExitCode 1

            $result = Convert-ComposeToK8s -ComposeFile $script:TestComposeFile -OutputPath $script:TestOutputDir -Confirm:$false -ErrorAction SilentlyContinue

            $result | Should -BeNullOrEmpty
        }
    }
}
