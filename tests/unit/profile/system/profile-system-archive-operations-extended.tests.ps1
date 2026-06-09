# ===============================================
# profile-system-archive-operations-extended.tests.ps1
# Execution tests for system/ArchiveOperations.ps1 behavior
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
    $script:TestTempRoot = New-TestTempDirectory -Prefix 'ProfileSystemArchive'
    . (Join-Path $script:ProfileDir 'bootstrap.ps1')
    . (Join-Path $script:ProfileDir 'files-module-registry.ps1')
    . (Join-Path $script:ProfileDir 'system.ps1')
}

function script:Reset-SystemFragmentState {
    Set-Variable -Name 'SystemInitialized' -Scope Global -Value $false -Force
}

Describe 'profile.d/system/ArchiveOperations.ps1 extended scenarios' {
    BeforeEach {
        Reset-SystemFragmentState
        Ensure-System
    }

    It 'Registers archive helper commands through Ensure-System' {
        Get-Command Expand-ArchiveCustom -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Compress-ArchiveCustom -ErrorAction Stop | Should -Not -BeNullOrEmpty

        $unzipAlias = Get-Alias unzip -ErrorAction SilentlyContinue
        if ($unzipAlias) {
            $unzipAlias.ResolvedCommandName | Should -Be 'Expand-ArchiveCustom'
        }

        $zipAlias = Get-Alias zip -ErrorAction SilentlyContinue
        if ($zipAlias) {
            $zipAlias.ResolvedCommandName | Should -Be 'Compress-ArchiveCustom'
        }
    }

    It 'Compress-ArchiveCustom creates a zip archive from a source file' {
        $sourceFile = Join-Path $script:TestTempRoot 'archive-source.txt'
        $zipPath = Join-Path $script:TestTempRoot 'archive.zip'
        Set-Content -Path $sourceFile -Value 'archive test content' -NoNewline

        Compress-ArchiveCustom -Path $sourceFile -DestinationPath $zipPath -Force

        Test-Path -LiteralPath $zipPath | Should -Be $true
    }

    It 'Expand-ArchiveCustom extracts a zip archive' {
        $sourceFile = Join-Path $script:TestTempRoot 'extract-source.txt'
        $zipPath = Join-Path $script:TestTempRoot 'extract.zip'
        $extractDir = Join-Path $script:TestTempRoot 'extracted'
        Set-Content -Path $sourceFile -Value 'extract test content' -NoNewline
        Compress-Archive -Path $sourceFile -DestinationPath $zipPath -Force
        New-Item -ItemType Directory -Path $extractDir -Force | Out-Null

        Expand-ArchiveCustom -Path $zipPath -DestinationPath $extractDir -Force

        Test-Path -LiteralPath (Join-Path $extractDir 'extract-source.txt') | Should -Be $true
    }
}
