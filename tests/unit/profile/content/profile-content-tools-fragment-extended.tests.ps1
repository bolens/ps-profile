# ===============================================
# profile-content-tools-fragment-extended.tests.ps1
# Execution tests for content-tools.ps1 fragment behavior
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
    $fragmentIdempotencyPath = Get-TestPath -RelativePath 'scripts/lib/fragment/FragmentIdempotency.psm1' -StartPath $PSScriptRoot -EnsureExists
    Import-Module $fragmentIdempotencyPath -DisableNameChecking -ErrorAction Stop -Force
    . (Join-Path $script:ProfileDir 'bootstrap.ps1')
}

function script:Reset-ContentToolsFragmentState {
    Clear-FragmentLoaded -FragmentName 'content-tools' -ErrorAction SilentlyContinue
}

Describe 'profile.d/content-tools.ps1 extended scenarios' {
    BeforeEach {
        Reset-ContentToolsFragmentState
    }

    It 'Registers content download helpers and marks the fragment loaded' {
        . (Join-Path $script:ProfileDir 'content-tools.ps1')

        Get-Command Download-Video -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Download-Gallery -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Test-FragmentLoaded -FragmentName 'content-tools' | Should -Be $true
    }

    It 'Download-Video warns when yt-dlp is unavailable' {
        . (Join-Path $script:ProfileDir 'content-tools.ps1')

        Mark-TestCommandsUnavailable -CommandNames @('yt-dlp')
        Set-TestCommandAvailabilityState -CommandName 'yt-dlp' -Available $false
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }
        if ($global:MissingToolWarnings) {
            $null = $global:MissingToolWarnings.TryRemove('yt-dlp', [ref]$null)
        }

        $output = Download-Video -Url 'https://example.com/video' 2>&1 3>&1 | Out-String
        Assert-TestMissingToolWarning -Output $output -Pattern 'yt-dlp not found'
    }

    It 'Skips re-initialization when content-tools is already loaded' {
        . (Join-Path $script:ProfileDir 'content-tools.ps1')
        $firstDownload = Get-Command Download-Video -ErrorAction Stop

        . (Join-Path $script:ProfileDir 'content-tools.ps1')

        (Get-Command Download-Video -ErrorAction Stop).ScriptBlock.ToString() |
            Should -Be $firstDownload.ScriptBlock.ToString()
    }
}
