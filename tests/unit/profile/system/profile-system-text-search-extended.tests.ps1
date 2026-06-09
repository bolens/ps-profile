# ===============================================
# profile-system-text-search-extended.tests.ps1
# Execution tests for system/TextSearch.ps1 behavior
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
    $script:TestTempRoot = New-TestTempDirectory -Prefix 'ProfileSystemTextSearch'
    . (Join-Path $script:ProfileDir 'bootstrap.ps1')
    . (Join-Path $script:ProfileDir 'files-module-registry.ps1')
    . (Join-Path $script:ProfileDir 'system.ps1')
}

function script:Reset-SystemFragmentState {
    Set-Variable -Name 'SystemInitialized' -Scope Global -Value $false -Force
}

Describe 'profile.d/system/TextSearch.ps1 extended scenarios' {
    BeforeEach {
        Reset-SystemFragmentState
        Ensure-System
    }

    It 'Registers Find-String through Ensure-System' {
        Get-Command Find-String -ErrorAction Stop | Should -Not -BeNullOrEmpty

        $pgrepAlias = Get-Alias pgrep -ErrorAction SilentlyContinue
        if ($pgrepAlias) {
            $pgrepAlias.ResolvedCommandName | Should -Be 'Find-String'
        }
    }

    It 'Find-String matches patterns in a file path' {
        $tempFile = Join-Path $script:TestTempRoot 'grep-target.txt'
        Set-Content -Path $tempFile -Value "alpha`nneedle-here`nomega" -NoNewline

        $matches = @(Find-String -Pattern 'needle' -Path $tempFile)
        $matches.Count | Should -BeGreaterThan 0
        $matches[0].Line | Should -Match 'needle-here'
    }

    It 'Find-String returns early when pattern is missing' {
        { Find-String -Path $script:TestTempRoot } | Should -Not -Throw
    }
}
