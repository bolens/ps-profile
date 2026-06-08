# ===============================================
# media-tools.tests.ps1
# Integration tests for media-tools.ps1 fragment
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
    . (Join-Path $script:ProfileDir 'env.ps1')
    . (Join-Path $script:ProfileDir 'media-tools.ps1')
}

Describe 'media-tools.ps1 - Fragment Loading' {
    It 'Loads fragment without errors' {
        { . (Join-Path $script:ProfileDir 'media-tools.ps1') } | Should -Not -Throw
    }
    
    It 'Is idempotent (can be loaded multiple times)' {
        { 
            . (Join-Path $script:ProfileDir 'media-tools.ps1')
            . (Join-Path $script:ProfileDir 'media-tools.ps1')
        } | Should -Not -Throw
    }
}

Describe 'media-tools.ps1 - Function Registration' {
    It 'Registers Convert-Video function' {
        Get-Command -Name 'Convert-Video' -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
    }
    
    It 'Registers Extract-Audio function' {
        Get-Command -Name 'Extract-Audio' -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
    }
    
    It 'Registers Tag-Audio function' {
        Get-Command -Name 'Tag-Audio' -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
    }
    
    It 'Registers Rip-CD function' {
        Get-Command -Name 'Rip-CD' -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
    }
    
    It 'Registers Get-MediaInfo function' {
        Get-Command -Name 'Get-MediaInfo' -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
    }
    
    It 'Registers Merge-MKV function' {
        Get-Command -Name 'Merge-MKV' -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
    }
}

Describe 'media-tools.ps1 - Graceful Degradation' {
    BeforeEach {
        if ($global:CollectedMissingToolWarnings) {
            $global:CollectedMissingToolWarnings.Clear()
        }
        if ($global:MissingToolWarnings) {
            $global:MissingToolWarnings.Clear()
        }
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }

        foreach ($cmd in @('handbrake-cli', 'HandBrakeCLI', 'ffmpeg', 'cyanrip', 'mediainfo', 'MediaInfo', 'mkvmerge', 'mp3tag')) {
            Set-TestCommandAvailabilityState -CommandName $cmd -Available $false
        }

        $script:TestMediaFile = Join-Path $TestDrive 'test.mp4'
        Set-Content -Path $script:TestMediaFile -Value 'test' -NoNewline
        $script:TestAudioFile = Join-Path $TestDrive 'test.mp3'
        Set-Content -Path $script:TestAudioFile -Value 'test' -NoNewline
    }

    It 'Convert-Video handles missing tool gracefully' {
        $output = & {
            Convert-Video -InputPath $script:TestMediaFile -OutputPath (Join-Path $TestDrive 'output.mkv') -ErrorAction SilentlyContinue
        } 2>&1 3>&1 | Out-String
        Assert-TestMissingToolWarning -Output $output -Pattern 'ffmpeg not found'
        Assert-TestOutputContainsInstallCommand -Output $output -ToolName 'ffmpeg'
    }

    It 'Convert-Video handles missing handbrake gracefully' {
        $output = & {
            Convert-Video -InputPath $script:TestMediaFile -OutputPath (Join-Path $TestDrive 'output.mkv') -UseHandbrake -ErrorAction SilentlyContinue
        } 2>&1 3>&1 | Out-String
        Assert-TestMissingToolWarning -Output $output -Pattern 'handbrake-cli not found'
        Assert-TestOutputContainsInstallCommand -Output $output -ToolName 'handbrake-cli'
    }

    It 'Extract-Audio handles missing tool gracefully' {
        $output = & {
            Extract-Audio -InputPath $script:TestMediaFile -OutputPath (Join-Path $TestDrive 'audio.mp3') -ErrorAction SilentlyContinue
        } 2>&1 3>&1 | Out-String
        Assert-TestMissingToolWarning -Output $output -Pattern 'ffmpeg not found'
        Assert-TestOutputContainsInstallCommand -Output $output -ToolName 'ffmpeg'
    }

    It 'Tag-Audio handles missing tool gracefully' {
        $output = & { Tag-Audio -AudioPath $script:TestAudioFile -ErrorAction SilentlyContinue } 2>&1 3>&1 | Out-String
        Assert-TestMissingToolWarning -Output $output -Pattern 'mp3tag not found'
        Assert-TestOutputContainsInstallCommand -Output $output -ToolName 'mp3tag'
    }

    It 'Rip-CD handles missing tool gracefully' {
        $output = & { Rip-CD -OutputPath (Join-Path $TestDrive 'rip-output') -ErrorAction SilentlyContinue } 2>&1 3>&1 | Out-String
        Assert-TestMissingToolWarning -Output $output -Pattern 'cyanrip not found'
        Assert-TestOutputContainsInstallCommand -Output $output -ToolName 'cyanrip'
    }

    It 'Get-MediaInfo handles missing tool gracefully' {
        $output = & { Get-MediaInfo -MediaPath $script:TestMediaFile -ErrorAction SilentlyContinue } 2>&1 3>&1 | Out-String
        Assert-TestMissingToolWarning -Output $output -Pattern 'mediainfo not found'
        Assert-TestOutputContainsInstallCommand -Output $output -ToolName 'mediainfo'
    }

    It 'Merge-MKV handles missing tool gracefully' {
        $output = & {
            Merge-MKV -InputPaths @($script:TestMediaFile) -OutputPath (Join-Path $TestDrive 'merged.mkv') -ErrorAction SilentlyContinue
        } 2>&1 3>&1 | Out-String
        Assert-TestMissingToolWarning -Output $output -Pattern 'mkvmerge not found'
        Assert-TestOutputContainsInstallCommand -Output $output -ToolName 'mkvmerge'
    }
}

