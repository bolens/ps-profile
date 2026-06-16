

Describe 'Fragment Loading Failure Scenarios' {
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
            Write-Error "Failed to initialize fragment loading failure tests in BeforeAll: $($errorDetails | ConvertTo-Json -Compress)" -ErrorAction Stop
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

    Context 'Fragment Loading Failures' {
        It 'handles fragment with syntax error gracefully' {
            $fragmentName = '99-test-syntax-error.ps1'
            $badContent = @'
function Test-BadFunction {
    # Missing closing brace
    Write-Output 'test'
'@

            New-TestFragment -Name $fragmentName -Content $badContent

            # Profile should still load despite syntax error in one fragment
            { . $script:InvokeProfileSilently } | Should -Not -Throw

            # Cleanup
            Remove-TestFragment -Name $fragmentName
        }

        It 'handles fragment that throws exception' {
            $fragmentName = '99-test-exception.ps1'
            $badContent = @'
throw "Test exception from fragment"
'@

            New-TestFragment -Name $fragmentName -Content $badContent

            # Profile should handle exception and continue loading
            { . $script:InvokeProfileSilently } | Should -Not -Throw

            # Cleanup
            Remove-TestFragment -Name $fragmentName
        }

        It 'handles fragment with missing dependency gracefully' {
            $fragmentName = '99-test-missing-dep.ps1'
            $badContent = @'
# Try to use a function that doesn't exist
$result = NonExistent-Function -Parameter 'test'
'@

            New-TestFragment -Name $fragmentName -Content $badContent

            # Profile should handle missing dependency error
            { . $script:InvokeProfileSilently } | Should -Not -Throw

            # Cleanup
            Remove-TestFragment -Name $fragmentName
        }

        It 'continues loading other fragments after failure' {
            $fragmentName1 = '99-test-fail1.ps1'
            $fragmentName2 = '99-test-success.ps1'

            $failContent = @'
throw "Fragment 1 fails"
'@
            $successContent = @'
$global:TestFragmentLoaded = $true
'@

            New-TestFragment -Name $fragmentName1 -Content $failContent
            New-TestFragment -Name $fragmentName2 -Content $successContent

            # Clear the test variable
            $global:TestFragmentLoaded = $false

            # Profile should continue loading despite first fragment failure
            { . $script:InvokeProfileSilently } | Should -Not -Throw

            # Second fragment should have loaded
            $global:TestFragmentLoaded | Should -Be $true

            # Cleanup
            Remove-TestFragment -Name $fragmentName1
            Remove-TestFragment -Name $fragmentName2
            $global:TestFragmentLoaded = $false
        }
    }
}

