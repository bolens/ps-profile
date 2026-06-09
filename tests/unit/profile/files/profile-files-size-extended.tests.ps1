# ===============================================
# profile-files-size-extended.tests.ps1
# Execution tests for files-modules/inspection/files-size.ps1 behavior
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
    $script:TestTempRoot = New-TestTempDirectory -Prefix 'ProfileFilesSize'
    . (Join-Path $script:ProfileDir 'bootstrap.ps1')
    . (Join-Path $script:ProfileDir 'files-module-registry.ps1')
    . (Join-Path $script:ProfileDir 'files.ps1')
}

function script:Reset-FileUtilitiesState {
    Set-Variable -Name FileUtilitiesInitialized -Scope Global -Value $false -Force
}

Describe 'profile.d/files-modules/inspection/files-size.ps1 extended scenarios' {
    BeforeEach {
        Reset-FileUtilitiesState
    }

    It 'Registers Get-FileSize through Ensure-FileUtilities' {
        Ensure-FileUtilities

        Get-Command Get-FileSize -ErrorAction Stop | Should -Not -BeNullOrEmpty

        $alias = Get-Alias filesize -ErrorAction SilentlyContinue
        if ($alias) {
            $alias.ResolvedCommandName | Should -Be 'Get-FileSize'
        }
    }

    It 'Get-FileSize returns bytes for a small file' {
        $tempFile = Join-Path $script:TestTempRoot 'size-small.txt'
        Set-Content -Path $tempFile -Value 'x' -NoNewline

        Get-FileSize -Path $tempFile | Should -Match '\d+ bytes'
    }

    It 'Get-FileSize returns KB for a larger file' {
        $tempFile = Join-Path $script:TestTempRoot 'size-kb.txt'
        Set-Content -Path $tempFile -Value ('x' * 2048) -NoNewline

        Get-FileSize -Path $tempFile | Should -Match '\d+\.\d+ KB'
    }
}
