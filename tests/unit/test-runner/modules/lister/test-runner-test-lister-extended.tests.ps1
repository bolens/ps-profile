<#
tests/unit/test-runner-test-lister-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for TestLister directory scanning and display output.
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
    Import-Module (Join-Path $modulePath 'TestLister.psm1') -Force -Global

    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:TempDir = New-TestTempDirectory -Prefix 'TestListerExtended'
}

AfterAll {
    if ($script:TempDir -and (Test-Path -LiteralPath $script:TempDir)) {
        Remove-Item -LiteralPath $script:TempDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Describe 'TestLister extended scenarios' {
    Context 'Get-TestList directory discovery' {
        It 'Aggregates tests from every test file in a directory tree' {
            $scanDir = New-TestTempDirectory -Prefix 'TestListerTree'
            $nestedDir = Join-Path $scanDir 'nested'
            New-Item -ItemType Directory -Path $nestedDir -Force | Out-Null

            $rootFile = Join-Path $scanDir 'root.tests.ps1'
            $nestedFile = Join-Path $nestedDir 'nested.tests.ps1'
            Set-Content -LiteralPath $rootFile -Value @"
Describe 'Root' {
    It 'root case' {
        `$true | Should -Be `$true
    }
}
"@ -Encoding UTF8
            Set-Content -LiteralPath $nestedFile -Value @"
Describe 'Nested' {
    It 'nested case' {
        `$true | Should -Be `$true
    }
}
"@ -Encoding UTF8

            $list = Get-TestList -TestPaths @($scanDir) -RepoRoot $script:TestRepoRoot

            $list.TestCount | Should -Be 2
            @($list.TestFiles).Count | Should -Be 2
            ($list.Tests.Name -contains 'root case') | Should -Be $true
            ($list.Tests.Name -contains 'nested case') | Should -Be $true
        }

        It 'Ignores non-test PowerShell files' {
            $scanDir = New-TestTempDirectory -Prefix 'TestListerIgnore'
            $helperFile = Join-Path $scanDir 'helper.ps1'
            $testFile = Join-Path $scanDir 'only.tests.ps1'
            Set-Content -LiteralPath $helperFile -Value "function Get-Helper { 'ok' }" -Encoding UTF8
            Set-Content -LiteralPath $testFile -Value @"
Describe 'Only' {
    It 'single case' {
        `$true | Should -Be `$true
    }
}
"@ -Encoding UTF8

            $list = Get-TestList -TestPaths @($scanDir) -RepoRoot $script:TestRepoRoot

            $list.TestCount | Should -Be 1
            @($list.TestFiles) | Should -Be @($testFile)
        }
    }

    Context 'Show-TestList output modes' {
        It 'Writes compact test names without ShowDetails' {
            $scanDir = New-TestTempDirectory -Prefix 'TestListerCompact'
            $testFile = Join-Path $scanDir 'compact.tests.ps1'
            Set-Content -LiteralPath $testFile -Value @"
Describe 'Compact suite' {
    Context 'Ready state' {
        It 'prints compact output' { `$true | Should -Be `$true }
    }
}
"@ -Encoding UTF8

            $list = Get-TestList -TestPaths @($testFile) -RepoRoot $script:TestRepoRoot

            { Show-TestList -TestList $list } | Should -Not -Throw
            $list.TestCount | Should -Be 1
            $list.Tests[0].Describe | Should -Be 'Compact suite'
            $list.Tests[0].Context | Should -Be 'Ready state'
        }
    }
}
