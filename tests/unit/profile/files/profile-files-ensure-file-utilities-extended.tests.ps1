# ===============================================
# profile-files-ensure-file-utilities-extended.tests.ps1
# Execution tests for files.ps1 Ensure-FileUtilities behavior
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
    $script:TestTempRoot = New-TestTempDirectory -Prefix 'ProfileEnsureFileUtilities'
    . (Join-Path $script:ProfileDir 'bootstrap.ps1')
    . (Join-Path $script:ProfileDir 'files-module-registry.ps1')
    . (Join-Path $script:ProfileDir 'files.ps1')
}

function script:Reset-FileUtilitiesState {
    Set-Variable -Name FileUtilitiesInitialized -Scope Global -Value $false -Force
}

Describe 'profile.d/files.ps1 Ensure-FileUtilities extended scenarios' {
    BeforeEach {
        Reset-FileUtilitiesState
    }

    It 'Registers inspection helpers through Ensure-FileUtilities' {
        Ensure-FileUtilities

        Get-Command Get-FileHashValue -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Get-FileSize -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Get-FileHead -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Get-HexDump -ErrorAction Stop | Should -Not -BeNullOrEmpty
        $global:FileUtilitiesInitialized | Should -Be $true
    }

    It 'Get-FileHashValue computes a hash after Ensure-FileUtilities' {
        $tempFile = Join-Path $script:TestTempRoot 'ensure-hash.txt'
        Set-Content -Path $tempFile -Value 'ensure-file-utilities' -NoNewline

        $hash = Get-FileHashValue -Path $tempFile

        $hash.Algorithm | Should -Be 'SHA256'
        $hash.Path | Should -Be $tempFile
    }

    It 'Skips re-initialization when file utilities are already loaded' {
        Ensure-FileUtilities
        $firstHash = Get-Command Get-FileHashValue -ErrorAction Stop

        Ensure-FileUtilities

        (Get-Command Get-FileHashValue -ErrorAction Stop).ScriptBlock.ToString() |
            Should -Be $firstHash.ScriptBlock.ToString()
    }
}
