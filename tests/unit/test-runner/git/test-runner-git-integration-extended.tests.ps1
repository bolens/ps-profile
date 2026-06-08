<#
tests/unit/test-runner-git-integration-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for TestGitIntegration path mapping and git diff behavior.
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
    $modulePath = Join-Path (Get-TestRepoRoot -StartPath $PSScriptRoot) 'scripts/utils/code-quality/modules'
    Import-Module (Join-Path (Get-TestRepoRoot -StartPath $PSScriptRoot) 'scripts/lib/core/Logging.psm1') -DisableNameChecking -Force -Global
    Import-Module (Join-Path $modulePath 'TestGitIntegration.psm1') -Force -Global

    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:TempDir = New-TestTempDirectory -Prefix 'GitIntegrationExtended'
}

AfterAll {
    if ($script:TempDir -and (Test-Path -LiteralPath $script:TempDir)) {
        Remove-Item -LiteralPath $script:TempDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Describe 'TestGitIntegration extended scenarios' {
    Context 'Get-TestFilesForSourceFiles' {
        It 'Maps nested scripts paths to unit test paths' {
            $tempRepo = Join-Path $script:TempDir 'scripts-nested-map'
            try {
                $srcFile = Join-Path $tempRepo 'scripts/utils/code-quality/run-pester.ps1'
                $testFile = Join-Path $tempRepo 'tests/unit/utils/code-quality/run-pester.tests.ps1'
                New-Item -ItemType Directory -Path (Split-Path $srcFile) -Force | Out-Null
                New-Item -ItemType Directory -Path (Split-Path $testFile) -Force | Out-Null
                Set-Content -LiteralPath $srcFile -Value '# runner' -Encoding UTF8
                Set-Content -LiteralPath $testFile -Value 'Describe runner {}' -Encoding UTF8

                $testFiles = @(Get-TestFilesForSourceFiles -SourceFiles @($srcFile) -RepoRoot $tempRepo)
                $testFiles.Count | Should -Be 1
                $testFiles[0] | Should -Be $testFile
            }
            finally {
                Remove-Item -LiteralPath $tempRepo -Recurse -Force -ErrorAction SilentlyContinue
            }
        }

        It 'Maps profile.d sources to unit tests when integration tests are absent' {
            $tempRepo = Join-Path $script:TempDir 'profile-unit-map'
            try {
                $srcFile = Join-Path $tempRepo 'profile.d/nested/sample-tool.ps1'
                $testFile = Join-Path $tempRepo 'tests/unit/nested/sample-tool.tests.ps1'
                New-Item -ItemType Directory -Path (Split-Path $srcFile) -Force | Out-Null
                New-Item -ItemType Directory -Path (Split-Path $testFile) -Force | Out-Null
                Set-Content -LiteralPath $srcFile -Value '# sample' -Encoding UTF8
                Set-Content -LiteralPath $testFile -Value 'Describe sample {}' -Encoding UTF8

                $testFiles = @(Get-TestFilesForSourceFiles -SourceFiles @($srcFile) -RepoRoot $tempRepo)
                $testFiles.Count | Should -Be 1
                $testFiles[0] | Should -Be $testFile
            }
            finally {
                Remove-Item -LiteralPath $tempRepo -Recurse -Force -ErrorAction SilentlyContinue
            }
        }

        It 'Maps source files to performance tests by basename' {
            $tempRepo = Join-Path $script:TempDir 'performance-map'
            try {
                $srcFile = Join-Path $tempRepo 'profile.d/performance-target.ps1'
                $testFile = Join-Path $tempRepo 'tests/performance/performance-target.tests.ps1'
                New-Item -ItemType Directory -Path (Split-Path $srcFile) -Force | Out-Null
                New-Item -ItemType Directory -Path (Split-Path $testFile) -Force | Out-Null
                Set-Content -LiteralPath $srcFile -Value '# performance' -Encoding UTF8
                Set-Content -LiteralPath $testFile -Value 'Describe performance {}' -Encoding UTF8

                $testFiles = @(Get-TestFilesForSourceFiles -SourceFiles @($srcFile) -RepoRoot $tempRepo)
                $testFiles | Should -Contain $testFile
            }
            finally {
                Remove-Item -LiteralPath $tempRepo -Recurse -Force -ErrorAction SilentlyContinue
            }
        }

        It 'Returns sorted unique test paths for multiple sources' {
            $tempRepo = Join-Path $script:TempDir 'dedupe-map'
            try {
                $srcA = Join-Path $tempRepo 'profile.d/shared.ps1'
                $srcB = Join-Path $tempRepo 'scripts/shared.ps1'
                $testFile = Join-Path $tempRepo 'tests/unit/shared.tests.ps1'
                New-Item -ItemType Directory -Path (Split-Path $srcA) -Force | Out-Null
                New-Item -ItemType Directory -Path (Split-Path $srcB) -Force | Out-Null
                New-Item -ItemType Directory -Path (Split-Path $testFile) -Force | Out-Null
                Set-Content -LiteralPath $srcA -Value '# shared a' -Encoding UTF8
                Set-Content -LiteralPath $srcB -Value '# shared b' -Encoding UTF8
                Set-Content -LiteralPath $testFile -Value 'Describe shared {}' -Encoding UTF8

                $testFiles = @(Get-TestFilesForSourceFiles -SourceFiles @($srcA, $srcB, $testFile) -RepoRoot $tempRepo)
                @($testFiles).Count | Should -Be 1
                $testFiles[0] | Should -Be $testFile
                $testFiles | Should -Be ($testFiles | Sort-Object)
            }
            finally {
                Remove-Item -LiteralPath $tempRepo -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }

    Context 'Get-GitChangedFilesSince' {
        It 'Returns files changed between two commits in a temporary repository' {
            if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
                Set-ItResult -Skipped -Because 'git is not available'
                return
            }

            $tempRepo = Join-Path $script:TempDir 'since-diff-repo'
            try {
                New-Item -ItemType Directory -Path $tempRepo -Force | Out-Null
                Push-Location $tempRepo
                git init -q | Out-Null
                git config user.email 'test@example.com' | Out-Null
                git config user.name 'Test User' | Out-Null

                $firstFile = Join-Path $tempRepo 'first.txt'
                Set-Content -LiteralPath $firstFile -Value 'first' -Encoding UTF8
                git add first.txt | Out-Null
                git commit -m 'first commit' -q | Out-Null

                $secondFile = Join-Path $tempRepo 'second.txt'
                Set-Content -LiteralPath $secondFile -Value 'second' -Encoding UTF8
                git add second.txt | Out-Null
                git commit -m 'second commit' -q | Out-Null
                Pop-Location

                $changed = @(Get-GitChangedFilesSince -Since 'HEAD~1' -RepoRoot $tempRepo)
                ($changed | Split-Path -Leaf) | Should -Contain 'second.txt'
            }
            finally {
                Pop-Location -ErrorAction SilentlyContinue
                Remove-Item -LiteralPath $tempRepo -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }
}
