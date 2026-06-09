# ===============================================
# profile-media-tools-fragment-extended.tests.ps1
# Execution tests for media-tools.ps1 fragment behavior
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

function script:Reset-MediaToolsFragmentState {
    Clear-FragmentLoaded -FragmentName 'media-tools' -ErrorAction SilentlyContinue
}

Describe 'profile.d/media-tools.ps1 extended scenarios' {
    BeforeEach {
        Reset-MediaToolsFragmentState
    }

    It 'Registers media processing helpers and marks the fragment loaded' {
        . (Join-Path $script:ProfileDir 'media-tools.ps1')

        Get-Command Convert-Video -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Get-MediaInfo -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Test-FragmentLoaded -FragmentName 'media-tools' | Should -Be $true
    }

    It 'Convert-Video warns when ffmpeg and handbrake are unavailable' {
        . (Join-Path $script:ProfileDir 'media-tools.ps1')

        Mark-TestCommandsUnavailable -CommandNames @('ffmpeg', 'handbrake', 'HandBrakeCLI')
        Set-TestCommandAvailabilityState -CommandName 'ffmpeg' -Available $false
        Set-TestCommandAvailabilityState -CommandName 'handbrake' -Available $false
        Set-TestCommandAvailabilityState -CommandName 'HandBrakeCLI' -Available $false
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }
        if ($global:MissingToolWarnings) {
            foreach ($tool in @('ffmpeg', 'handbrake', 'HandBrakeCLI')) {
                $null = $global:MissingToolWarnings.TryRemove($tool, [ref]$null)
            }
        }

        $testInput = New-TestTempFile -Prefix 'media-tools-input' -Extension '.mp4' -Content 'not-a-video'
        $testOutput = New-TestTempFile -Prefix 'media-tools-output' -Extension '.mkv'
                $output = Convert-Video -InputPath $testInput -OutputPath $testOutput 2>&1 3>&1 | Out-String
        $output | Should -Match 'ffmpeg|handbrake|not found'
    }
    finally {
        Remove-TestArtifacts
    }

    It 'Skips re-initialization when media-tools is already loaded' {
        . (Join-Path $script:ProfileDir 'media-tools.ps1')
        $firstConvert = Get-Command Convert-Video -ErrorAction Stop

        . (Join-Path $script:ProfileDir 'media-tools.ps1')

        (Get-Command Convert-Video -ErrorAction Stop).ScriptBlock.ToString() |
            Should -Be $firstConvert.ScriptBlock.ToString()
    }
}
