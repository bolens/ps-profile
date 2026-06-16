

Describe 'Fragment Missing Dependencies' {
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
            Write-Error "Failed to initialize fragment missing dependencies tests in BeforeAll: $($errorDetails | ConvertTo-Json -Compress)" -ErrorAction Stop
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

    Context 'Missing Dependencies' {
        It 'handles fragment referencing non-existent command' {
            $fragmentName = '99-test-missing-cmd.ps1'
            $cleanupNeeded = $false

            try {
                $content = @'
# Try to use a command that doesn't exist
$result = Get-NonExistentCommand -ErrorAction SilentlyContinue
'@

                New-TestFragment -Name $fragmentName -Content $content
                $cleanupNeeded = $true

                # Profile should handle missing command gracefully
                { . $script:InvokeProfileSilently } | Should -Not -Throw -Because "profile should handle missing commands gracefully"
            }
            catch {
                $errorDetails = @{
                    Message      = $_.Exception.Message
                    FragmentName = $fragmentName
                    Category     = $_.CategoryInfo.Category
                }
                Write-Error "Fragment missing command test failed: $($errorDetails | ConvertTo-Json -Compress)" -ErrorAction Continue
                throw
            }
            finally {
                if ($cleanupNeeded) {
                    Remove-TestFragment -Name $fragmentName
                }
            }
        }

        It 'handles fragment referencing non-existent module' {
            $fragmentName = '99-test-missing-module.ps1'
            $cleanupNeeded = $false

            try {
                $content = @'
Import-Module NonExistentModule -ErrorAction SilentlyContinue
'@

                New-TestFragment -Name $fragmentName -Content $content
                $cleanupNeeded = $true

                # Profile should handle missing module gracefully
                { . $script:InvokeProfileSilently } | Should -Not -Throw -Because "profile should handle missing modules gracefully"
            }
            catch {
                $errorDetails = @{
                    Message      = $_.Exception.Message
                    FragmentName = $fragmentName
                    Category     = $_.CategoryInfo.Category
                }
                Write-Error "Fragment missing module test failed: $($errorDetails | ConvertTo-Json -Compress)" -ErrorAction Continue
                throw
            }
            finally {
                if ($cleanupNeeded) {
                    Remove-TestFragment -Name $fragmentName
                }
            }
        }
    }
}

