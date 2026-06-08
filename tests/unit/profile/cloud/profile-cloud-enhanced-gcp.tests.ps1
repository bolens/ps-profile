# ===============================================
# profile-cloud-enhanced-gcp.tests.ps1
# Unit tests for Set-GcpProject function
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
    . (Join-Path $script:ProfileDir 'cloud-enhanced.ps1')
}

Describe 'cloud-enhanced.ps1 - Set-GcpProject' {
    BeforeEach {
        Clear-TestCommandInvocationCapture

        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }

        Set-TestCommandAvailabilityState -CommandName 'gcloud' -Available $false
        Remove-Item -Path 'Function:\gcloud' -Force -ErrorAction SilentlyContinue
        Remove-Item -Path 'Function:\global:gcloud' -Force -ErrorAction SilentlyContinue
    }

    Context 'Tool not available' {
        It 'Returns null when gcloud is not available' {
            $result = Set-GcpProject -List -ErrorAction SilentlyContinue

            $result | Should -BeNullOrEmpty
        }
    }

    Context 'Tool available' {
        It 'Lists projects when List is specified' {
            Setup-CapturingCommandMock -CommandName 'gcloud' -Output 'Project list'

            $result = Set-GcpProject -List -ErrorAction SilentlyContinue

            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain 'projects'
            $args | Should -Contain 'list'
            $result | Should -Not -BeNullOrEmpty
        }

        It 'Switches project when ProjectId is specified' {
            Setup-CapturingCommandMock -CommandName 'gcloud' -Output ''

            Set-GcpProject -ProjectId 'my-project' -ErrorAction SilentlyContinue | Out-Null

            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain 'config'
            $args | Should -Contain 'set'
            $args | Should -Contain 'project'
            $args | Should -Contain 'my-project'
        }

        It 'Shows current project when no parameters' {
            Setup-CapturingCommandMock -CommandName 'gcloud' -Output 'my-project'

            $result = Set-GcpProject -ErrorAction SilentlyContinue

            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain 'config'
            $args | Should -Contain 'get-value'
            $args | Should -Contain 'project'
            $result | Should -Not -BeNullOrEmpty
        }

        It 'Handles gcloud execution errors' {
            Setup-CapturingCommandMock -CommandName 'gcloud' -Output '' -ExitCode 1

            { Set-GcpProject -List -ErrorAction Stop } | Should -Throw
        }
    }
}
