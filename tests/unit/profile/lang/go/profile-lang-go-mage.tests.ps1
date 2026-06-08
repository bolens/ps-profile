# ===============================================
# profile-lang-go-mage.tests.ps1
# Unit tests for Invoke-Mage function
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
    . (Join-Path $script:ProfileDir 'lang-go.ps1')
}

Describe 'lang-go.ps1 - Invoke-Mage' {
    BeforeEach {
        Clear-TestCommandInvocationCapture

        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }

        Set-TestCommandAvailabilityState -CommandName 'mage' -Available $false
        Remove-Item -Path 'Function:\mage' -Force -ErrorAction SilentlyContinue
        Remove-Item -Path 'Function:\global:mage' -Force -ErrorAction SilentlyContinue
    }

    Context 'Tool not available' {
        It 'Returns null when mage is not available' {
            $result = Invoke-Mage -ErrorAction SilentlyContinue

            $result | Should -BeNullOrEmpty
        }
    }

    Context 'Tool available' {
        It 'Calls mage without target (lists targets)' {
            Setup-CapturingCommandMock -CommandName 'mage' -Output 'Available targets: build, test'

            $result = Invoke-Mage -ErrorAction SilentlyContinue

            $global:TestCommandInvocationCaptures.Count | Should -Be 1
            @((Get-TestCommandInvocationArgsFlat | Where-Object { $null -ne $_ -and $_ -ne '' })).Count | Should -Be 0
            $result | Should -Be 'Available targets: build, test'
        }

        It 'Calls mage with target' {
            Setup-CapturingCommandMock -CommandName 'mage' -Output 'Build complete'

            Invoke-Mage -Target 'build' -ErrorAction SilentlyContinue | Out-Null

            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain 'build'
        }

        It 'Calls mage with target and additional arguments' {
            Setup-CapturingCommandMock -CommandName 'mage' -Output 'Test complete'

            Invoke-Mage -Target 'test' '-v' -ErrorAction SilentlyContinue | Out-Null

            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain 'test'
            $args | Should -Contain '-v'
        }
    }

    Context 'Error handling' {
        It 'Handles mage execution errors' {
            Set-TestCommandThrowingMock -CommandName 'mage' -Message 'mage: command failed'

            try {
                $result = Invoke-Mage -Target 'invalid' -ErrorAction SilentlyContinue
            }
            catch {
                $result = $null
            }

            $result | Should -BeNullOrEmpty
        }
    }
}
