# ===============================================
# profile-database-clients-supabase.tests.ps1
# Unit tests for Invoke-Supabase function
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
    . (Join-Path $script:ProfileDir 'database-clients.ps1')
}

Describe 'database-clients.ps1 - Invoke-Supabase' {
    BeforeEach {
        Clear-TestCommandInvocationCapture

        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }

        Set-TestCommandAvailabilityState -CommandName 'supabase-beta' -Available $false
        Set-TestCommandAvailabilityState -CommandName 'supabase' -Available $false
        Remove-Item -Path Function:\supabase-beta -Force -ErrorAction SilentlyContinue
        Remove-Item -Path Function:\global:supabase-beta -Force -ErrorAction SilentlyContinue
        Remove-Item -Path Function:\supabase -Force -ErrorAction SilentlyContinue
        Remove-Item -Path Function:\global:supabase -Force -ErrorAction SilentlyContinue
        Remove-Item -Path Alias:\supabase -Force -ErrorAction SilentlyContinue
        Remove-Item -Path Alias:\global:supabase -Force -ErrorAction SilentlyContinue
    }

    Context 'Tool not available' {
        It 'Returns null when supabase is not available' {
            Set-TestCommandAvailabilityState -CommandName 'supabase-beta' -Available $false
            Set-TestCommandAvailabilityState -CommandName 'supabase' -Available $false

            $result = Invoke-Supabase status -ErrorAction SilentlyContinue

            $result | Should -BeNullOrEmpty
        }
    }

    Context 'Tool available' {
        It 'Uses supabase-beta when available' {
            Set-TestCommandAvailabilityState -CommandName 'supabase' -Available $false
            Setup-CapturingCommandMock -CommandName 'supabase-beta' -Output 'Supabase status: running'

            $result = Invoke-Supabase status

            $result | Should -Not -BeNullOrEmpty
            $args = Get-TestCommandInvocationArgs
            $args | Should -Contain 'status'
        }

        It 'Falls back to supabase when supabase-beta is not available' {
            Set-TestCommandAvailabilityState -CommandName 'supabase-beta' -Available $false
            Setup-CapturingCommandMock -CommandName 'supabase' -Output 'Supabase status: running'

            $result = Invoke-Supabase status

            $result | Should -Not -BeNullOrEmpty
            $args = Get-TestCommandInvocationArgs
            $args | Should -Contain 'status'
        }

        It 'Calls supabase with correct arguments' {
            Set-TestCommandAvailabilityState -CommandName 'supabase' -Available $false
            Setup-CapturingCommandMock -CommandName 'supabase-beta' -Output 'Local Supabase started'

            $result = Invoke-Supabase start

            $result | Should -Not -BeNullOrEmpty
            $args = Get-TestCommandInvocationArgs
            $args | Should -Contain 'start'
        }

        It 'Handles multiple arguments' {
            Set-TestCommandAvailabilityState -CommandName 'supabase' -Available $false
            Setup-CapturingCommandMock -CommandName 'supabase-beta' -Output 'Migration applied'

            $result = Invoke-Supabase db reset

            $result | Should -Not -BeNullOrEmpty
            $args = Get-TestCommandInvocationArgs
            $args | Should -Contain 'db'
            $args | Should -Contain 'reset'
        }

        It 'Handles command execution errors' {
            Set-TestCommandAvailabilityState -CommandName 'supabase' -Available $false
            Set-TestCommandThrowingMock -CommandName 'supabase-beta' -Message 'supabase-beta failed'

            { Invoke-Supabase status } | Should -Throw '*supabase-beta*'
        }
    }
}
