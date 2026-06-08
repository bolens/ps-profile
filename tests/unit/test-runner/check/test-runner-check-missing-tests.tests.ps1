<#
tests/unit/test-runner-check-missing-tests.tests.ps1

.SYNOPSIS
    Behavioral unit tests for check-missing-tests.ps1 module coverage audit.
#>

function global:Invoke-CheckMissingTestsScript {
    $output = & pwsh -NoProfile -File $script:CheckScript 2>&1 | Out-String
    return [pscustomobject]@{
        ExitCode = $LASTEXITCODE
        Output   = $output
    }
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
    $script:CheckScript = Join-Path $script:TestRepoRoot 'scripts' 'utils' 'code-quality' 'check-missing-tests.ps1'
}

Describe 'check-missing-tests.ps1 execution' {
    It 'Recursively scans scripts/lib and reports full module coverage for this repository' {
        $result = Invoke-CheckMissingTestsScript

        $result.ExitCode | Should -Be 0
        $result.Output | Should -Match 'Total modules:\s+[1-9]\d*'
        $result.Output | Should -Match 'Modules with tests:\s+[1-9]\d*'
        $result.Output | Should -Match 'Missing tests for:\s*\(none\)'
    }

    It 'Fails when an isolated repository has a lib module without a matching unit test' {
        $repo = New-TestTempDirectory -Prefix 'CheckMissingTestsFail'
        try {
            $checkDir = Join-Path $repo 'scripts' 'utils' 'code-quality'
            $libDir = Join-Path $repo 'scripts' 'lib' 'fixture'
            $unitDir = Join-Path $repo 'tests' 'unit'
            $null = New-Item -ItemType Directory -Path $checkDir -Force
            $null = New-Item -ItemType Directory -Path $libDir -Force
            $null = New-Item -ItemType Directory -Path $unitDir -Force
            Copy-Item -LiteralPath $script:CheckScript -Destination (Join-Path $checkDir 'check-missing-tests.ps1') -Force
            Set-Content -LiteralPath (Join-Path $libDir 'UntestedLibModule.psm1') -Value @'
function Get-UntestedLibModuleFixture {
    'missing-test'
}
'@ -Encoding UTF8

            Push-Location $repo
            try {
                git init -q | Out-Null
                git config user.email 'fixture@example.com'
                git config user.name 'Fixture'

                $output = & pwsh -NoProfile -File (Join-Path $checkDir 'check-missing-tests.ps1') 2>&1 | Out-String
                $exitCode = $LASTEXITCODE
            }
            finally {
                Pop-Location
            }

            $exitCode | Should -Be 1
            $output | Should -Match 'UntestedLibModule'
            $output | Should -Match 'Missing tests for:'
        }
        finally {
            if (Test-Path -LiteralPath $repo) {
                Remove-Item -LiteralPath $repo -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }

    It 'Passes when an isolated repository has matching library unit tests for every lib module' {
        $repo = New-TestTempDirectory -Prefix 'CheckMissingTestsPass'
        try {
            $checkDir = Join-Path $repo 'scripts' 'utils' 'code-quality'
            $libDir = Join-Path $repo 'scripts' 'lib' 'fixture'
            $unitDir = Join-Path $repo 'tests' 'unit'
            $null = New-Item -ItemType Directory -Path $checkDir -Force
            $null = New-Item -ItemType Directory -Path $libDir -Force
            $null = New-Item -ItemType Directory -Path $unitDir -Force
            Copy-Item -LiteralPath $script:CheckScript -Destination (Join-Path $checkDir 'check-missing-tests.ps1') -Force
            Set-Content -LiteralPath (Join-Path $libDir 'CoveredLibModule.psm1') -Value @'
function Get-CoveredLibModuleFixture {
    'covered'
}
'@ -Encoding UTF8
            Set-Content -LiteralPath (Join-Path $unitDir 'library-coveredlibmodule.tests.ps1') -Value @'
Describe 'CoveredLibModule' {
    It 'has a matching test file name' { $true | Should -BeTrue }
}
'@ -Encoding UTF8

            Push-Location $repo
            try {
                git init -q | Out-Null
                git config user.email 'fixture@example.com'
                git config user.name 'Fixture'

                $output = & pwsh -NoProfile -File (Join-Path $checkDir 'check-missing-tests.ps1') 2>&1 | Out-String
                $exitCode = $LASTEXITCODE
            }
            finally {
                Pop-Location
            }

            $exitCode | Should -Be 0
            $output | Should -Match 'Missing tests for:\s*\(none\)'
        }
        finally {
            if (Test-Path -LiteralPath $repo) {
                Remove-Item -LiteralPath $repo -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }
}
