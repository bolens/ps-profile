# ===============================================
# profile-files-hash-extended.tests.ps1
# Execution tests for files-modules/inspection/files-hash.ps1 behavior
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
    $script:TestTempRoot = New-TestTempDirectory -Prefix 'ProfileFilesHash'
    . (Join-Path $script:ProfileDir 'bootstrap.ps1')
    . (Join-Path $script:ProfileDir 'files-module-registry.ps1')
    . (Join-Path $script:ProfileDir 'files.ps1')
}

function script:Reset-FileUtilitiesState {
    Set-Variable -Name FileUtilitiesInitialized -Scope Global -Value $false -Force
}

Describe 'profile.d/files-modules/inspection/files-hash.ps1 extended scenarios' {
    BeforeEach {
        Reset-FileUtilitiesState
    }

    It 'Registers Get-FileHashValue through Ensure-FileUtilities' {
        Ensure-FileUtilities

        Get-Command Get-FileHashValue -ErrorAction Stop | Should -Not -BeNullOrEmpty

        $alias = Get-Alias file-hash -ErrorAction SilentlyContinue
        if ($alias) {
            $alias.ResolvedCommandName | Should -Be 'Get-FileHashValue'
        }
    }

    It 'Get-FileHashValue calculates SHA256 hash for a temp file' {
        $tempFile = Join-Path $script:TestTempRoot 'hash-sha256.txt'
        Set-Content -Path $tempFile -Value 'hash extended test content' -NoNewline

        $hash = Get-FileHashValue -Path $tempFile

        $hash.Algorithm | Should -Be 'SHA256'
        $hash.Hash.Length | Should -Be 64
        $hash.Path | Should -Be $tempFile
    }

    It 'Get-FileHashValue supports alternate algorithms' {
        $tempFile = Join-Path $script:TestTempRoot 'hash-md5.txt'
        Set-Content -Path $tempFile -Value 'md5 content' -NoNewline

        $hash = Get-FileHashValue -Path $tempFile -Algorithm MD5

        $hash.Algorithm | Should -Be 'MD5'
        $hash.Hash.Length | Should -Be 32
    }
}
