<#
tests/unit/test-support-test-mocks-extended.tests.ps1
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
    $script:Fragment = Join-Path $script:TestRepoRoot 'tests/TestSupport/TestMocks.ps1'
}
Describe 'tests/TestSupport/TestMocks.ps1 extended scenarios' {
    It 'Documents test mock initialization utilities' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Initialize-TestMocks'
        $c | Should -Match 'Reset-TestIsolationState'
    }
    It 'Shadows editor and external command helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Get-AvailableEditor'
        $c | Should -Match 'Open-Editor'
        $c | Should -Match 'Open-VSCode'
    }
    It 'Defines Remove-TestArtifacts cleanup helper' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Remove-TestArtifacts'
        $c | Should -Match 'Get-TestStartProcessCapture'
    }
}


Describe 'Repository spillover cleanup' {
    It 'Preserves changelog configuration while removing known test output' {
        $fixture = Join-Path $TestDrive 'cleanup-root'
        New-Item -ItemType Directory -Path $fixture | Out-Null
        Set-Content -LiteralPath (Join-Path $fixture 'cliff.toml') -Value 'maintained configuration'
        Set-Content -LiteralPath (Join-Path $fixture 'backup.dump') -Value 'temporary output'
        $probe = Join-Path $TestDrive 'cleanup-probe.ps1'
        @'
param([string]$Helper, [string]$FixtureRoot)
$ErrorActionPreference = 'Stop'
. $Helper
function Get-TestRepoRoot { param([string]$StartPath) return $FixtureRoot }
Clear-TestRepoRootSpillover -StartPath $FixtureRoot
'@ | Set-Content -LiteralPath $probe
        $output = & (Get-Process -Id $PID).Path -NoProfile -File $probe $script:Fragment $fixture 2>&1
        $LASTEXITCODE | Should -Be 0 -Because ($output -join [Environment]::NewLine)
        Get-Content -LiteralPath (Join-Path $fixture 'cliff.toml') | Should -Be 'maintained configuration'
        Test-Path -LiteralPath (Join-Path $fixture 'backup.dump') | Should -BeFalse
    }
}
