<#
tests/unit/library-requirements-list-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for RequirementsList parsing and install command helpers.
#>

BeforeAll {
    . (Join-Path $PSScriptRoot '..\TestSupport.ps1')

    $script:LibPath = Get-TestPath -RelativePath 'scripts\lib' -StartPath $PSScriptRoot -EnsureExists
    Import-Module (Join-Path $script:LibPath 'utilities' 'RequirementsList.psm1') -DisableNameChecking -Force

    $script:TempRoot = New-TestTempDirectory -Prefix 'RequirementsListExtended'
}

AfterAll {
    Remove-Module RequirementsList -ErrorAction SilentlyContinue -Force

    if ($script:TempRoot -and (Test-Path -LiteralPath $script:TempRoot)) {
        Remove-Item -LiteralPath $script:TempRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Describe 'RequirementsList extended scenarios' {
    Context 'Get-RequirementsListFromFile' {
        It 'Deduplicates package names and skips comments' {
            $file = Join-Path $script:TempRoot 'scoop.txt'
            @'
# tools
bat
ripgrep
bat
# --- section marker
fd
'@ | Set-Content -LiteralPath $file -Encoding UTF8

            $packages = @(Get-RequirementsListFromFile -Path $file)

            @($packages).Count | Should -Be 3
            $packages | Should -Contain 'bat'
            $packages | Should -Contain 'ripgrep'
            $packages | Should -Contain 'fd'
        }

        It 'Throws when the requirements file is missing' {
            $missing = Join-Path $script:TempRoot 'missing-scoop.txt'
            { Get-RequirementsListFromFile -Path $missing } | Should -Throw '*Requirements file not found*'
        }
    }

    Context 'Get-NpmRequirementsFromPackageJson' {
        It 'Returns dependency names from package.json' {
            $file = Join-Path $script:TempRoot 'package.json'
            @'
{
  "dependencies": {
    "left-pad": "^1.0.0",
    "lodash": "^4.17.21"
  }
}
'@ | Set-Content -LiteralPath $file -Encoding UTF8

            $packages = @(Get-NpmRequirementsFromPackageJson -Path $file)

            $packages | Should -Contain 'left-pad'
            $packages | Should -Contain 'lodash'
            @($packages).Count | Should -Be 2
        }
    }

    Context 'Get-SystemPackageInstallCommand' {
        It 'Builds apt install commands for multiple packages' {
            $cmd = Get-SystemPackageInstallCommand -PackageNames @('bat', 'fd-find') -PackageManager 'apt'
            $cmd | Should -Be 'sudo apt install -y bat fd-find'
        }

        It 'Builds scoop install commands for multiple packages' {
            $cmd = Get-SystemPackageInstallCommand -PackageNames @('bat', 'fd') -PackageManager 'scoop'
            $cmd | Should -Be 'scoop install bat fd'
        }
    }

    Context 'Get-SystemRequirementsPackages' {
        It 'Loads scoop packages from a temporary repository layout' {
            $repoRoot = Join-Path $script:TempRoot 'fake-repo'
            $scoopFile = Join-Path $repoRoot 'requirements' 'scoop.txt'
            New-Item -ItemType Directory -Path (Split-Path $scoopFile) -Force | Out-Null
            Set-Content -LiteralPath $scoopFile -Value "bat`nfd" -Encoding UTF8

            $packages = @(Get-SystemRequirementsPackages -RepoRoot $repoRoot -PackageManager 'scoop')

            $packages | Should -Contain 'bat'
            $packages | Should -Contain 'fd'
        }

        It 'Returns an empty array for unsupported package managers' {
            $packages = @(Get-SystemRequirementsPackages -RepoRoot $script:TempRoot -PackageManager 'winget')
            @($packages).Count | Should -Be 0
        }
    }
}
