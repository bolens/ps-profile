<#
tests/unit/library-profile-env-files.tests.ps1

.SYNOPSIS
    Unit tests for ProfileEnvFiles module.
#>

BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1

    $libPath = Join-Path $PSScriptRoot '../../scripts/lib'
    Import-Module (Join-Path $libPath 'profile/ProfileEnvFiles.psm1') -DisableNameChecking -Force -Global

    $script:RepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:TempDir = New-TestTempDirectory -Prefix 'ProfileEnvFilesTests'
    $script:StubUtilitiesDir = Join-Path $script:TempDir 'scripts/lib/utilities'
    New-Item -ItemType Directory -Path $script:StubUtilitiesDir -Force | Out-Null
}

AfterAll {
    Remove-Item Env:\PS_PROFILE_DEBUG -ErrorAction SilentlyContinue
    Remove-Item Env:\TEST_PROFILE_ENV_LOADED -ErrorAction SilentlyContinue

    if ($script:TempDir -and (Test-Path -LiteralPath $script:TempDir)) {
        Remove-Item -LiteralPath $script:TempDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Describe 'ProfileEnvFiles Module' {
    Context 'Initialize-ProfileEnvFiles' {
        BeforeEach {
            Clear-TestStartProcessCapture
        }

        AfterEach {
            Get-TestStartProcessCapture | Should -BeNullOrEmpty
        }

        It 'Does not throw when the EnvFile module is missing' {
            { Initialize-ProfileEnvFiles -ProfileDir $script:TempDir } | Should -Not -Throw
        }

        It 'Invokes Initialize-EnvFiles when a stub module is present' {
            $markerName = 'TEST_PROFILE_ENV_LOADED'
            Remove-Item "Env:\$markerName" -ErrorAction SilentlyContinue

            $stubModule = Join-Path $script:StubUtilitiesDir 'EnvFile.psm1'
            Set-Content -LiteralPath $stubModule -Value @"
function Initialize-EnvFiles {
    [CmdletBinding()]
    param(
        [string]`$RepoRoot,
        [switch]`$Overwrite
    )

    Set-Item -Path 'Env:$markerName' -Value 'stub-loaded' -Force
}
Export-ModuleMember -Function Initialize-EnvFiles
"@ -Encoding UTF8

            Set-Content -LiteralPath (Join-Path $script:TempDir '.env') -Value "$markerName=from-dotenv" -Encoding UTF8

            Initialize-ProfileEnvFiles -ProfileDir $script:TempDir

            $env:TEST_PROFILE_ENV_LOADED | Should -Be 'stub-loaded'
        }

        It 'Loads env files from the repository without opening external applications' {
            { Initialize-ProfileEnvFiles -ProfileDir $script:RepoRoot } | Should -Not -Throw
        }
    }
}
