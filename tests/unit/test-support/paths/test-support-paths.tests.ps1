<#
tests/unit/test-support-paths.tests.ps1

.SYNOPSIS
    Unit tests for TestPaths helper functions not covered elsewhere.
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
}

Describe 'TestPaths helpers' {
    Context 'Get-TestRepoRelativePath' {
        It 'Converts an absolute test-data path to a repository-relative path' {
            $artifactPath = Get-TestArtifactPath -FileName 'repo-relative-probe.txt'
            $relativePath = Get-TestRepoRelativePath -Path $artifactPath -StartPath $PSScriptRoot

            $relativePath | Should -Match '^tests/test-data/repo-relative-probe\.txt$'
            (Join-Path $script:TestRepoRoot $relativePath) | Should -Be $artifactPath
        }
    }

    Context 'New-TestExternalTempDirectory' {
        It 'Creates a directory outside the repository root and registers cleanup' {
            $externalDir = New-TestExternalTempDirectory -Prefix 'PathsExternal'
                        Test-Path -LiteralPath $externalDir | Should -Be $true
            $externalDir.StartsWith($script:TestRepoRoot, [StringComparison]::OrdinalIgnoreCase) | Should -Be $false
        }
        finally {
            Clear-RegisteredTestCleanupPaths
        }
    }

    Context 'New-TestTempFile' {
        It 'Creates a file with optional initial content' {
            $filePath = New-TestTempFile -Prefix 'PathsContent' -Extension '.txt' -Content 'probe-content'
                        Test-Path -LiteralPath $filePath | Should -Be $true
            (Get-Content -LiteralPath $filePath -Raw).Trim() | Should -Be 'probe-content'
        }
        finally {
            Remove-Item -LiteralPath $filePath -Force -ErrorAction SilentlyContinue
        }

        It 'Normalizes extensions without a leading dot' {
            $filePath = New-TestTempFile -Prefix 'PathsExt' -Extension 'json'
                        $filePath | Should -Match '\.json$'
        }
        finally {
            Remove-Item -LiteralPath $filePath -Force -ErrorAction SilentlyContinue
        }
    }

    Context 'Get-TestArtifactsPath' {
        It 'Places artifacts under tests/test-artifacts' {
            $artifactPath = Get-TestArtifactsPath -StartPath $PSScriptRoot -EnsureExists
            $artifactPath | Should -BeLike "*$([IO.Path]::DirectorySeparatorChar)test-artifacts"
            Test-Path -LiteralPath $artifactPath | Should -Be $true
        }
    }

    Context 'Clear-RegisteredTestCleanupPaths' {
        It 'Removes only registered cleanup paths' {
            $fixture = New-TestTempFile -Prefix 'CleanupRegistryProbe' -Extension '.txt' -Content 'x'
            Test-Path -LiteralPath $fixture | Should -Be $true

            Clear-RegisteredTestCleanupPaths

            Test-Path -LiteralPath $fixture | Should -Be $false
        }
    }

    Context 'Get-TestSuiteFiles' {
        It 'Returns only ps1 test files from a suite directory' {
            $files = Get-TestSuiteFiles -Suite 'Unit' -StartPath $PSScriptRoot
            $files.Count | Should -BeGreaterThan 0
            ($files | Select-Object -First 1).Extension | Should -Be '.ps1'
        }
    }
}
