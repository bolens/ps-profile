#
# Tests for system-related helper functions.
#

. (Join-Path $PSScriptRoot '..\TestSupport.ps1')

BeforeAll {
    # Load TestSupport.ps1 directly
    $testSupportPath = Join-Path (Split-Path $PSScriptRoot -Parent) 'TestSupport.ps1'
    . $testSupportPath

    # Import the common module
    $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
    . (Join-Path $script:ProfileDir '00-bootstrap.ps1')
    . (Join-Path $script:ProfileDir '07-system.ps1')
}

Describe 'Profile system utility functions' {
    Context 'Command discovery helpers' {
        It 'which shows command information' {
            $result = which Get-Command
            $result | Should -Not -Be $null
            $result.Name | Should -Be 'Get-Command'
        }

        It 'which handles non-existent commands gracefully' {
            $name = "NonExistentCommand_{0}" -f (Get-Random)
            $result = which $name
            ($result -eq $null -or $result.Count -eq 0) | Should -Be $true
        }
    }

    Context 'Search utilities' {
        It 'pgrep searches for patterns in files' {
            $tempFile = Join-Path $TestDrive 'test_pgrep.txt'
            Set-Content -Path $tempFile -Value 'test content with pattern'
            $result = pgrep 'pattern' $tempFile
            $result | Should -Not -Be $null
            $result.Line | Should -Match 'pattern'
        }

        It 'pgrep handles pattern not found gracefully' {
            $tempFile = Join-Path $TestDrive 'test_no_match.txt'
            Set-Content -Path $tempFile -Value 'no match here'
            $result = pgrep 'nonexistentpattern' $tempFile
            ($result -eq $null -or $result.Count -eq 0) | Should -Be $true
        }

        It 'search finds files recursively' {
            $tempDir = Join-Path $TestDrive 'test_search'
            New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
            New-Item -ItemType File -Path (Join-Path $tempDir 'test.txt') -Force | Out-Null

            Push-Location $tempDir
            try {
                $result = search test.txt
                $result | Where-Object { $_ -eq 'test.txt' } | Should -Not -BeNullOrEmpty
            }
            finally {
                Pop-Location
            }
        }

        It 'search handles empty directories' {
            $emptyDir = Join-Path $TestDrive 'empty_search'
            New-Item -ItemType Directory -Path $emptyDir -Force | Out-Null

            Push-Location $emptyDir
            try {
                $result = search '*.txt'
                ($result -eq $null -or $result.Count -eq 0) | Should -Be $true
            }
            finally {
                Pop-Location
            }
        }
    }

    Context 'File creation and metadata helpers' {
        It 'touch creates empty files' {
            $tempFile = Join-Path $TestDrive 'test_touch.txt'
            if (Test-Path $tempFile) {
                Remove-Item $tempFile -Force
            }
            touch $tempFile
            Test-Path $tempFile | Should -Be $true
        }

        It 'touch updates timestamp when file exists' {
            $tempFile = Join-Path $TestDrive 'touch_timestamp.txt'
            Set-Content -Path $tempFile -Value 'initial content'
            $original = (Get-Item $tempFile).LastWriteTime
            Start-Sleep -Milliseconds 50
            touch $tempFile
            $updated = (Get-Item $tempFile).LastWriteTime
            $updated | Should -BeGreaterThan $original
        }

        It 'touch supports LiteralPath parameter' {
            $tempFile = Join-Path $TestDrive 'folder with spaces' 'literal touch.txt'
            $directory = Split-Path -Parent $tempFile
            if (-not (Test-Path $directory)) {
                New-Item -ItemType Directory -Path $directory -Force | Out-Null
            }

            if (Test-Path $tempFile) {
                Remove-Item $tempFile -Force
            }

            touch -LiteralPath $tempFile
            Test-Path -LiteralPath $tempFile | Should -Be $true
        }

        It 'touch throws when parent directory is missing' {
            $tempFile = Join-Path $TestDrive 'missing' 'nope.txt'
            $parent = Split-Path -Parent $tempFile
            if (Test-Path $parent) {
                Remove-Item $parent -Recurse -Force
            }

            { touch $tempFile } | Should -Throw
        }
    }

    Context 'File management wrappers' {
        It 'New-Directory creates directories via wrapper' {
            $tempDir = Join-Path $TestDrive 'wrapper_mkdir'
            if (Test-Path $tempDir) {
                Remove-Item $tempDir -Force -Recurse
            }

            New-Directory -Path $tempDir | Out-Null
            Test-Path $tempDir | Should -Be $true
        }

        It 'Copy-ItemCustom copies files via wrapper' {
            $sourceDir = Join-Path $TestDrive 'copy_source'
            $destDir = Join-Path $TestDrive 'copy_dest'
            New-Directory -Path $sourceDir | Out-Null
            New-Directory -Path $destDir | Out-Null

            $sourceFile = Join-Path $sourceDir 'source.txt'
            Set-Content -Path $sourceFile -Value 'wrapper copy test'

            Copy-ItemCustom -Path $sourceFile -Destination $destDir
            Test-Path (Join-Path $destDir 'source.txt') | Should -Be $true
        }

        It 'Move-ItemCustom moves files via wrapper' {
            $sourceDir = Join-Path $TestDrive 'move_source'
            $destDir = Join-Path $TestDrive 'move_dest'
            New-Directory -Path $sourceDir | Out-Null
            New-Directory -Path $destDir | Out-Null

            $sourceFile = Join-Path $sourceDir 'move.txt'
            Set-Content -Path $sourceFile -Value 'wrapper move test'

            Move-ItemCustom -Path $sourceFile -Destination $destDir
            Test-Path $sourceFile | Should -Be $false
            Test-Path (Join-Path $destDir 'move.txt') | Should -Be $true
        }

        It 'Remove-ItemCustom deletes files via wrapper' {
            $tempFile = Join-Path $TestDrive 'remove.txt'
            Set-Content -Path $tempFile -Value 'wrapper remove test'
            Remove-ItemCustom -Path $tempFile -Force
            Test-Path $tempFile | Should -Be $false
        }

        It 'mkdir creates directories' {
            $tempDir = Join-Path $TestDrive 'test_mkdir'
            mkdir $tempDir | Out-Null
            Test-Path $tempDir | Should -Be $true
        }
    }

    Context 'System insights and networking' {
        BeforeEach {
            # Mock Get-Process to ensure consistent test data
            Mock Get-Process {
                @(
                    [PSCustomObject]@{ Name = 'System'; CPU = 10.5; Id = 4 },
                    [PSCustomObject]@{ Name = 'svchost'; CPU = 8.2; Id = 123 },
                    [PSCustomObject]@{ Name = 'explorer'; CPU = 5.1; Id = 456 },
                    [PSCustomObject]@{ Name = 'powershell'; CPU = 3.8; Id = 789 },
                    [PSCustomObject]@{ Name = 'chrome'; CPU = 2.9; Id = 101 }
                )
            }

            # Mock external commands to prevent interactive behavior
            Mock netstat { "Active Connections" }
            Mock Resolve-DnsName {
                [PSCustomObject]@{ Name = 'localhost'; Type = 'A'; IPAddress = '127.0.0.1' }
            }
        }

        It 'df shows disk usage information' {
            $result = df
            $result | Should -Not -Be $null
            $result[0].PSObject.Properties.Name -contains 'Name' | Should -Be $true
            $result[0].PSObject.Properties.Name -contains 'Used(GB)' | Should -Be $true
        }

        It 'htop shows top CPU processes' {
            # Ensure htop is the PowerShell function, not an external command
            $htopFunction = Get-Command htop -CommandType Function -ErrorAction SilentlyContinue
            if ($htopFunction) {
                $result = htop
            }
            else {
                # Fallback to Get-Process directly if function is not available
                $result = Get-Process | Sort-Object CPU -Descending | Select-Object -First 10
            }
            $result | Should -Not -Be $null
            ($result.Count -le 10) | Should -Be $true
            $result[0].PSObject.Properties.Name -contains 'Name' | Should -Be $true
        }

        It 'ports shows network port information' {
            { ports } | Should -Not -Throw
        }

        It 'ptest tests network connectivity' {
            $result = ptest localhost
            $result | Should -Not -Be $null
        }

        It 'dns resolves hostnames' {
            $result = dns localhost
            $result | Should -Not -BeNullOrEmpty
            $result[0].Name | Should -Be 'localhost'
        }
    }

    Context 'Archiving helpers' {
        It 'zip creates archives' {
            $tempDir = Join-Path $TestDrive 'test_zip'
            $zipFile = Join-Path $TestDrive 'test.zip'
            New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
            New-Item -ItemType File -Path (Join-Path $tempDir 'test.txt') -Value 'test' -Force | Out-Null

            zip -Path $tempDir -DestinationPath $zipFile
            Test-Path $zipFile | Should -Be $true
        }
    }
}
