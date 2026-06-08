# ===============================================
# profile-ai-tools-lmstudio.tests.ps1
# Unit tests for Invoke-LMStudio function
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
    . (Join-Path $script:ProfileDir 'ai-tools.ps1')
}

Describe 'ai-tools.ps1 - Invoke-LMStudio' {
    BeforeEach {
        Clear-TestCommandInvocationCapture

        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }

        Set-TestCommandAvailabilityState -CommandName 'lms' -Available $false
        Remove-Item -Path Function:\lms -Force -ErrorAction SilentlyContinue
        Remove-Item -Path Function:\global:lms -Force -ErrorAction SilentlyContinue
        Remove-Item -Path Alias:\lms -Force -ErrorAction SilentlyContinue
        Remove-Item -Path Alias:\global:lms -Force -ErrorAction SilentlyContinue
    }

    Context 'Tool not available' {
        It 'Returns null when lms is not available' {
            Set-TestCommandAvailabilityState -CommandName 'lms' -Available $false

            $originalHome = $env:HOME
            $emptyHome = New-TestTempDirectory -Prefix 'LmStudioUnavailable'
            try {
                $env:HOME = $emptyHome
                $result = Invoke-LMStudio -Arguments @('list') -ErrorAction SilentlyContinue
                $result | Should -BeNullOrEmpty
            }
            finally {
                if ($null -ne $originalHome) {
                    $env:HOME = $originalHome
                }
                else {
                    Remove-Item Env:HOME -ErrorAction SilentlyContinue
                }
            }
        }
    }

    Context 'Tool available via command' {
        It 'Calls lms with correct arguments' {
            Setup-CapturingCommandMock -CommandName 'lms' -Output 'Models list'

            $result = Invoke-LMStudio -Arguments @('list')

            $result | Should -Not -BeNullOrEmpty
            $args = Get-TestCommandInvocationArgs
            $args | Should -Contain 'list'
        }
    }

    Context 'Error handling' {
        It 'Handles lms execution errors' {
            Set-TestCommandThrowingMock -CommandName 'lms' -Message 'lms: command failed'

            { Invoke-LMStudio -Arguments @('invalid-command') } | Should -Throw '*lms*'
        }
    }
}
