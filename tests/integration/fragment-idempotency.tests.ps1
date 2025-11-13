. (Join-Path $PSScriptRoot '..\TestSupport.ps1')

Describe 'Fragment Idempotency Edge Cases' {
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

    Context 'Fragment Idempotency Edge Cases' {
        It 'handles fragment that modifies global state multiple times' {
            $fragmentName = '99-test-state-mod.ps1'
            $content = @'
if (-not $global:FragmentLoadCount) {
    $global:FragmentLoadCount = 0
}
$global:FragmentLoadCount++
'@

            New-TestFragment -Name $fragmentName -Content $content

            # Clear state
            $global:FragmentLoadCount = 0

            # Load profile multiple times
            . $script:InvokeProfileSilently
            $firstLoad = $global:FragmentLoadCount

            . $script:InvokeProfileSilently
            $secondLoad = $global:FragmentLoadCount

            # Fragment should be idempotent (or at least handle multiple loads)
            # Exact behavior depends on fragment design, but shouldn't crash
            $secondLoad | Should -BeGreaterThan $firstLoad

            # Cleanup
            Remove-TestFragment -Name $fragmentName
            $global:FragmentLoadCount = $null
        }

        It 'handles fragment that defines functions multiple times' {
            $fragmentName = '99-test-function-def.ps1'
            $content = @'
function Test-IdempotentFunction {
    Write-Output 'loaded'
}
'@

            New-TestFragment -Name $fragmentName -Content $content

            # Load profile multiple times
            . $script:InvokeProfileSilently
            $firstExists = Get-Command Test-IdempotentFunction -ErrorAction SilentlyContinue

            . $script:InvokeProfileSilently
            $secondExists = Get-Command Test-IdempotentFunction -ErrorAction SilentlyContinue

            # Function should exist after both loads (idempotent)
            $firstExists | Should -Not -BeNullOrEmpty
            $secondExists | Should -Not -BeNullOrEmpty

            # Cleanup
            Remove-TestFragment -Name $fragmentName
            Remove-Item Function:\Test-IdempotentFunction -ErrorAction SilentlyContinue
        }
    }
}
