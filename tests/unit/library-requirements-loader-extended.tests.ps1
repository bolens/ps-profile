<#
tests/unit/library-requirements-loader-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for Import-Requirements structure and cache behavior.
#>

BeforeAll {
    . (Join-Path $PSScriptRoot '..\TestSupport.ps1')

    $script:LibPath = Get-TestPath -RelativePath 'scripts\lib' -StartPath $PSScriptRoot -EnsureExists
    Import-Module (Join-Path $script:LibPath 'utilities' 'Cache.psm1') -DisableNameChecking -Force -ErrorAction SilentlyContinue
    Import-Module (Join-Path $script:LibPath 'utilities' 'DataFile.psm1') -DisableNameChecking -Force -ErrorAction SilentlyContinue
    Import-Module (Join-Path $script:LibPath 'utilities' 'RequirementsLoader.psm1') -DisableNameChecking -Force

    $script:TempDir = New-TestTempDirectory -Prefix 'RequirementsLoaderExtended'
}

AfterAll {
    Remove-Module RequirementsLoader, DataFile, Cache -ErrorAction SilentlyContinue -Force

    if ($script:TempDir -and (Test-Path -LiteralPath $script:TempDir)) {
        Remove-Item -LiteralPath $script:TempDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Describe 'RequirementsLoader extended scenarios' {
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
    }
}
