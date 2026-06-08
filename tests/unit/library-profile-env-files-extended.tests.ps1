<#
tests/unit/library-profile-env-files-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for Initialize-ProfileEnvFiles stub loading behavior.
#>

BeforeAll {
    . (Join-Path $PSScriptRoot '..\TestSupport.ps1')

    Import-Module (Join-Path $PSScriptRoot '../../scripts/lib/profile/ProfileEnvFiles.psm1') -DisableNameChecking -Force -Global

    $script:TempDir = New-TestTempDirectory -Prefix 'ProfileEnvFilesExtended'
    $script:StubUtilitiesDir = Join-Path $script:TempDir 'scripts/lib/utilities'
    New-Item -ItemType Directory -Path $script:StubUtilitiesDir -Force | Out-Null
}

AfterAll {
    Remove-Item Env:\PS_PROFILE_DEBUG -ErrorAction SilentlyContinue
    Remove-Item Env:\TEST_PROFILE_ENV_OVERWRITE -ErrorAction SilentlyContinue

    if ($script:TempDir -and (Test-Path -LiteralPath $script:TempDir)) {
        Remove-Item -LiteralPath $script:TempDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Describe 'ProfileEnvFiles extended scenarios' {
    BeforeEach {
        Clear-TestStartProcessCapture
        Remove-Item Env:\TEST_PROFILE_ENV_OVERWRITE -ErrorAction SilentlyContinue
        Remove-Item Env:\TEST_PROFILE_ENV_NO_DOTENV -ErrorAction SilentlyContinue
        Get-Module -Name EnvFile -ErrorAction SilentlyContinue | ForEach-Object {
            Remove-Module $_.Name -Force -ErrorAction SilentlyContinue
        }
    }

    function script:Install-EnvFileStub {
        param(
            [string]$Content
        )

        Set-Content -LiteralPath (Join-Path $script:StubUtilitiesDir 'EnvFile.psm1') -Value $Content -Encoding UTF8
        Import-Module (Join-Path $script:StubUtilitiesDir 'EnvFile.psm1') -Force -ErrorAction Stop
    }

    AfterEach {
        Get-TestStartProcessCapture | Should -BeNullOrEmpty
    }

    Context 'Initialize-ProfileEnvFiles' {
        It 'Always passes Overwrite to Initialize-EnvFiles when the stub module is loaded' {
            Install-EnvFileStub @'
function Initialize-EnvFiles {
    [CmdletBinding()]
    param(
        [string]$RepoRoot,
        [switch]$Overwrite
    )

    if ($Overwrite) {
        Set-Item -Path 'Env:TEST_PROFILE_ENV_OVERWRITE' -Value 'yes' -Force
    }
}
Export-ModuleMember -Function Initialize-EnvFiles
'@

            Initialize-ProfileEnvFiles -ProfileDir $script:TempDir

            $env:TEST_PROFILE_ENV_OVERWRITE | Should -Be 'yes'
        }

        It 'Loads the stub module even when no dotenv files exist' {
            Install-EnvFileStub @'
function Initialize-EnvFiles {
    Set-Item -Path 'Env:TEST_PROFILE_ENV_NO_DOTENV' -Value 'loaded-without-dotenv' -Force
}
Export-ModuleMember -Function Initialize-EnvFiles
'@

            Initialize-ProfileEnvFiles -ProfileDir $script:TempDir

            $env:TEST_PROFILE_ENV_NO_DOTENV | Should -Be 'loaded-without-dotenv'
        }

        It 'Does not launch external processes while loading env files' {
            Install-EnvFileStub @'
function Initialize-EnvFiles { }
Export-ModuleMember -Function Initialize-EnvFiles
'@

            { Initialize-ProfileEnvFiles -ProfileDir $script:TempDir } | Should -Not -Throw
        }
    }
}
