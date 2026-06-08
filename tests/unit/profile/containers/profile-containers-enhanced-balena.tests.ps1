# ===============================================
# profile-containers-enhanced-balena.tests.ps1
# Unit tests for Deploy-Balena function
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
    . (Join-Path $script:ProfileDir 'containers-enhanced.ps1')
}

Describe 'containers-enhanced.ps1 - Deploy-Balena' {
    BeforeEach {
        Clear-TestCommandInvocationCapture

        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }

        Set-TestCommandAvailabilityState -CommandName 'balena' -Available $false
        Remove-Item -Path 'Function:\balena' -Force -ErrorAction SilentlyContinue
        Remove-Item -Path 'Function:\global:balena' -Force -ErrorAction SilentlyContinue
    }

    Context 'Tool not available' {
        It 'Returns null when balena is not available' {
            $result = Deploy-Balena -Application 'my-app' -ErrorAction SilentlyContinue

            $result | Should -BeNullOrEmpty
        }
    }

    Context 'Tool available' {
        It 'Calls balena push for push action' {
            Setup-CapturingCommandMock -CommandName 'balena' -Output 'Pushed'

            $result = Deploy-Balena -Application 'my-app' -Action 'push' -ErrorAction SilentlyContinue

            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain 'push'
            $args | Should -Contain 'my-app'
            $result | Should -Not -BeNullOrEmpty
        }

        It 'Calls balena logs for logs action' {
            Setup-CapturingCommandMock -CommandName 'balena' -Output 'Log output'

            $result = Deploy-Balena -Application 'my-app' -Action 'logs' -Device 'device-uuid' -ErrorAction SilentlyContinue

            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain 'logs'
            $args | Should -Contain 'my-app'
            $args | Should -Contain '--device'
            $args | Should -Contain 'device-uuid'
        }

        It 'Calls balena ssh for ssh action' {
            Setup-CapturingCommandMock -CommandName 'balena' -Output 'SSH connected'

            $result = Deploy-Balena -Action 'ssh' -Device 'device-uuid' -ErrorAction SilentlyContinue

            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain 'ssh'
            $args | Should -Contain 'device-uuid'
        }

        It 'Returns error when Device is missing for ssh action' {
            Set-TestCommandAvailabilityState -CommandName 'balena'

            $result = Deploy-Balena -Action 'ssh' -ErrorAction SilentlyContinue

            $result | Should -BeNullOrEmpty
            Get-TestCommandInvocationArgs | Should -BeNullOrEmpty
        }

        It 'Calls balena status for status action' {
            Setup-CapturingCommandMock -CommandName 'balena' -Output 'Status output'

            $result = Deploy-Balena -Application 'my-app' -Action 'status' -ErrorAction SilentlyContinue

            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain 'status'
            $args | Should -Contain '--application'
            $args | Should -Contain 'my-app'
        }

        It 'Handles balena execution errors' {
            Setup-CapturingCommandMock -CommandName 'balena' -Output '' -ExitCode 1

            $result = Deploy-Balena -Application 'my-app' -ErrorAction SilentlyContinue

            $result | Should -BeNullOrEmpty
        }
    }
}
