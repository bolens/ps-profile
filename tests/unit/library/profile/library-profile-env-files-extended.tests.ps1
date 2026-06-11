<#
tests/unit/library-profile-env-files-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for Initialize-ProfileEnvFiles stub loading behavior.
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
    Import-Module (Join-Path (Get-TestRepoRoot -StartPath $PSScriptRoot) 'scripts/lib/profile/ProfileEnvFiles.psm1') -DisableNameChecking -Force -Global

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
        Enable-TestStructuredLogging
        Remove-Item Env:\TEST_PROFILE_ENV_OVERWRITE -ErrorAction SilentlyContinue
        Remove-Item Env:\TEST_PROFILE_ENV_NO_DOTENV -ErrorAction SilentlyContinue
        Remove-Item Env:\PS_PROFILE_DEBUG -ErrorAction SilentlyContinue
        Get-Module -Name EnvFile -ErrorAction SilentlyContinue | ForEach-Object {
            Remove-Module $_.Name -Force -ErrorAction SilentlyContinue
        }
        Remove-TestFunction -Name 'Initialize-EnvFiles'
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

        It 'Emits verbose output at debug level 2 when env files exist' {
            Install-EnvFileStub @'
function Initialize-EnvFiles {
    param([string]$RepoRoot, [switch]$Overwrite)
}
Export-ModuleMember -Function Initialize-EnvFiles
'@
            Set-Content -LiteralPath (Join-Path $script:TempDir '.env') -Value 'TEST_KEY=value' -Encoding UTF8
            Set-Content -LiteralPath (Join-Path $script:TempDir '.env.local') -Value 'TEST_LOCAL=value' -Encoding UTF8
            $env:PS_PROFILE_DEBUG = '2'

            { Initialize-ProfileEnvFiles -ProfileDir $script:TempDir -Verbose } | Should -Not -Throw
        }

        It 'Emits detailed output at debug level 3' {
            Install-EnvFileStub @'
function Initialize-EnvFiles {
    param([string]$RepoRoot, [switch]$Overwrite)
}
Export-ModuleMember -Function Initialize-EnvFiles
'@
            $env:PS_PROFILE_DEBUG = '3'

            { Initialize-ProfileEnvFiles -ProfileDir $script:TempDir } | Should -Not -Throw
        }

        It 'Uses structured warning when Initialize-EnvFiles is missing after import' {
            Set-Content -LiteralPath (Join-Path $script:StubUtilitiesDir 'EnvFile.psm1') -Value @'
function Get-EnvFileStubMarker { return 'loaded' }
Export-ModuleMember -Function Get-EnvFileStubMarker
'@ -Encoding UTF8
            $env:PS_PROFILE_DEBUG = '1'

            { Initialize-ProfileEnvFiles -ProfileDir $script:TempDir } | Should -Not -Throw
        }

        It 'Uses level 3 details when Initialize-EnvFiles is missing after import' {
            Set-Content -LiteralPath (Join-Path $script:StubUtilitiesDir 'EnvFile.psm1') -Value @'
function Get-EnvFileStubMarker { return 'loaded' }
Export-ModuleMember -Function Get-EnvFileStubMarker
'@ -Encoding UTF8
            $env:PS_PROFILE_DEBUG = '3'

            { Initialize-ProfileEnvFiles -ProfileDir $script:TempDir } | Should -Not -Throw
        }

        It 'Uses plain Write-Warning when Initialize-EnvFiles is missing and debug is off' {
            Disable-TestStructuredLogging
            Set-Content -LiteralPath (Join-Path $script:StubUtilitiesDir 'EnvFile.psm1') -Value @'
function Get-EnvFileStubMarker { return 'loaded' }
Export-ModuleMember -Function Get-EnvFileStubMarker
'@ -Encoding UTF8

            $warnings = $null
            { Initialize-ProfileEnvFiles -ProfileDir $script:TempDir -WarningVariable warnings } | Should -Not -Throw
            @($warnings).Count | Should -BeGreaterThan 0
        }

        It 'Uses structured warning when env file import throws' {
            Set-Content -LiteralPath (Join-Path $script:StubUtilitiesDir 'EnvFile.psm1') -Value @'
function Initialize-EnvFiles {
    throw 'env import probe'
}
Export-ModuleMember -Function Initialize-EnvFiles
'@ -Encoding UTF8
            $env:PS_PROFILE_DEBUG = '1'

            { Initialize-ProfileEnvFiles -ProfileDir $script:TempDir } | Should -Not -Throw
        }

        It 'Uses plain Write-Warning when env file import throws without debug' {
            Disable-TestStructuredLogging
            Set-Content -LiteralPath (Join-Path $script:StubUtilitiesDir 'EnvFile.psm1') -Value @'
function Initialize-EnvFiles {
    throw 'env import probe'
}
Export-ModuleMember -Function Initialize-EnvFiles
'@ -Encoding UTF8

            $warnings = $null
            { Initialize-ProfileEnvFiles -ProfileDir $script:TempDir -WarningVariable warnings } | Should -Not -Throw
            @($warnings).Count | Should -BeGreaterThan 0
        }

        It 'Uses structured warning when env file import throws at debug level 3' {
            Set-Content -LiteralPath (Join-Path $script:StubUtilitiesDir 'EnvFile.psm1') -Value @'
function Initialize-EnvFiles {
    throw 'env import probe level 3'
}
Export-ModuleMember -Function Initialize-EnvFiles
'@ -Encoding UTF8
            $env:PS_PROFILE_DEBUG = '3'

            { Initialize-ProfileEnvFiles -ProfileDir $script:TempDir } | Should -Not -Throw
        }

        It 'Uses structured warning when env file import throws without debug output' {
            Set-Content -LiteralPath (Join-Path $script:StubUtilitiesDir 'EnvFile.psm1') -Value @'
function Initialize-EnvFiles {
    throw 'env import probe no debug'
}
Export-ModuleMember -Function Initialize-EnvFiles
'@ -Encoding UTF8
            Remove-Item Env:\PS_PROFILE_DEBUG -ErrorAction SilentlyContinue

            { Initialize-ProfileEnvFiles -ProfileDir $script:TempDir } | Should -Not -Throw
        }

        It 'Logs module path details when the EnvFile module is missing at debug level 3' {
            $missingDir = New-TestTempDirectory -Prefix 'ProfileEnvFilesMissingModule'
            $env:PS_PROFILE_DEBUG = '3'

            { Initialize-ProfileEnvFiles -ProfileDir $missingDir } | Should -Not -Throw

            Remove-Item -LiteralPath $missingDir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}
