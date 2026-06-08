<#
tests/unit/utility-move-testsupport-to-beforeall.tests.ps1

.SYNOPSIS
    Behavioral unit tests for move-testsupport-to-beforeall.ps1 on an isolated tree.
#>

function global:New-MoveTestSupportFixtureRepository {
    $repo = New-TestTempDirectory -Prefix 'MoveTestSupportFixture'
    $integrationDir = Join-Path $repo 'tests' 'integration' 'bootstrap'
    New-Item -ItemType Directory -Path $integrationDir -Force | Out-Null
    Set-Content -LiteralPath (Join-Path $integrationDir 'noop.tests.ps1') -Value @'
Describe 'noop' {
    It 'does nothing' { $true | Should -BeTrue }
}
'@ -Encoding UTF8

    $scriptsDir = Join-Path $repo 'scripts'
    New-Item -ItemType Directory -Path (Join-Path $scriptsDir 'utils' 'code-quality') -Force | Out-Null
    Copy-Item -LiteralPath (Join-Path $script:TestRepoRoot 'scripts' 'lib') -Destination (Join-Path $scriptsDir 'lib') -Recurse -Force
    Copy-Item -LiteralPath $script:MoveTestSupportScript -Destination (Join-Path $scriptsDir 'utils' 'code-quality' 'move-testsupport-to-beforeall.ps1') -Force

    return $repo
}

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
    $script:MoveTestSupportScript = Join-Path $script:TestRepoRoot 'scripts' 'utils' 'code-quality' 'move-testsupport-to-beforeall.ps1'
    $ConfirmPreference = 'None'
}

Describe 'move-testsupport-to-beforeall.ps1 execution' {
    It 'Completes without modifying files that already use BeforeAll imports' {
        $repo = New-MoveTestSupportFixtureRepository
        try {
            $scriptPath = Join-Path $repo 'scripts' 'utils' 'code-quality' 'move-testsupport-to-beforeall.ps1'
            $result = Invoke-TestScriptFile -ScriptPath $scriptPath -ArgumentList @('-RepoRoot', $repo)

            $result.ExitCode | Should -BeIn @(0, $null)
            $result.Output | Should -Match 'Updated 0 file'
        }
        finally {
            if (Test-Path -LiteralPath $repo) {
                Remove-Item -LiteralPath $repo -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }

    It 'Moves a top-level TestSupport import into a BeforeAll hook' {
        $repo = New-TestTempDirectory -Prefix 'MoveTestSupportApply'
        $integrationDir = Join-Path $repo 'tests' 'integration' 'sample'
        $testFile = Join-Path $integrationDir 'needs-move.tests.ps1'
        try {
            New-Item -ItemType Directory -Path $integrationDir -Force | Out-Null
            Set-Content -LiteralPath $testFile -Value @'
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
Describe 'needs move' {
    It 'works' { $true | Should -BeTrue }
}
'@ -Encoding UTF8

            $result = Invoke-TestScriptFile -ScriptPath $script:MoveTestSupportScript -ArgumentList @('-RepoRoot', $repo)

            $result.ExitCode | Should -BeIn @(0, $null)
            $result.Output | Should -Match 'Updated 1 file'
            $updated = Get-Content -LiteralPath $testFile -Raw
            $updated | Should -Match 'BeforeAll \{'
            $updated.Contains('TestSupport.ps1') | Should -Be $true
            $updated | Should -Not -Match '(?m)^\. \(Join-Path \$PSScriptRoot'
        }
        finally {
            if (Test-Path -LiteralPath $repo) {
                Remove-Item -LiteralPath $repo -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }
}
