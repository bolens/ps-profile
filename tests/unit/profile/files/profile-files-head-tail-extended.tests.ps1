# ===============================================
# profile-files-head-tail-extended.tests.ps1
# Execution tests for files-modules/inspection/files-head-tail.ps1 behavior
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
    $script:TestTempRoot = New-TestTempDirectory -Prefix 'ProfileFilesHeadTail'
    . (Join-Path $script:ProfileDir 'bootstrap.ps1')
    . (Join-Path $script:ProfileDir 'files-module-registry.ps1')
    . (Join-Path $script:ProfileDir 'files.ps1')
}

function script:Reset-FileUtilitiesState {
    Set-Variable -Name FileUtilitiesInitialized -Scope Global -Value $false -Force
}

Describe 'profile.d/files-modules/inspection/files-head-tail.ps1 extended scenarios' {
    BeforeEach {
        Reset-FileUtilitiesState
    }

    It 'Registers Get-FileHead and Get-FileTail through Ensure-FileUtilities' {
        Ensure-FileUtilities

        Get-Command Get-FileHead -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Get-FileTail -ErrorAction Stop | Should -Not -BeNullOrEmpty

        $headAlias = Get-Alias head -ErrorAction SilentlyContinue
        if ($headAlias) {
            $headAlias.ResolvedCommandName | Should -Be 'Get-FileHead'
        }

        $tailAlias = Get-Alias tail -ErrorAction SilentlyContinue
        if ($tailAlias) {
            $tailAlias.ResolvedCommandName | Should -Be 'Get-FileTail'
        }
    }

    It 'Get-FileHead returns the first N lines from a file' {
        $content = (1..15 | ForEach-Object { "line$_" }) -join "`n"
        $tempFile = Join-Path $script:TestTempRoot 'head-lines.txt'
        Set-Content -Path $tempFile -Value $content

        $result = Get-FileHead -Path $tempFile -Lines 5

        $result.Count | Should -Be 5
        $result[0] | Should -Be 'line1'
        $result[4] | Should -Be 'line5'
    }

    It 'Get-FileTail returns the last N lines from a file' {
        $content = (1..12 | ForEach-Object { "line$_" }) -join "`n"
        $tempFile = Join-Path $script:TestTempRoot 'tail-lines.txt'
        Set-Content -Path $tempFile -Value $content

        $result = Get-FileTail -Path $tempFile -Lines 4

        $result.Count | Should -Be 4
        $result[0] | Should -Be 'line9'
        $result[3] | Should -Be 'line12'
    }
}
