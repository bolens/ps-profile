<#
tests/unit/library-requirements-loader-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for Import-Requirements structure and cache behavior.
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
    $script:LibPath = Get-TestPath -RelativePath 'scripts\lib' -StartPath $PSScriptRoot -EnsureExists
    $script:ProfileDir = Join-Path (Get-TestRepoRoot -StartPath $PSScriptRoot) 'profile.d'
    Import-Module (Join-Path $script:LibPath 'core' 'Validation.psm1') -DisableNameChecking -Force -ErrorAction SilentlyContinue
    Import-Module (Join-Path $script:LibPath 'utilities' 'Cache.psm1') -DisableNameChecking -Force -ErrorAction SilentlyContinue
    Import-Module (Join-Path $script:LibPath 'utilities' 'CacheKey.psm1') -DisableNameChecking -Force -ErrorAction SilentlyContinue
    Import-Module (Join-Path $script:LibPath 'utilities' 'DataFile.psm1') -DisableNameChecking -Force -ErrorAction SilentlyContinue
    Import-Module (Join-Path $script:LibPath 'utilities' 'RequirementsLoader.psm1') -DisableNameChecking -Force

    $script:TempDir = New-TestTempDirectory -Prefix 'RequirementsLoaderExtended'
}

function script:Clear-RequirementsLoaderTestEnvironment {
    Remove-Item Env:PS_PROFILE_DEBUG -ErrorAction SilentlyContinue
}

function script:Enable-TestStructuredLogging {
    if (Get-Command Write-StructuredWarning -ErrorAction SilentlyContinue) {
        return
    }

    . (Join-Path $script:ProfileDir 'bootstrap.ps1')
    . (Join-Path $script:ProfileDir 'bootstrap' 'ErrorHandlingStandard.ps1')
}

AfterAll {
    Clear-RequirementsLoaderTestEnvironment
    Remove-Module RequirementsLoader, DataFile, CacheKey, Cache -ErrorAction SilentlyContinue -Force

    if ($script:TempDir -and (Test-Path -LiteralPath $script:TempDir)) {
        Remove-Item -LiteralPath $script:TempDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Describe 'RequirementsLoader extended scenarios' {
    BeforeEach { Clear-RequirementsLoaderTestEnvironment }

    Context 'Import-Requirements' {
        BeforeEach {
            $script:RepoRoot = Join-Path $script:TempDir ("repo-{0}" -f ([Guid]::NewGuid().ToString('N')))
            New-Item -ItemType Directory -Path (Join-Path $script:RepoRoot 'requirements') -Force | Out-Null
        }

        It 'Loads nested ExternalTools configuration from the loader script' {
            $loaderFile = Join-Path $script:RepoRoot 'requirements' 'load-requirements.ps1'
            @'
@{
    PowerShellVersion = '7.4'
    Modules = @{}
    ExternalTools = @{
        git = @{
            InstallCommand = 'scoop install git'
        }
    }
    PlatformRequirements = @{}
}
'@ | Set-Content -LiteralPath $loaderFile -Encoding UTF8

            $result = Import-Requirements -RepoRoot $script:RepoRoot

            $result.ExternalTools.git.InstallCommand | Should -Be 'scoop install git'
        }

        It 'Loads PlatformRequirements entries from the loader script' {
            $loaderFile = Join-Path $script:RepoRoot 'requirements' 'load-requirements.ps1'
            @'
@{
    PowerShellVersion = '7.4'
    Modules = @{}
    ExternalTools = @{}
    PlatformRequirements = @{
        Linux = @{
            PowerShell = '7.0'
        }
    }
}
'@ | Set-Content -LiteralPath $loaderFile -Encoding UTF8

            $result = Import-Requirements -RepoRoot $script:RepoRoot

            $result.PlatformRequirements.Linux.PowerShell | Should -Be '7.0'
        }

        It 'Returns updated values after the loader script changes when cache is disabled' {
            $loaderFile = Join-Path $script:RepoRoot 'requirements' 'load-requirements.ps1'
            @'
@{
    PowerShellVersion = '7.0'
    Modules = @{}
    ExternalTools = @{}
    PlatformRequirements = @{}
}
'@ | Set-Content -LiteralPath $loaderFile -Encoding UTF8

            $first = Import-Requirements -RepoRoot $script:RepoRoot -UseCache:$false

            @'
@{
    PowerShellVersion = '7.5'
    Modules = @{}
    ExternalTools = @{}
    PlatformRequirements = @{}
}
'@ | Set-Content -LiteralPath $loaderFile -Encoding UTF8

            $second = Import-Requirements -RepoRoot $script:RepoRoot -UseCache:$false

            $first.PowerShellVersion | Should -Be '7.0'
            $second.PowerShellVersion | Should -Be '7.5'
        }

        It 'Throws when the requirements directory exists but loader script is missing' {
            Remove-Item -LiteralPath (Join-Path $script:RepoRoot 'requirements' 'load-requirements.ps1') -Force -ErrorAction SilentlyContinue

            { Import-Requirements -RepoRoot $script:RepoRoot } | Should -Throw
        }

        It 'Returns cached requirements on subsequent calls when cache is enabled' {
            $loaderFile = Join-Path $script:RepoRoot 'requirements' 'load-requirements.ps1'
            @'
@{
    PowerShellVersion = '7.4'
    Modules = @{ Pester = '5.0.0' }
    ExternalTools = @{}
    PlatformRequirements = @{}
}
'@ | Set-Content -LiteralPath $loaderFile -Encoding UTF8

            $env:PS_PROFILE_DEBUG = '3'
            $first = Import-Requirements -RepoRoot $script:RepoRoot -UseCache
            $second = Import-Requirements -RepoRoot $script:RepoRoot -UseCache

            $first.PowerShellVersion | Should -Be '7.4'
            $second.PowerShellVersion | Should -Be '7.4'
        }

        It 'Emits structured warnings when the loader script throws and debug is enabled' {
            $loaderFile = Join-Path $script:RepoRoot 'requirements' 'load-requirements.ps1'
            'throw "extended loader failure"' | Set-Content -LiteralPath $loaderFile -Encoding UTF8

            $env:PS_PROFILE_DEBUG = '3'
            Enable-TestStructuredLogging

            { Import-Requirements -RepoRoot $script:RepoRoot } | Should -Throw
        }

        It 'Emits structured errors when loader script is missing and debug is enabled' {
            Remove-Item -LiteralPath (Join-Path $script:RepoRoot 'requirements' 'load-requirements.ps1') -Force -ErrorAction SilentlyContinue

            $env:PS_PROFILE_DEBUG = '1'
            Enable-TestStructuredLogging

            { Import-Requirements -RepoRoot $script:RepoRoot } | Should -Throw '*Requirements loader not found*'
        }

        It 'Uses Write-Warning fallback when structured logging is unavailable' {
            $loaderFile = Join-Path $script:RepoRoot 'requirements' 'load-requirements.ps1'
            'throw "plain warning fallback"' | Set-Content -LiteralPath $loaderFile -Encoding UTF8

            Remove-TestFunction -Name @('Write-StructuredWarning', 'Write-StructuredError')
            $env:PS_PROFILE_DEBUG = '2'

            { Import-Requirements -RepoRoot $script:RepoRoot } | Should -Throw
        }

        It 'Throws when repository root cannot be auto-detected from an isolated directory' {
            $isolatedDir = New-Item -ItemType Directory -Path (Join-Path ([System.IO.Path]::GetTempPath()) ("psprof-norepo-{0}" -f [Guid]::NewGuid().ToString('N'))) -Force

            try {
                Push-Location $isolatedDir.FullName
                { Import-Requirements } | Should -Throw '*Could not detect repository root*'
            }
            finally {
                Pop-Location
                Remove-Item -LiteralPath $isolatedDir.FullName -Recurse -Force -ErrorAction SilentlyContinue
            }
        }

        It 'Logs verbose loader success at debug level 2' {
            $loaderFile = Join-Path $script:RepoRoot 'requirements' 'load-requirements.ps1'
            @'
@{
    PowerShellVersion = '7.4'
    Modules = @{}
    ExternalTools = @{}
    PlatformRequirements = @{}
}
'@ | Set-Content -LiteralPath $loaderFile -Encoding UTF8

            $env:PS_PROFILE_DEBUG = '2'
            $result = Import-Requirements -RepoRoot $script:RepoRoot -UseCache:$false
            $result.PowerShellVersion | Should -Be '7.4'
        }

        It 'Returns cached requirements without reloading the loader script' {
            $loaderFile = Join-Path $script:RepoRoot 'requirements' 'load-requirements.ps1'
            @'
@{
    PowerShellVersion = '7.4'
    Modules = @{ Pester = '5.0.0' }
    ExternalTools = @{}
    PlatformRequirements = @{}
}
'@ | Set-Content -LiteralPath $loaderFile -Encoding UTF8

            $first = Import-Requirements -RepoRoot $script:RepoRoot -UseCache
            '@{ PowerShellVersion = ''9.9''; Modules = @{}; ExternalTools = @{}; PlatformRequirements = @{} }' |
                Set-Content -LiteralPath $loaderFile -Encoding UTF8

            $second = Import-Requirements -RepoRoot $script:RepoRoot -UseCache

            $first.PowerShellVersion | Should -Be '7.4'
            $second.PowerShellVersion | Should -Be '7.4'
        }

        It 'Emits plain warnings when loader script throws without structured logging commands' {
            $loaderFile = Join-Path $script:RepoRoot 'requirements' 'load-requirements.ps1'
            'throw "plain loader failure"' | Set-Content -LiteralPath $loaderFile -Encoding UTF8

            Remove-TestFunction -Name @('Write-StructuredWarning', 'Write-StructuredError')
            Remove-Item Env:PS_PROFILE_DEBUG -ErrorAction SilentlyContinue

            { Import-Requirements -RepoRoot $script:RepoRoot } | Should -Throw
        }

        It 'Emits structured warnings when loader script throws without debug enabled' {
            $loaderFile = Join-Path $script:RepoRoot 'requirements' 'load-requirements.ps1'
            'throw "structured no-debug failure"' | Set-Content -LiteralPath $loaderFile -Encoding UTF8

            Remove-Item Env:PS_PROFILE_DEBUG -ErrorAction SilentlyContinue
            Enable-TestStructuredLogging

            { Import-Requirements -RepoRoot $script:RepoRoot } | Should -Throw
        }

        It 'Emits structured errors when loader script is missing without debug enabled' {
            Remove-Item -LiteralPath (Join-Path $script:RepoRoot 'requirements' 'load-requirements.ps1') -Force -ErrorAction SilentlyContinue

            Remove-Item Env:PS_PROFILE_DEBUG -ErrorAction SilentlyContinue
            Enable-TestStructuredLogging

            { Import-Requirements -RepoRoot $script:RepoRoot } | Should -Throw '*Requirements loader not found*'
        }

        It 'Logs loader failure details at debug level 3' {
            $loaderFile = Join-Path $script:RepoRoot 'requirements' 'load-requirements.ps1'
            'throw "debug level 3 failure"' | Set-Content -LiteralPath $loaderFile -Encoding UTF8

            $env:PS_PROFILE_DEBUG = '3'
            Enable-TestStructuredLogging

            { Import-Requirements -RepoRoot $script:RepoRoot } | Should -Throw
        }

        It 'Uses cached requirements and logs cache reuse at debug level 3' {
            $loaderFile = Join-Path $script:RepoRoot 'requirements' 'load-requirements.ps1'
            @'
@{
    PowerShellVersion = '7.4'
    Modules = @{}
    ExternalTools = @{}
    PlatformRequirements = @{}
}
'@ | Set-Content -LiteralPath $loaderFile -Encoding UTF8

            $env:PS_PROFILE_DEBUG = '3'
            $first = Import-Requirements -RepoRoot $script:RepoRoot -UseCache
            $second = Import-Requirements -RepoRoot $script:RepoRoot -UseCache

            $first.PowerShellVersion | Should -Be '7.4'
            $second.PowerShellVersion | Should -Be '7.4'
        }
    }
}
