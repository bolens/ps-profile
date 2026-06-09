# ===============================================
# profile-files-hexdump-extended.tests.ps1
# Execution tests for files-modules/inspection/files-hexdump.ps1 behavior
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
    $script:TestTempRoot = New-TestTempDirectory -Prefix 'ProfileFilesHexDump'
    . (Join-Path $script:ProfileDir 'bootstrap.ps1')
    . (Join-Path $script:ProfileDir 'files-module-registry.ps1')
    . (Join-Path $script:ProfileDir 'files.ps1')
}

function script:Reset-FileUtilitiesState {
    Set-Variable -Name FileUtilitiesInitialized -Scope Global -Value $false -Force
}

Describe 'profile.d/files-modules/inspection/files-hexdump.ps1 extended scenarios' {
    BeforeEach {
        Reset-FileUtilitiesState
    }

    It 'Registers Get-HexDump through Ensure-FileUtilities' {
        Ensure-FileUtilities

        Get-Command Get-HexDump -ErrorAction Stop | Should -Not -BeNullOrEmpty

        $alias = Get-Alias hex-dump -ErrorAction SilentlyContinue
        if ($alias) {
            $alias.ResolvedCommandName | Should -Be 'Get-HexDump'
        }
    }

    It 'Get-HexDump produces hex output for file contents' {
        $tempFile = Join-Path $script:TestTempRoot 'hexdump.txt'
        Set-Content -Path $tempFile -Value 'AB' -NoNewline

        $result = Get-HexDump -Path $tempFile

        $result | Should -Not -BeNullOrEmpty
        $result.ToString() | Should -Match '41\s+42'
    }
}
