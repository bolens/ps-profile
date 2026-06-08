# ===============================================
# profile-rclone-fragment-extended.tests.ps1
# Execution tests for rclone.ps1 fragment behavior
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
    . (Join-Path $script:ProfileDir 'rclone.ps1')
}

Describe 'profile.d/rclone.ps1 extended scenarios' {
    It 'Registers rclone file transfer helpers and aliases' {
        Get-Command Copy-RcloneFile -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Get-RcloneFileList -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command rcopy -ErrorAction Stop | Should -Not -BeNullOrEmpty
    }

    It 'Copy-RcloneFile warns when rclone is unavailable' {
        Set-TestCommandAvailabilityState -CommandName 'rclone' -Available $false
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }
        if ($global:MissingToolWarnings) {
            $null = $global:MissingToolWarnings.TryRemove('rclone', [ref]$null)
        }

        $output = Copy-RcloneFile 'src' 'dst' 2>&1 3>&1 | Out-String
        Assert-TestMissingToolWarning -Output $output -Pattern 'rclone not found'
    }

    It 'Preserves existing rclone helper bodies on repeated fragment loads' {
        $firstCopy = Get-Command Copy-RcloneFile -ErrorAction Stop

        . (Join-Path $script:ProfileDir 'rclone.ps1')

        (Get-Command Copy-RcloneFile -ErrorAction Stop).ScriptBlock.ToString() |
            Should -Be $firstCopy.ScriptBlock.ToString()
    }
}
