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
    $script:RepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:RequirementsListPath = Get-TestPath -RelativePath 'scripts\lib\utilities\RequirementsList.psm1' -StartPath $PSScriptRoot -EnsureExists
    Import-Module $script:RequirementsListPath -DisableNameChecking -ErrorAction Stop -Force
    $script:TestTempRoot = New-TestTempDirectory -Prefix 'RequirementsListTests'
}

AfterAll {
    Remove-Module RequirementsList -ErrorAction SilentlyContinue -Force
}

Describe 'RequirementsList module' {
    Context 'Get-RequirementsManifestPath' {
        It 'Resolves manifest paths under repo root' {
            Get-RequirementsManifestPath -RepoRoot $script:RepoRoot -Kind 'python' |
                Should -Be (Join-Path $script:RepoRoot 'requirements.txt')
            Get-RequirementsManifestPath -RepoRoot $script:RepoRoot -Kind 'scoop' |
                Should -Be (Join-Path $script:RepoRoot 'requirements' 'scoop.txt')
            Get-RequirementsManifestPath -RepoRoot $script:RepoRoot -Kind 'linux' |
                Should -Be (Join-Path $script:RepoRoot 'requirements' 'linux.txt')
        }
    }

    Context 'Get-PythonRequirementsFromFile' {
        It 'Parses package names and strips version specifiers' {
            $file = Join-Path $script:TestTempRoot 'requirements.txt'
            @'
# comment
h5py>=3.11.0
numpy>=2.0.0
'@ | Set-Content -Path $file -Encoding UTF8

            $result = Get-PythonRequirementsFromFile -Path $file
            $result | Should -Contain 'h5py'
            $result | Should -Contain 'numpy'
            @($result).Count | Should -Be 2
        }
    }

    Context 'Get-LinuxRequirementsFromFile' {
        It 'Returns only packages from the requested section' {
            $file = Get-RequirementsManifestPath -RepoRoot $script:RepoRoot -Kind 'linux'
            if (-not (Test-Path -LiteralPath $file)) {
                Set-ItResult -Skipped -Because 'requirements/linux.txt not found'
                return
            }

            $apt = Get-LinuxRequirementsFromFile -Path $file -Section 'apt'
            $pacman = Get-LinuxRequirementsFromFile -Path $file -Section 'pacman'
            $dnf = Get-LinuxRequirementsFromFile -Path $file -Section 'dnf'

            $apt | Should -Contain 'fd-find'
            $apt | Should -Not -Contain 'fd'

            $pacman | Should -Contain 'fd'
            $pacman | Should -Contain 'github-cli'

            $dnf | Should -Contain 'fd-find'
            $dnf | Should -Contain 'gh'
            $dnf | Should -Not -Contain 'github-cli'
        }
    }

    Context 'Get-RequirementsListFromFile' {
        It 'Loads scoop package names from requirements/scoop.txt' {
            $file = Get-RequirementsManifestPath -RepoRoot $script:RepoRoot -Kind 'scoop'
            if (-not (Test-Path -LiteralPath $file)) {
                Set-ItResult -Skipped -Because 'requirements/scoop.txt not found'
                return
            }

            $result = Get-RequirementsListFromFile -Path $file
            $result | Should -Contain 'bat'
            $result | Should -Contain 'ripgrep'
            @($result | Where-Object { $_ -eq 'imagemagick' }).Count | Should -Be 1
        }
    }

    Context 'Get-SystemPackageInstallCommand' {
        It 'Builds pacman install command' {
            $cmd = Get-SystemPackageInstallCommand -PackageNames @('bat', 'fd') -PackageManager 'pacman'
            $cmd | Should -Be 'sudo pacman -S --needed bat fd'
        }

        It 'Builds dnf install command' {
            $cmd = Get-SystemPackageInstallCommand -PackageNames @('bat') -PackageManager 'dnf'
            $cmd | Should -Be 'sudo dnf install -y bat'
        }
    }
}
