# ===============================================
# profile-git-enhanced-workflow.tests.ps1
# Unit tests for Invoke-GitButler and Invoke-Jujutsu functions
# ===============================================

BeforeAll {
    . (Join-Path $PSScriptRoot '..\TestSupport.ps1')
    $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
    . (Join-Path $script:ProfileDir 'bootstrap.ps1')
    . (Join-Path $script:ProfileDir 'git-enhanced.ps1')
}

Describe 'git-enhanced.ps1 - Invoke-GitButler' {
    BeforeEach {
        Clear-TestCommandInvocationCapture

        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }

        Set-TestCommandAvailabilityState -CommandName 'gitbutler' -Available $false
        Remove-Item -Path 'Function:\gitbutler' -Force -ErrorAction SilentlyContinue
        Remove-Item -Path 'Function:\global:gitbutler' -Force -ErrorAction SilentlyContinue
    }

    Context 'Tool not available' {
        It 'Returns null when gitbutler is not available' {
            $result = Invoke-GitButler -ErrorAction SilentlyContinue

            $result | Should -BeNullOrEmpty
        }
    }

    Context 'Tool available' {
        It 'Calls gitbutler without arguments' {
            Setup-CapturingCommandMock -CommandName 'gitbutler' -Output 'Git Butler output'

            $result = Invoke-GitButler -ErrorAction SilentlyContinue

            $global:TestCommandInvocationCaptures.Count | Should -Be 1
            $global:TestCommandInvocationCaptures.Count | Should -Be 1
            @((Get-TestCommandInvocationArgsFlat | Where-Object { $null -ne $_ -and $_ -ne '' })).Count | Should -Be 0
            $result | Should -Be 'Git Butler output'
        }

        It 'Calls gitbutler with arguments' {
            Setup-CapturingCommandMock -CommandName 'gitbutler' -Output 'Git Butler output'

            Invoke-GitButler 'status', 'sync' -ErrorAction SilentlyContinue | Out-Null

            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain 'status'
            $args | Should -Contain 'sync'
        }

        It 'Handles gitbutler execution errors' {
            Set-TestCommandThrowingMock -CommandName 'gitbutler' -Message 'gitbutler: command failed'

            { Invoke-GitButler 'invalid' -ErrorAction Stop } | Should -Throw '*gitbutler*'
        }
    }
}

Describe 'git-enhanced.ps1 - Invoke-Jujutsu' {
    BeforeEach {
        Clear-TestCommandInvocationCapture

        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }

        Set-TestCommandAvailabilityState -CommandName 'jj' -Available $false
        Remove-Item -Path 'Function:\jj' -Force -ErrorAction SilentlyContinue
        Remove-Item -Path 'Function:\global:jj' -Force -ErrorAction SilentlyContinue
    }

    Context 'Tool not available' {
        It 'Returns null when jj is not available' {
            $result = Invoke-Jujutsu -ErrorAction SilentlyContinue

            $result | Should -BeNullOrEmpty
        }
    }

    Context 'Tool available' {
        It 'Calls jj without arguments' {
            Setup-CapturingCommandMock -CommandName 'jj' -Output 'Jujutsu output'

            $result = Invoke-Jujutsu -ErrorAction SilentlyContinue

            $global:TestCommandInvocationCaptures.Count | Should -Be 1
            $global:TestCommandInvocationCaptures.Count | Should -Be 1
            @((Get-TestCommandInvocationArgsFlat | Where-Object { $null -ne $_ -and $_ -ne '' })).Count | Should -Be 0
            $result | Should -Be 'Jujutsu output'
        }

        It 'Calls jj with arguments' {
            Setup-CapturingCommandMock -CommandName 'jj' -Output 'Jujutsu output'

            Invoke-Jujutsu 'init', 'status' -ErrorAction SilentlyContinue | Out-Null

            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain 'init'
            $args | Should -Contain 'status'
        }

        It 'Handles jj execution errors' {
            Set-TestCommandThrowingMock -CommandName 'jj' -Message 'jj: command failed'

            { Invoke-Jujutsu 'invalid' -ErrorAction Stop } | Should -Throw '*jj*'
        }
    }
}
