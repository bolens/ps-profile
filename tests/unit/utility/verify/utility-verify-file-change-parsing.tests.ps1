<#
tests/unit/utility-verify-file-change-parsing.tests.ps1

.SYNOPSIS
    Behavioral unit tests for verify-file-change-parsing.ps1 prerequisite checks.
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
    $script:VerifyFileChangeParsingScript = Join-Path $script:TestRepoRoot 'scripts' 'utils' 'verify-file-change-parsing.ps1'
    $script:CacheInitModule = Join-Path $script:TestRepoRoot 'scripts' 'lib' 'fragment' 'FragmentCacheInitialization.psm1'
    $ConfirmPreference = 'None'
}

Describe 'verify-file-change-parsing.ps1 execution' {
    It 'Fails fast when FragmentCacheInitialization is not available' {
        $repo = New-TestTempDirectory -Prefix 'VerifyFileChangeMissingModule'
        try {
            $utilsDir = Join-Path $repo 'scripts' 'utils'
            $null = New-Item -ItemType Directory -Path $utilsDir -Force
            Copy-Item -LiteralPath $script:VerifyFileChangeParsingScript -Destination (Join-Path $utilsDir 'verify-file-change-parsing.ps1') -Force

            Push-Location $repo
            try {
                git init -q | Out-Null
                git config user.email 'fixture@example.com'
                git config user.name 'Fixture'

                $result = Invoke-TestScriptFile -ScriptPath (Join-Path $utilsDir 'verify-file-change-parsing.ps1')
            }
            finally {
                Pop-Location
            }

            $result.ExitCode | Should -BeIn @(0, 1)
            $result.Output | Should -Match 'FragmentCacheInitialization module not found'
        }
        finally {
            if (Test-Path -LiteralPath $repo) {
                Remove-Item -LiteralPath $repo -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }

    It 'Completes file change parsing verification when fragment cache modules are available' {
        if (-not (Test-Path -LiteralPath $script:CacheInitModule)) {
            Set-ItResult -Skipped -Because 'FragmentCacheInitialization module is not present'
            return
        }

        $repo = New-TestTempDirectory -Prefix 'VerifyFileChangePass'
        try {
            $utilsDir = Join-Path $repo 'scripts' 'utils'
            $null = New-Item -ItemType Directory -Path $utilsDir -Force
            Copy-Item -LiteralPath (Join-Path $script:TestRepoRoot 'scripts' 'lib') -Destination (Join-Path $repo 'scripts' 'lib') -Recurse -Force
            Copy-Item -LiteralPath $script:VerifyFileChangeParsingScript -Destination (Join-Path $utilsDir 'verify-file-change-parsing.ps1') -Force

            Push-Location $repo
            try {
                git init -q | Out-Null
                git config user.email 'fixture@example.com'
                git config user.name 'Fixture'

                $result = Invoke-TestScriptFile -ScriptPath (Join-Path $utilsDir 'verify-file-change-parsing.ps1')
            }
            finally {
                Pop-Location
            }

            $result.ExitCode | Should -Be 0
            $result.Output | Should -Match 'File Change Parsing Verification'
            $result.Output | Should -Match 'Verification Complete'
        }
        finally {
            if (Test-Path -LiteralPath $repo) {
                Remove-Item -LiteralPath $repo -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }
}
