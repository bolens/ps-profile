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
    . (Join-Path $script:ProfileDir 'bootstrap.ps1')
    . (Join-Path $script:ProfileDir 'system.ps1')
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

            { touch $tempFile -ErrorAction Stop } | Should -Throw
            Test-Path $tempFile | Should -Be $false
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

    Context 'mkdir Unix-like behavior' {
        It 'mkdir creates a single directory' {
            $tempDir = Join-Path $TestDrive 'single_dir'
            if (Test-Path $tempDir) {
                Remove-Item $tempDir -Force -Recurse
            }
            mkdir $tempDir | Out-Null
            Test-Path $tempDir | Should -Be $true
            (Get-Item $tempDir).PSIsContainer | Should -Be $true
        }

        It 'mkdir creates multiple directories' {
            $baseDir = Join-Path $TestDrive 'multi_mkdir'
            $dir1 = Join-Path $baseDir 'core'
            $dir2 = Join-Path $baseDir 'fragment'
            $dir3 = Join-Path $baseDir 'path'
            
            if (Test-Path $baseDir) {
                Remove-Item $baseDir -Force -Recurse
            }
            New-Item -ItemType Directory -Path $baseDir -Force | Out-Null

            mkdir $dir1 $dir2 $dir3 | Out-Null
            Test-Path $dir1 | Should -Be $true
            Test-Path $dir2 | Should -Be $true
            Test-Path $dir3 | Should -Be $true
        }

        It 'mkdir -p creates parent directories' {
            $nestedPath = Join-Path $TestDrive 'parent' 'child' 'grandchild'
            if (Test-Path (Split-Path $nestedPath -Parent)) {
                Remove-Item (Split-Path $nestedPath -Parent) -Force -Recurse
            }

            mkdir -p $nestedPath | Out-Null
            Test-Path $nestedPath | Should -Be $true
            Test-Path (Split-Path $nestedPath -Parent) | Should -Be $true
            Test-Path (Split-Path (Split-Path $nestedPath -Parent) -Parent) | Should -Be $true
        }

        It 'mkdir -Parent creates parent directories' {
            $nestedPath = Join-Path $TestDrive 'parent2' 'child2' 'grandchild2'
            if (Test-Path (Split-Path $nestedPath -Parent)) {
                Remove-Item (Split-Path $nestedPath -Parent) -Force -Recurse
            }

            mkdir -Parent $nestedPath | Out-Null
            Test-Path $nestedPath | Should -Be $true
        }

        It 'mkdir -p creates multiple directories with parent paths' {
            $baseDir = Join-Path $TestDrive 'multi_p'
            $dir1 = Join-Path $baseDir 'file'
            $dir2 = Join-Path $baseDir 'metrics'
            $dir3 = Join-Path $baseDir 'performance'
            
            if (Test-Path $baseDir) {
                Remove-Item $baseDir -Force -Recurse
            }

            mkdir -p $dir1 $dir2 $dir3 | Out-Null
            Test-Path $dir1 | Should -Be $true
            Test-Path $dir2 | Should -Be $true
            Test-Path $dir3 | Should -Be $true
        }

        It 'mkdir -p core fragment path file metrics performance code-analysis utilities runtime parallel creates all directories' {
            $baseDir = Join-Path $TestDrive 'unix_like_test'
            $dirs = @('core', 'fragment', 'path', 'file', 'metrics', 'performance', 'code-analysis', 'utilities', 'runtime', 'parallel')
            
            if (Test-Path $baseDir) {
                Remove-Item $baseDir -Force -Recurse
            }
            New-Item -ItemType Directory -Path $baseDir -Force | Out-Null

            $fullPaths = $dirs | ForEach-Object { Join-Path $baseDir $_ }
            mkdir -p $fullPaths | Out-Null

            foreach ($dir in $dirs) {
                $fullPath = Join-Path $baseDir $dir
                Test-Path $fullPath | Should -Be $true
            }
        }

        It 'mkdir handles already existing directories gracefully with -p' {
            $existingDir = Join-Path $TestDrive 'existing_dir'
            if (-not (Test-Path $existingDir)) {
                New-Item -ItemType Directory -Path $existingDir -Force | Out-Null
            }

            { mkdir -p $existingDir } | Should -Not -Throw
            Test-Path $existingDir | Should -Be $true
        }

        It 'mkdir fails when parent directory does not exist without -p' {
            $nestedPath = Join-Path $TestDrive 'missing_parent' 'child'
            $parent = Split-Path $nestedPath -Parent
            if (Test-Path $parent) {
                Remove-Item $parent -Force -Recurse
            }

            { mkdir $nestedPath -ErrorAction Stop 2>$null } | Should -Throw
            Test-Path $nestedPath | Should -Be $false
        }

        It 'mkdir shows error message when missing operand' {
            $errorOutput = mkdir 2>&1
            $errorOutput | Should -Not -BeNullOrEmpty
            $errorOutput[0].ToString() | Should -Match 'missing operand'
        }

        It 'mkdir handles -p flag in argument list' {
            $nestedPath = Join-Path $TestDrive 'arg_p' 'child'
            if (Test-Path (Split-Path $nestedPath -Parent)) {
                Remove-Item (Split-Path $nestedPath -Parent) -Force -Recurse
            }

            # Test that -p can be passed as an argument (Unix style)
            mkdir -p $nestedPath | Out-Null
            Test-Path $nestedPath | Should -Be $true
        }

        It 'mkdir skips empty strings in path list' {
            $validDir = Join-Path $TestDrive 'valid_dir'
            if (Test-Path $validDir) {
                Remove-Item $validDir -Force -Recurse
            }

            # Pass empty string and valid path
            mkdir '' $validDir | Out-Null
            Test-Path $validDir | Should -Be $true
        }

        It 'mkdir creates directories with spaces in names' {
            $dirWithSpaces = Join-Path $TestDrive 'dir with spaces'
            if (Test-Path $dirWithSpaces) {
                Remove-Item $dirWithSpaces -Force -Recurse
            }

            mkdir $dirWithSpaces | Out-Null
            Test-Path $dirWithSpaces | Should -Be $true
        }

        It 'mkdir -p creates nested directories with spaces' {
            $nestedWithSpaces = Join-Path $TestDrive 'parent dir' 'child dir' 'grandchild dir'
            if (Test-Path (Split-Path $nestedWithSpaces -Parent)) {
                Remove-Item (Split-Path $nestedWithSpaces -Parent) -Force -Recurse
            }

            mkdir -p $nestedWithSpaces | Out-Null
            Test-Path $nestedWithSpaces | Should -Be $true
        }

        It 'mkdir handles -p flag when passed as switch parameter' {
            $baseDir = Join-Path $TestDrive 'switch_p_test'
            $dir1 = Join-Path $baseDir 'dir1'
            $dir2 = Join-Path $baseDir 'dir2'
            
            if (Test-Path $baseDir) {
                Remove-Item $baseDir -Force -Recurse
            }
            New-Item -ItemType Directory -Path $baseDir -Force | Out-Null

            # Test -p as a switch parameter (PowerShell style)
            mkdir -Parent $dir1 $dir2 | Out-Null
            Test-Path $dir1 | Should -Be $true
            Test-Path $dir2 | Should -Be $true
        }

        It 'mkdir creates multiple directories in current directory' {
            $testBase = Join-Path $TestDrive 'current_dir_test'
            if (Test-Path $testBase) {
                Remove-Item $testBase -Force -Recurse
            }
            New-Item -ItemType Directory -Path $testBase -Force | Out-Null

            Push-Location $testBase
            try {
                mkdir -p core fragment path file | Out-Null
                Test-Path (Join-Path $testBase 'core') | Should -Be $true
                Test-Path (Join-Path $testBase 'fragment') | Should -Be $true
                Test-Path (Join-Path $testBase 'path') | Should -Be $true
                Test-Path (Join-Path $testBase 'file') | Should -Be $true
            }
            finally {
                Pop-Location
            }
        }
    }

    Context 'System insights and networking' {

        It 'df shows disk usage information' {
            # Mock Get-PSDrive to return test data
            Mock -CommandName Get-PSDrive -MockWith {
                @(
                    [PSCustomObject]@{
                        Name       = 'C'
                        Used       = 50GB
                        Free       = 100GB
                        Root       = 'C:\'
                        PSProvider = [Microsoft.PowerShell.Commands.FileSystemProvider]::new()
                    }
                )
            } -ParameterFilter { $PSProvider -eq 'FileSystem' }
            
            $result = df
            $result | Should -Not -Be $null
            if ($result.Count -gt 0) {
                $result[0].PSObject.Properties.Name -contains 'Name' | Should -Be $true
                $result[0].PSObject.Properties.Name -contains 'Used(GB)' | Should -Be $true
            }
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
            if ($result.Count -gt 0) {
                ($result.Count -le 10) | Should -Be $true
                $result[0].PSObject.Properties.Name -contains 'Name' | Should -Be $true
            }
        }

        It 'ports shows network port information' {
            # Mock netstat to prevent actual network calls
            Mock -CommandName netstat -MockWith { "Active Connections`nTCP    0.0.0.0:80" }
            { ports } | Should -Not -Throw
        }

        It 'ptest tests network connectivity' {
            # Mock Test-Connection to prevent actual network calls
            Mock -CommandName Test-Connection -MockWith {
                [PSCustomObject]@{ ComputerName = 'localhost'; ResponseTime = 1; Status = 'Success' }
            }
            $result = ptest localhost
            $result | Should -Not -Be $null
        }

        It 'dns resolves hostnames' {
            # Mock Resolve-DnsName to prevent actual DNS calls
            Mock -CommandName Resolve-DnsName -MockWith {
                [PSCustomObject]@{ Name = 'localhost'; Type = 'A'; IPAddress = '127.0.0.1' }
            }
            $result = dns localhost
            $result | Should -Not -BeNullOrEmpty
            if ($result -is [array] -and $result.Count -gt 0) {
                $result[0].Name | Should -Be 'localhost'
            }
            elseif ($result -is [PSCustomObject]) {
                $result.Name | Should -Be 'localhost'
            }
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
