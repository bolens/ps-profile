<#
tests/unit/utility-optimize-git-performance-extended.tests.ps1
#>
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
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Script = Join-Path $script:TestRepoRoot 'scripts/utils/performance/optimize-git-performance.ps1'
}
Describe 'optimize-git-performance.ps1 extended scenarios' {
    It 'Documents git and Starship prompt optimization goals' {
        $c = Get-Content -LiteralPath $script:Script -Raw
        $c | Should -Match 'git performance'
        $c | Should -Match 'Starship'
    }
    It 'Resolves starship.toml via PlatformPaths helpers' {
        $c = Get-Content -LiteralPath $script:Script -Raw
        $c | Should -Match 'starship\.toml'
        $c | Should -Match 'Get-ConfigDirectory'
    }
    It 'Configures git caching and timeout settings' {
        $c = Get-Content -LiteralPath $script:Script -Raw
        $c | Should -Match 'git config'
        $c | Should -Match 'timeout'
    }
    It 'Uses cross-platform user home resolution' {
        $c = Get-Content -LiteralPath $script:Script -Raw
        $c | Should -Match 'Get-UserHome'
    }
}
