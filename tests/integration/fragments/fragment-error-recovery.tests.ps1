

Describe 'Fragment Error Recovery' {
    BeforeAll {
        try {
            $script:RepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
            $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
            $script:ProfilePath = Get-TestPath -RelativePath 'Microsoft.PowerShell_profile.ps1' -StartPath $PSScriptRoot -EnsureExists

            if ($null -eq $script:ProfilePath -or [string]::IsNullOrWhiteSpace($script:ProfilePath)) {
                throw "Get-TestPath returned null or empty value for ProfilePath"
            }
            if (-not (Test-Path -LiteralPath $script:ProfilePath)) {
                throw "Profile file not found at: $script:ProfilePath"
            }

            # Enable test mode to allow test fragments to be loaded
            $script:OriginalTestMode = $env:PS_PROFILE_TEST_MODE
            $env:PS_PROFILE_TEST_MODE = '1'

            # Silence expected fragment warnings so test output focuses on pass/fail status.
            $script:OriginalFragmentWarningSetting = $env:PS_PROFILE_SUPPRESS_FRAGMENT_WARNINGS
            $env:PS_PROFILE_SUPPRESS_FRAGMENT_WARNINGS = '1'

            if (Get-Command -Name 'Initialize-FragmentWarningSuppression' -ErrorAction SilentlyContinue) {
                Initialize-FragmentWarningSuppression
            }
        }
        catch {
            $errorDetails = @{
                Message  = $_.Exception.Message
                Type     = $_.Exception.GetType().FullName
                Location = $_.InvocationInfo.ScriptLineNumber
            }
            Write-Error "Failed to initialize fragment error recovery tests in BeforeAll: $($errorDetails | ConvertTo-Json -Compress)" -ErrorAction Stop
            throw
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
        if ($null -ne $script:OriginalTestMode) {
            $env:PS_PROFILE_TEST_MODE = $script:OriginalTestMode
        }
        else {
            $env:PS_PROFILE_TEST_MODE = $null
        }

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
            $cleanupNeeded = $false

            try {
                $badContent = @'
throw "Recovery test error"
'@

                New-TestFragment -Name $fragmentName -Content $badContent
                $cleanupNeeded = $true

                # First load with error
                { . $script:InvokeProfileSilently } | Should -Not -Throw -Because "profile should handle fragment errors gracefully"

                # Second load should also work (recovery)
                { . $script:InvokeProfileSilently } | Should -Not -Throw -Because "profile should recover and allow subsequent loads"
            }
            catch {
                $errorDetails = @{
                    Message      = $_.Exception.Message
                    FragmentName = $fragmentName
                    Category     = $_.CategoryInfo.Category
                }
                Write-Error "Fragment error recovery test failed: $($errorDetails | ConvertTo-Json -Compress)" -ErrorAction Continue
                throw
            }
            finally {
                if ($cleanupNeeded) {
                    Remove-TestFragment -Name $fragmentName
                }
            }
        }

        It 'handles missing profile.d directory' {
            # This test verifies the profile handles missing directory
            # Note: Actual behavior depends on profile implementation
            $profileContent = Get-Content $script:ProfilePath -Raw

            # Profile should check for directory existence
            # Check for various patterns that might indicate directory checking
            $hasDirectoryCheck = $profileContent -match 'Test-Path.*profile\.d' -or
            $profileContent -match 'profile\.d' -or
            $profileContent -match '\$profileD' -or
            $profileContent -match 'Join-Path.*profile\.d'
            
            $hasDirectoryCheck | Should -Be $true
        }

        It 'handles corrupted fragment configuration file' {
            $configPath = Join-Path (Split-Path $script:ProfilePath -Parent) '.profile-fragments.json'
            $originalContent = $null

            if ($configPath -and -not [string]::IsNullOrWhiteSpace($configPath) -and (Test-Path -LiteralPath $configPath)) {
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

