<#
tests/unit/test-runner-git-integration.tests.ps1

.SYNOPSIS
    Unit tests for the TestGitIntegration module.
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
}

Describe 'TestGitIntegration Module' {
    Context 'Get-GitChangedFiles' {
        It 'Returns an array in a git repository' {
            if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
                Set-ItResult -Skipped -Because 'git is not available'
                return
            }

            $result = Get-GitChangedFiles -RepoRoot $script:TestRepoRoot
            $result | Should -Not -BeNullOrEmpty
            @($result).GetType().Name | Should -BeIn @('Object[]', 'String[]')
        }

        It 'Returns empty array outside a git repository' {
            try {
            if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
                Set-ItResult -Skipped -Because 'git is not available'
                return
            }

            $tempDir = New-TestTempDirectory -Prefix 'NoGitRepo'
                        $result = Get-GitChangedFiles -RepoRoot $tempDir
            $result | Should -Be @()
            }
            finally {
                Remove-Item -LiteralPath $tempDir -Recurse -Force -ErrorAction SilentlyContinue
            }
        }

        It 'Includes untracked files when requested' {
            if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
                Set-ItResult -Skipped -Because 'git is not available'
                return
            }

            $tempDir = New-TestTempDirectory -Prefix 'GitUntrackedRepo'
            try {
                Push-Location $tempDir
                git init -q | Out-Null
                git config user.email 'test@example.com' | Out-Null
                git config user.name 'Test User' | Out-Null
                Set-Content -LiteralPath (Join-Path $tempDir 'tracked.txt') -Value 'tracked' -Encoding UTF8
                git add tracked.txt | Out-Null
                git commit -m 'init' -q | Out-Null
                Set-Content -LiteralPath (Join-Path $tempDir 'untracked.txt') -Value 'new' -Encoding UTF8
                Pop-Location

                $without = Get-GitChangedFiles -RepoRoot $tempDir
                $with = Get-GitChangedFiles -RepoRoot $tempDir -IncludeUntracked

                @($without).Count | Should -Be 0
                @($with).Count | Should -BeGreaterThan 0
                ($with | Split-Path -Leaf) | Should -Contain 'untracked.txt'
            }
            finally {
                Pop-Location -ErrorAction SilentlyContinue
                Remove-Item -LiteralPath $tempDir -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }

    Context 'Get-GitChangedFilesSince' {
        It 'Returns files changed since HEAD~1' {
            if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
                Set-ItResult -Skipped -Because 'git is not available'
                return
            }

            $result = Get-GitChangedFilesSince -Since 'HEAD~1' -RepoRoot $script:TestRepoRoot
            $result | Should -Not -BeNullOrEmpty
        }

        It 'Returns empty array for invalid git reference' {
            if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
                Set-ItResult -Skipped -Because 'git is not available'
                return
            }

            $result = Get-GitChangedFilesSince -Since 'invalid-ref-xyz-999' -RepoRoot $script:TestRepoRoot
            $result | Should -Be @()
        }
    }

    Context 'Get-TestFilesForSourceFiles' {
        It 'Maps source files to same-named unit tests' {
            $tempRepo = New-TestTempDirectory -Prefix 'GitMapStrategy1'
            try {
                $srcFile = Join-Path $tempRepo 'scripts/lib/utilities/Foo.psm1'
                $testFile = Join-Path $tempRepo 'tests/unit/Foo.tests.ps1'
                New-Item -ItemType Directory -Path (Split-Path $srcFile) -Force | Out-Null
                New-Item -ItemType Directory -Path (Split-Path $testFile) -Force | Out-Null
                Set-Content -LiteralPath $srcFile -Value '# foo' -Encoding UTF8
                Set-Content -LiteralPath $testFile -Value 'Describe foo {}' -Encoding UTF8

                $testFiles = @(Get-TestFilesForSourceFiles -SourceFiles @($srcFile) -RepoRoot $tempRepo)
                $testFiles.Count | Should -Be 1
                $testFiles[0] | Should -Be $testFile
            }
            finally {
                Remove-Item -LiteralPath $tempRepo -Recurse -Force -ErrorAction SilentlyContinue
            }
        }

        It 'Maps profile.d sources to integration test paths' {
            $tempRepo = New-TestTempDirectory -Prefix 'GitMapStrategy2'
            try {
                $srcFile = Join-Path $tempRepo 'profile.d/sample-tool.ps1'
                $testFile = Join-Path $tempRepo 'tests/integration/sample-tool.tests.ps1'
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

        It 'Includes test files passed directly as source' {
            $testFile = Join-Path $script:TestRepoRoot 'tests/unit/library/common/library-common.tests.ps1'
            if (-not (Test-Path -LiteralPath $testFile)) {
                Set-ItResult -Skipped -Because 'library-common.tests.ps1 not found'
                return
            }

            $testFiles = Get-TestFilesForSourceFiles -SourceFiles @($testFile) -RepoRoot $script:TestRepoRoot
            $testFiles | Should -Contain $testFile
        }

        It 'Skips non-existent source files' {
            $missing = Join-Path $script:TestRepoRoot 'nonexistent-source-file-xyz.ps1'
            $testFiles = Get-TestFilesForSourceFiles -SourceFiles @($missing) -RepoRoot $script:TestRepoRoot
            $testFiles | Should -Be @()
        }
    }
}
