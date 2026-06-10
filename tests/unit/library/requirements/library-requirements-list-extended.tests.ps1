<#
tests/unit/library-requirements-list-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for RequirementsList parsing and install command helpers.
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

        It 'Loads apt packages from the linux requirements manifest' {
            $repoRoot = Join-Path $script:TempRoot 'linux-apt-repo'
            $linuxFile = Join-Path $repoRoot 'requirements' 'linux.txt'
            New-Item -ItemType Directory -Path (Split-Path $linuxFile) -Force | Out-Null
            @'
# --- apt
fd-find
jq

# --- pacman
fd

# --- dnf
gh
'@ | Set-Content -LiteralPath $linuxFile -Encoding UTF8

            $packages = @(Get-SystemRequirementsPackages -RepoRoot $repoRoot -PackageManager 'apt')

            $packages | Should -Contain 'fd-find'
            $packages | Should -Contain 'jq'
            $packages | Should -Not -Contain 'fd'
        }

        It 'Loads pacman packages from the linux requirements manifest' {
            $repoRoot = Join-Path $script:TempRoot 'linux-pacman-repo'
            $linuxFile = Join-Path $repoRoot 'requirements' 'linux.txt'
            New-Item -ItemType Directory -Path (Split-Path $linuxFile) -Force | Out-Null
            @'
# --- apt
fd-find

# --- pacman
fd
github-cli

# --- dnf
gh
'@ | Set-Content -LiteralPath $linuxFile -Encoding UTF8

            $packages = @(Get-SystemRequirementsPackages -RepoRoot $repoRoot -PackageManager 'pacman')

            $packages | Should -Contain 'fd'
            $packages | Should -Contain 'github-cli'
        }

        It 'Returns an empty array for unsupported package managers' {
            $packages = @(Get-SystemRequirementsPackages -RepoRoot $script:TempRoot -PackageManager 'winget')
            @($packages).Count | Should -Be 0
        }
    }

    Context 'Get-SystemPackageManagerKind' {
        AfterEach {
            Remove-Item Env:PS_SYSTEM_PACKAGE_MANAGER -ErrorAction SilentlyContinue
            if (Get-Command Clear-CommandTestStubs -ErrorAction SilentlyContinue) {
                Clear-CommandTestStubs
            }
        }

        It 'Honors PS_SYSTEM_PACKAGE_MANAGER when the command exists' {
            Setup-CapturingCommandMock -CommandName 'apt-get' -Output ''
            $env:PS_SYSTEM_PACKAGE_MANAGER = 'apt'

            Get-SystemPackageManagerKind | Should -Be 'apt'
        }

        It 'Returns null when the preferred package manager command is unavailable' {
            $env:PS_SYSTEM_PACKAGE_MANAGER = 'zypper'
            Remove-TestFunction -Name @('zypper')

            Get-SystemPackageManagerKind | Should -BeNullOrEmpty
        }

        It 'Detects scoop when scoop is available on PATH' {
            Setup-CapturingCommandMock -CommandName 'scoop' -Output 'scoop help'
            $env:PS_SYSTEM_PACKAGE_MANAGER = 'scoop'

            Get-SystemPackageManagerKind | Should -Be 'scoop'
        }

        It 'Detects dnf when yum is available on PATH' {
            Setup-CapturingCommandMock -CommandName 'yum' -Output 'yum help'
            $env:PS_SYSTEM_PACKAGE_MANAGER = 'yum'

            Get-SystemPackageManagerKind | Should -Be 'dnf'
        }
    }

    Context 'Get-SystemRequirementsPackages dnf section' {
        It 'Loads dnf packages from the linux requirements manifest' {
            $repoRoot = Join-Path $script:TempRoot 'linux-dnf-repo'
            $linuxFile = Join-Path $repoRoot 'requirements' 'linux.txt'
            New-Item -ItemType Directory -Path (Split-Path $linuxFile) -Force | Out-Null
            @'
# --- apt
fd-find

# --- pacman
fd

# --- dnf
gh
curl
'@ | Set-Content -LiteralPath $linuxFile -Encoding UTF8

            $packages = @(Get-SystemRequirementsPackages -RepoRoot $repoRoot -PackageManager 'dnf')

            $packages | Should -Contain 'gh'
            $packages | Should -Contain 'curl'
        }
    }

    Context 'Missing manifest files' {
        It 'Throws when python requirements file is missing' {
            $missing = Join-Path $script:TempRoot 'missing-python.txt'
            { Get-PythonRequirementsFromFile -Path $missing } | Should -Throw '*Requirements file not found*'
        }

        It 'Throws when linux requirements file is missing' {
            $missing = Join-Path $script:TempRoot 'missing-linux.txt'
            { Get-LinuxRequirementsFromFile -Path $missing -Section 'apt' } | Should -Throw '*Requirements file not found*'
        }

        It 'Throws when package.json is missing' {
            $missing = Join-Path $script:TempRoot 'missing-package.json'
            { Get-NpmRequirementsFromPackageJson -Path $missing } | Should -Throw '*package.json not found*'
        }
    }

    Context 'Get-SystemPackageInstallCommand edge cases' {
        It 'Returns an empty string when no package names are provided' {
            Get-SystemPackageInstallCommand -PackageNames @() -PackageManager 'apt' | Should -Be ''
        }
    }

    Context 'Get-SystemRequirementsPackages auto detection' {
        AfterEach {
            Remove-Item Env:PS_SYSTEM_PACKAGE_MANAGER -ErrorAction SilentlyContinue
            if (Get-Command Clear-CommandTestStubs -ErrorAction SilentlyContinue) {
                Clear-CommandTestStubs
            }
        }

        It 'Loads scoop packages when scoop is the detected package manager' {
            Setup-CapturingCommandMock -CommandName 'scoop' -Output 'scoop help'
            $env:PS_SYSTEM_PACKAGE_MANAGER = 'scoop'

            $repoRoot = Join-Path $script:TempRoot 'auto-scoop-repo'
            $scoopFile = Join-Path $repoRoot 'requirements' 'scoop.txt'
            New-Item -ItemType Directory -Path (Split-Path $scoopFile) -Force | Out-Null
            Set-Content -LiteralPath $scoopFile -Value "bat`nfd" -Encoding UTF8

            $packages = @(Get-SystemRequirementsPackages -RepoRoot $repoRoot)

            $packages | Should -Contain 'bat'
            $packages | Should -Contain 'fd'
        }
    }
}
