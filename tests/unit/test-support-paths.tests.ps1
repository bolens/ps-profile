<#
tests/unit/test-support-paths.tests.ps1

.SYNOPSIS
    Unit tests for TestPaths helper functions not covered elsewhere.
#>

BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
}

Describe 'TestPaths helpers' {
    Context 'New-TestTempFile' {
        It 'Creates a file with optional initial content' {
            $filePath = New-TestTempFile -Prefix 'PathsContent' -Extension '.txt' -Content 'probe-content'
            try {
                Test-Path -LiteralPath $filePath | Should -Be $true
                (Get-Content -LiteralPath $filePath -Raw).Trim() | Should -Be 'probe-content'
            }
            finally {
                Remove-Item -LiteralPath $filePath -Force -ErrorAction SilentlyContinue
            }
        }

        It 'Normalizes extensions without a leading dot' {
            $filePath = New-TestTempFile -Prefix 'PathsExt' -Extension 'json'
            try {
                $filePath | Should -Match '\.json$'
            }
            finally {
                Remove-Item -LiteralPath $filePath -Force -ErrorAction SilentlyContinue
            }
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
