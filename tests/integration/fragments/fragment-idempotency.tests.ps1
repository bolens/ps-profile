

Describe 'Fragment Idempotency Edge Cases' {
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
            Write-Error "Failed to initialize fragment idempotency tests in BeforeAll: $($errorDetails | ConvertTo-Json -Compress)" -ErrorAction Stop
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

            if ($null -eq $script:ProfileDir -or [string]::IsNullOrWhiteSpace($script:ProfileDir)) {
                throw "ProfileDir is null or empty in New-TestFragment"
            }
            $fragmentPath = Join-Path $script:ProfileDir $Name
            if ($null -eq $fragmentPath -or [string]::IsNullOrWhiteSpace($fragmentPath)) {
                throw "fragmentPath is null or empty in New-TestFragment"
            }
            Set-Content -Path $fragmentPath -Value $Content -Encoding UTF8
            return $fragmentPath
        }

        # Helper to remove test fragment
        function script:Remove-TestFragment {
            param([string]$Name)
            if ($null -eq $script:ProfileDir -or [string]::IsNullOrWhiteSpace($script:ProfileDir)) {
                return
            }
            $fragmentPath = Join-Path $script:ProfileDir $Name
            if ($fragmentPath -and -not [string]::IsNullOrWhiteSpace($fragmentPath) -and (Test-Path -LiteralPath $fragmentPath)) {
                Remove-Item -Path $fragmentPath -Force -ErrorAction SilentlyContinue
            }
        }
    }

    AfterEach {
        # Clean up any test fragments
        if ($script:ProfileDir -and -not [string]::IsNullOrWhiteSpace($script:ProfileDir) -and (Test-Path -LiteralPath $script:ProfileDir)) {
            Get-ChildItem -Path $script:ProfileDir -Filter '99-test-*.ps1' -ErrorAction SilentlyContinue | Remove-Item -Force
        }
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

    Context 'Fragment Idempotency Edge Cases' {
        It 'handles fragment that modifies global state multiple times' {
            $fragmentName = '99-test-state-mod.ps1'
            $cleanupNeeded = $false

            try {
                $content = @'
if (-not $global:FragmentLoadCount) {
    $global:FragmentLoadCount = 0
}
$global:FragmentLoadCount++
'@

                New-TestFragment -Name $fragmentName -Content $content
                $cleanupNeeded = $true

                # Clear state
                $global:FragmentLoadCount = 0

                # Load profile multiple times
                . $script:InvokeProfileSilently
                $firstLoad = $global:FragmentLoadCount

                . $script:InvokeProfileSilently
                $secondLoad = $global:FragmentLoadCount

                # Fragment should be idempotent (or at least handle multiple loads)
                # Exact behavior depends on fragment design, but shouldn't crash
                $secondLoad | Should -BeGreaterThan $firstLoad -Because "fragment should handle multiple loads without crashing"
            }
            catch {
                $errorDetails = @{
                    Message      = $_.Exception.Message
                    FragmentName = $fragmentName
                    Category     = $_.CategoryInfo.Category
                }
                Write-Error "Fragment state modification test failed: $($errorDetails | ConvertTo-Json -Compress)" -ErrorAction Continue
                throw
            }
            finally {
                if ($cleanupNeeded) {
                    Remove-TestFragment -Name $fragmentName
                    $global:FragmentLoadCount = $null
                }
            }
        }

        It 'handles fragment that defines functions multiple times' {
            $fragmentName = '99-test-function-def.ps1'
            $cleanupNeeded = $false

            try {
                $content = @'
function Test-IdempotentFunction {
    Write-Output 'loaded'
}
'@

                New-TestFragment -Name $fragmentName -Content $content
                $cleanupNeeded = $true

                # Load profile multiple times
                . $script:InvokeProfileSilently
                $firstExists = Get-Command Test-IdempotentFunction -ErrorAction SilentlyContinue

                . $script:InvokeProfileSilently
                $secondExists = Get-Command Test-IdempotentFunction -ErrorAction SilentlyContinue

                # Function should exist after both loads (idempotent)
                $firstExists | Should -Not -BeNullOrEmpty -Because "function should exist after first load"
                $secondExists | Should -Not -BeNullOrEmpty -Because "function should exist after second load (idempotent)"
            }
            catch {
                $errorDetails = @{
                    Message      = $_.Exception.Message
                    FragmentName = $fragmentName
                    Category     = $_.CategoryInfo.Category
                }
                Write-Error "Fragment function definition test failed: $($errorDetails | ConvertTo-Json -Compress)" -ErrorAction Continue
                throw
            }
            finally {
                if ($cleanupNeeded) {
                    Remove-TestFragment -Name $fragmentName
                    Remove-Item Function:\Test-IdempotentFunction -ErrorAction SilentlyContinue
                }
            }
        }
    }
}

