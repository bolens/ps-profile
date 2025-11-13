. (Join-Path $PSScriptRoot '..\TestSupport.ps1')

Describe 'Fragment Error Recovery' {
    BeforeAll {
        $script:RepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
        $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
        $script:ProfilePath = Get-TestPath -RelativePath 'Microsoft.PowerShell_profile.ps1' -StartPath $PSScriptRoot -EnsureExists

        # Silence expected fragment warnings so test output focuses on pass/fail status.
        $script:OriginalFragmentWarningSetting = $env:PS_PROFILE_SUPPRESS_FRAGMENT_WARNINGS
        $env:PS_PROFILE_SUPPRESS_FRAGMENT_WARNINGS = '1'

        if (Get-Command -Name 'Initialize-FragmentWarningSuppression' -ErrorAction SilentlyContinue) {
            Initialize-FragmentWarningSuppression
        }

        $script:InvokeProfileSilently = {
            # Temporarily silence warnings so intentionally failing fragments don't pollute test output.
            $originalWarningPreference = $WarningPreference
            try {
                $WarningPreference = 'SilentlyContinue'
                . $script:ProfilePath
            }
            finally {
                $WarningPreference = $originalWarningPreference
            }
        }

        # Helper to create a temporary fragment with specific content
        function script:New-TestFragment {
            param(
                [string]$Name,
                [string]$Content
            )

            $fragmentPath = Join-Path $script:ProfileDir $Name
            Set-Content -Path $fragmentPath -Value $Content -Encoding UTF8
            return $fragmentPath
        }

        # Helper to remove test fragment
        function script:Remove-TestFragment {
            param([string]$Name)
            $fragmentPath = Join-Path $script:ProfileDir $Name
            Remove-Item -Path $fragmentPath -Force -ErrorAction SilentlyContinue
        }
    }

    AfterEach {
        # Clean up any test fragments
        Get-ChildItem -Path $script:ProfileDir -Filter '99-test-*.ps1' -ErrorAction SilentlyContinue | Remove-Item -Force
    }

    AfterAll {
        if ($null -ne $script:OriginalFragmentWarningSetting) {
            $env:PS_PROFILE_SUPPRESS_FRAGMENT_WARNINGS = $script:OriginalFragmentWarningSetting
        }
        else {
            $env:PS_PROFILE_SUPPRESS_FRAGMENT_WARNINGS = $null
        }

        if (Get-Command -Name 'Initialize-FragmentWarningSuppression' -ErrorAction SilentlyContinue) {
            Initialize-FragmentWarningSuppression
        }

        Remove-Variable -Name 'InvokeProfileSilently' -Scope Script -ErrorAction SilentlyContinue
    }

    Context 'Error Recovery' {
        It 'recovers from fragment loading error and allows subsequent loads' {
            $fragmentName = '99-test-recovery.ps1'
            $badContent = @'
throw "Recovery test error"
'@

            New-TestFragment -Name $fragmentName -Content $badContent

            # First load with error
            { . $script:InvokeProfileSilently } | Should -Not -Throw

            # Second load should also work (recovery)
            { . $script:InvokeProfileSilently } | Should -Not -Throw

            # Cleanup
            Remove-TestFragment -Name $fragmentName
        }

        It 'handles missing profile.d directory' {
            # This test verifies the profile handles missing directory
            # Note: Actual behavior depends on profile implementation
            $profileContent = Get-Content $script:ProfilePath -Raw

            # Profile should check for directory existence
            $profileContent | Should -Match 'Test-Path.*profile\.d'
        }

        It 'handles corrupted fragment configuration file' {
            $configPath = Join-Path (Split-Path $script:ProfilePath -Parent) '.profile-fragments.json'
            $originalContent = $null

            if (Test-Path $configPath) {
                $originalContent = Get-Content $configPath -Raw
            }

            try {
                # Create invalid JSON
                Set-Content -Path $configPath -Value '{ invalid json }' -Encoding UTF8

                # Profile should handle corrupted config gracefully
                { . $script:InvokeProfileSilently } | Should -Not -Throw
            }
            finally {
                # Restore original config
                if ($originalContent) {
                    Set-Content -Path $configPath -Value $originalContent -Encoding UTF8
                }
                else {
                    Remove-Item $configPath -Force -ErrorAction SilentlyContinue
                }
            }
        }
    }
}
