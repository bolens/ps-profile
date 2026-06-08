<#
tests/unit/library-common-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for shared library helpers formerly grouped under Common.
#>

BeforeAll {
    . (Join-Path $PSScriptRoot '..\TestSupport.ps1')

    $libPath = Get-TestPath -RelativePath 'scripts\lib' -StartPath $PSScriptRoot -EnsureExists
    Import-Module (Join-Path $libPath 'path' 'PathResolution.psm1') -DisableNameChecking -ErrorAction Stop
    Import-Module (Join-Path $libPath 'file' 'FileSystem.psm1') -DisableNameChecking -ErrorAction Stop
    Import-Module (Join-Path $libPath 'path' 'PathValidation.psm1') -DisableNameChecking -ErrorAction Stop
    Import-Module (Join-Path $libPath 'utilities' 'Command.psm1') -DisableNameChecking -ErrorAction Stop
    Import-Module (Join-Path $libPath 'runtime' 'PowerShellDetection.psm1') -DisableNameChecking -ErrorAction Stop

    $platformPathsModule = Join-Path $libPath 'core' 'PlatformPaths.psm1'
    if (Test-Path -LiteralPath $platformPathsModule) {
        Import-Module $platformPathsModule -DisableNameChecking -ErrorAction Stop
        $script:TestTempRoot = Get-TempDirectory
    }
    else {
        $script:TestTempRoot = New-TestTempDirectory -Prefix 'LibraryCommonExtended'
    }
}

AfterAll {
    if ($script:TestTempRoot -and (Test-Path -LiteralPath $script:TestTempRoot)) {
        Remove-Item -LiteralPath $script:TestTempRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Describe 'Common library helpers extended scenarios' {
    Context 'Get-RepoRoot' {
        It 'Resolves repository root from scripts utility paths' {
            $utilityScript = Get-TestPath -RelativePath 'scripts\utils\code-quality\run-pester.ps1' -StartPath $PSScriptRoot -EnsureExists
            $repoRoot = Get-RepoRoot -ScriptPath $utilityScript

            Test-Path -LiteralPath (Join-Path $repoRoot 'profile.d') | Should -Be $true
            Test-Path -LiteralPath (Join-Path $repoRoot 'scripts') | Should -Be $true
        }
    }

    Context 'Resolve-DefaultPath' {
        It 'Returns the provided path when it already exists' {
            $existingDir = New-TestTempDirectory -Prefix 'ResolveDefaultExisting'
            Resolve-DefaultPath -Path $existingDir -DefaultPath (Join-Path $script:TestTempRoot 'fallback') |
                Should -Be $existingDir
        }
    }

    Context 'Test-PathExists' {
        It 'Throws a descriptive error when the path does not exist' {
            $missingPath = Join-Path $script:TestTempRoot "missing-$([guid]::NewGuid())"
            { Test-PathExists -Path $missingPath } | Should -Throw '*not found*'
        }
    }

    Context 'Test-CommandAvailable' {
        It 'Treats command names case-insensitively' {
            Test-CommandAvailable -CommandName 'GET-COMMAND' | Should -Be $true
        }
    }

    Context 'Get-PowerShellExecutable' {
        It 'Returns pwsh on PowerShell 7 and later hosts' {
            if ($PSVersionTable.PSVersion.Major -ge 7) {
                Get-PowerShellExecutable | Should -Be 'pwsh'
            }
            else {
                Set-ItResult -Inconclusive -Because 'Host is not PowerShell 7+'
            }
        }
    }
}
