#
# Tests for system-related helper functions.
#

BeforeAll {
    . (Join-Path $PSScriptRoot '..\TestSupport.ps1')
    $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
    . (Join-Path $script:ProfileDir 'bootstrap.ps1')
    . (Join-Path $script:ProfileDir 'system.ps1')

    # Load system modules at script scope (Ensure-System uses Import-FragmentModule, which
    # dot-sources inside a function and would not leave helpers visible to these tests).
    $systemModuleFiles = @(
        'FileOperations.ps1'
        'SystemInfo.ps1'
        'NetworkOperations.ps1'
        'ArchiveOperations.ps1'
        'EditorAliases.ps1'
        'TextSearch.ps1'
    )

    foreach ($moduleFile in $systemModuleFiles) {
        $modulePath = Join-Path $script:ProfileDir 'system' $moduleFile
        . $modulePath
    }

    $script:TestRoot = New-TestTempDirectory -Prefix 'SystemUtilities'
}

# On Linux, Set-AgentModeAlias skips names already on PATH (which, pgrep, touch, mkdir, etc.).
# On Windows, those aliases are registered to imitate Unix tools. Tests invoke whichever is available.
function global:Invoke-SystemUtility {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$FunctionName,

        [Parameter(Mandatory, Position = 1)]
        [string]$AliasName,

        [Parameter(ValueFromRemainingArguments = $true)]
        [object[]]$Arguments
    )

    if (-not (Get-Command -Name $FunctionName -ErrorAction SilentlyContinue)) {
        if (Get-Alias -Name $AliasName -ErrorAction SilentlyContinue) {
            if ($null -ne $Arguments -and @($Arguments).Count -gt 0) {
                & $AliasName @Arguments
            }
            else {
                & $AliasName
            }

            return
        }

        throw "Profile system function '$FunctionName' is not available."
    }

  # Array splatting does not bind -LiteralPath; route it explicitly (avoids creating ./-LiteralPath).
    $argumentList = @($Arguments)
    if ($argumentList.Count -gt 0) {
        $literalIndex = [array]::IndexOf($argumentList, '-LiteralPath')
        if ($literalIndex -ge 0) {
            $literalPaths = @($argumentList[($literalIndex + 1)..($argumentList.Count - 1)])
            $leadingArgs = @()
            if ($literalIndex -gt 0) {
                $leadingArgs = @($argumentList[0..($literalIndex - 1)])
            }

            if ($leadingArgs.Count -gt 0) {
                & $FunctionName @leadingArgs -LiteralPath $literalPaths
            }
            else {
                & $FunctionName -LiteralPath $literalPaths
            }

            return
        }
    }

    if ($argumentList.Count -gt 0) {
        & $FunctionName @argumentList
    }
    else {
        & $FunctionName
    }
}

Describe 'Profile system utility functions' {
    Context 'Command discovery helpers' {
        It 'which shows command information' {
            $result = Invoke-SystemUtility Get-CommandInfo which Get-Command
            $result | Should -Not -BeNullOrEmpty
            $result.Name | Should -Be 'Get-Command'
        }

        It 'which handles non-existent commands gracefully' {
            $name = "NonExistentCommand_{0}" -f (Get-Random)
            $result = Invoke-SystemUtility Get-CommandInfo which $name
            $result | Should -BeNullOrEmpty
        }
    }

    Context 'Search utilities' {
        It 'pgrep searches for patterns in files' {
            $tempFile = Join-Path $script:TestRoot 'test_pgrep.txt'
            Set-Content -Path $tempFile -Value 'test content with pattern'
            $result = Invoke-SystemUtility Find-String pgrep 'pattern' $tempFile
            $result | Should -Not -Be $null
            $result.Line | Should -Match 'pattern'
        }

        It 'pgrep handles pattern not found gracefully' {
            $tempFile = Join-Path $script:TestRoot 'test_no_match.txt'
            Set-Content -Path $tempFile -Value 'no match here'
            $result = Invoke-SystemUtility Find-String pgrep 'nonexistentpattern' $tempFile
            (@($result).Count -eq 0) | Should -Be $true
        }

        It 'search finds files recursively' {
            $tempDir = Join-Path $script:TestRoot 'test_search'
            New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
            New-Item -ItemType File -Path (Join-Path $tempDir 'test.txt') -Force | Out-Null

            Push-Location $tempDir
            try {
                $result = Invoke-SystemUtility Find-File search test.txt
                $result | Where-Object { $_ -eq 'test.txt' } | Should -Not -BeNullOrEmpty
            }
            finally {
                Pop-Location
            }
        }

        It 'search handles empty directories' {
            $emptyDir = Join-Path $script:TestRoot 'empty_search'
            New-Item -ItemType Directory -Path $emptyDir -Force | Out-Null

            Push-Location $emptyDir
            try {
                $result = Invoke-SystemUtility Find-File search '*.txt'
                (@($result).Count -eq 0) | Should -Be $true
            }
            finally {
                Pop-Location
            }
        }
    }

    Context 'File creation and metadata helpers' {
        It 'touch creates empty files' {
            $tempFile = Join-Path $script:TestRoot 'test_touch.txt'
            if (Test-Path $tempFile) {
                Remove-Item $tempFile -Force
            }
            Invoke-SystemUtility New-EmptyFile touch $tempFile
            Test-Path $tempFile | Should -Be $true
        }

        It 'touch updates timestamp when file exists' {
            $tempFile = Join-Path $script:TestRoot 'touch_timestamp.txt'
            Set-Content -Path $tempFile -Value 'initial content'
            $original = (Get-Item $tempFile).LastWriteTime
            Start-Sleep -Milliseconds 50
            Invoke-SystemUtility New-EmptyFile touch $tempFile
            $updated = (Get-Item $tempFile).LastWriteTime
            $updated | Should -BeGreaterThan $original
        }

        It 'touch supports LiteralPath parameter' {
            $tempFile = Join-Path $script:TestRoot 'folder with spaces' 'literal touch.txt'
            $directory = Split-Path -Parent $tempFile
            if (-not (Test-Path $directory)) {
                New-Item -ItemType Directory -Path $directory -Force | Out-Null
            }

            if (Test-Path $tempFile) {
                Remove-Item $tempFile -Force
            }

            $repoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
            $spillPath = Join-Path $repoRoot '-LiteralPath'

            Invoke-SystemUtility New-EmptyFile touch -LiteralPath $tempFile
            Test-Path -LiteralPath $tempFile | Should -Be $true
            Test-Path -LiteralPath $spillPath | Should -Be $false -Because 'array splat must not create a repo-root file named -LiteralPath'
        }

        It 'touch throws when parent directory is missing' {
            $tempFile = Join-Path $script:TestRoot 'missing' 'nope.txt'
            $parent = Split-Path -Parent $tempFile
            if (Test-Path $parent) {
                Remove-Item $parent -Recurse -Force
            }

            { Invoke-SystemUtility New-EmptyFile touch $tempFile -ErrorAction Stop } | Should -Throw
            Test-Path $tempFile | Should -Be $false
        }
    }

    Context 'New-Directory / mkdir' {
        It 'mkdir supports LiteralPath parameter' {
            $tempDir = Join-Path $script:TestRoot 'folder with spaces' 'literal mkdir'
            $repoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
            $spillPath = Join-Path $repoRoot '-LiteralPath'

            if (Test-Path -LiteralPath $tempDir) {
                Remove-Item -LiteralPath $tempDir -Recurse -Force
            }

            Invoke-SystemUtility New-Directory mkdir -LiteralPath $tempDir
            Test-Path -LiteralPath $tempDir | Should -Be $true
            Test-Path -LiteralPath $spillPath | Should -Be $false -Because 'array splat must not create a repo-root file named -LiteralPath'
        }
    }

    Context 'File management wrappers' {
        It 'New-Directory creates directories via wrapper' {
            $tempDir = Join-Path $script:TestRoot 'wrapper_mkdir'
            if (Test-Path $tempDir) {
                Remove-Item $tempDir -Force -Recurse
            }

            New-Directory -Path $tempDir | Out-Null
            Test-Path $tempDir | Should -Be $true
        }

        It 'Copy-ItemCustom copies files via wrapper' {
            $sourceDir = Join-Path $script:TestRoot 'copy_source'
            $destDir = Join-Path $script:TestRoot 'copy_dest'
            New-Directory -Path $sourceDir | Out-Null
            New-Directory -Path $destDir | Out-Null

            $sourceFile = Join-Path $sourceDir 'source.txt'
            Set-Content -Path $sourceFile -Value 'wrapper copy test'

            Copy-ItemCustom -Path $sourceFile -Destination $destDir
            Test-Path (Join-Path $destDir 'source.txt') | Should -Be $true
        }

        It 'Move-ItemCustom moves files via wrapper' {
            $sourceDir = Join-Path $script:TestRoot 'move_source'
            $destDir = Join-Path $script:TestRoot 'move_dest'
            New-Directory -Path $sourceDir | Out-Null
            New-Directory -Path $destDir | Out-Null

            $sourceFile = Join-Path $sourceDir 'move.txt'
            Set-Content -Path $sourceFile -Value 'wrapper move test'

            Move-ItemCustom -Path $sourceFile -Destination $destDir
            Test-Path $sourceFile | Should -Be $false
            Test-Path (Join-Path $destDir 'move.txt') | Should -Be $true
        }

        It 'Remove-ItemCustom deletes files via wrapper' {
            $tempFile = Join-Path $script:TestRoot 'remove.txt'
            Set-Content -Path $tempFile -Value 'wrapper remove test'
            Remove-ItemCustom -Path $tempFile -Force
            Test-Path $tempFile | Should -Be $false
        }

        It 'mkdir creates directories' {
            $tempDir = Join-Path $script:TestRoot 'test_mkdir'
            Invoke-SystemUtility New-Directory mkdir $tempDir | Out-Null
            Test-Path $tempDir | Should -Be $true
        }
    }

    Context 'mkdir Unix-like behavior' {
        It 'mkdir creates a single directory' {
            $tempDir = Join-Path $script:TestRoot 'single_dir'
            if (Test-Path $tempDir) {
                Remove-Item $tempDir -Force -Recurse
            }
            Invoke-SystemUtility New-Directory mkdir $tempDir | Out-Null
            Test-Path $tempDir | Should -Be $true
            (Get-Item $tempDir).PSIsContainer | Should -Be $true
        }

        It 'mkdir creates multiple directories' {
            $baseDir = Join-Path $script:TestRoot 'multi_mkdir'
            $dir1 = Join-Path $baseDir 'core'
            $dir2 = Join-Path $baseDir 'fragment'
            $dir3 = Join-Path $baseDir 'path'
            
            if (Test-Path $baseDir) {
                Remove-Item $baseDir -Force -Recurse
            }
            New-Item -ItemType Directory -Path $baseDir -Force | Out-Null

            Invoke-SystemUtility New-Directory mkdir $dir1 $dir2 $dir3 | Out-Null
            Test-Path $dir1 | Should -Be $true
            Test-Path $dir2 | Should -Be $true
            Test-Path $dir3 | Should -Be $true
        }

        It 'mkdir -p creates parent directories' {
            $nestedPath = Join-Path $script:TestRoot 'parent' 'child' 'grandchild'
            if (Test-Path (Split-Path $nestedPath -Parent)) {
                Remove-Item (Split-Path $nestedPath -Parent) -Force -Recurse
            }

            Invoke-SystemUtility New-Directory mkdir @('-p', $nestedPath) | Out-Null
            Test-Path $nestedPath | Should -Be $true
            Test-Path (Split-Path $nestedPath -Parent) | Should -Be $true
            Test-Path (Split-Path (Split-Path $nestedPath -Parent) -Parent) | Should -Be $true
        }

        It 'mkdir -Parent creates parent directories' {
            $nestedPath = Join-Path $script:TestRoot 'parent2' 'child2' 'grandchild2'
            if (Test-Path (Split-Path $nestedPath -Parent)) {
                Remove-Item (Split-Path $nestedPath -Parent) -Force -Recurse
            }

            New-Directory -Parent $nestedPath | Out-Null
            Test-Path $nestedPath | Should -Be $true
        }

        It 'mkdir -p creates multiple directories with parent paths' {
            $baseDir = Join-Path $script:TestRoot 'multi_p'
            $dir1 = Join-Path $baseDir 'file'
            $dir2 = Join-Path $baseDir 'metrics'
            $dir3 = Join-Path $baseDir 'performance'
            
            if (Test-Path $baseDir) {
                Remove-Item $baseDir -Force -Recurse
            }

            Invoke-SystemUtility New-Directory mkdir @('-p', $dir1, $dir2, $dir3) | Out-Null
            Test-Path $dir1 | Should -Be $true
            Test-Path $dir2 | Should -Be $true
            Test-Path $dir3 | Should -Be $true
        }

        It 'mkdir -p core fragment path file metrics performance code-analysis utilities runtime parallel creates all directories' {
            $baseDir = Join-Path $script:TestRoot 'unix_like_test'
            $dirs = @('core', 'fragment', 'path', 'file', 'metrics', 'performance', 'code-analysis', 'utilities', 'runtime', 'parallel')
            
            if (Test-Path $baseDir) {
                Remove-Item $baseDir -Force -Recurse
            }
            New-Item -ItemType Directory -Path $baseDir -Force | Out-Null

            $fullPaths = $dirs | ForEach-Object { Join-Path $baseDir $_ }
            New-Directory -Parent @($fullPaths) | Out-Null

            foreach ($dir in $dirs) {
                $fullPath = Join-Path $baseDir $dir
                Test-Path $fullPath | Should -Be $true
            }
        }

        It 'mkdir handles already existing directories gracefully with -p' {
            $existingDir = Join-Path $script:TestRoot 'existing_dir'
            if (-not (Test-Path $existingDir)) {
                New-Item -ItemType Directory -Path $existingDir -Force | Out-Null
            }

            { Invoke-SystemUtility New-Directory mkdir @('-p', $existingDir) } | Should -Not -Throw
            Test-Path $existingDir | Should -Be $true
        }

        It 'mkdir fails when parent directory does not exist without -p' {
            $nestedPath = Join-Path $script:TestRoot 'missing_parent' 'child'
            $parent = Split-Path $nestedPath -Parent
            if (Test-Path $parent) {
                Remove-Item $parent -Force -Recurse
            }

            { Invoke-SystemUtility New-Directory mkdir $nestedPath -ErrorAction Stop 2>$null } | Should -Throw
            Test-Path $nestedPath | Should -Be $false
        }

        It 'mkdir shows error message when missing operand' {
            { New-Directory -ErrorAction Stop 2>$null } | Should -Throw '*missing operand*'
        }

        It 'mkdir handles -p flag in argument list' {
            $nestedPath = Join-Path $script:TestRoot 'arg_p' 'child'
            if (Test-Path (Split-Path $nestedPath -Parent)) {
                Remove-Item (Split-Path $nestedPath -Parent) -Force -Recurse
            }

            # Test that -p can be passed as an argument (Unix style)
            Invoke-SystemUtility New-Directory mkdir @('-p', $nestedPath) | Out-Null
            Test-Path $nestedPath | Should -Be $true
        }

        It 'mkdir skips empty strings in path list' {
            $validDir = Join-Path $script:TestRoot 'valid_dir'
            if (Test-Path $validDir) {
                Remove-Item $validDir -Force -Recurse
            }

            # Pass empty string and valid path
            Invoke-SystemUtility New-Directory mkdir '' $validDir | Out-Null
            Test-Path $validDir | Should -Be $true
        }

        It 'mkdir creates directories with spaces in names' {
            $dirWithSpaces = Join-Path $script:TestRoot 'dir with spaces'
            if (Test-Path $dirWithSpaces) {
                Remove-Item $dirWithSpaces -Force -Recurse
            }

            Invoke-SystemUtility New-Directory mkdir $dirWithSpaces | Out-Null
            Test-Path $dirWithSpaces | Should -Be $true
        }

        It 'mkdir -p creates nested directories with spaces' {
            $nestedWithSpaces = Join-Path $script:TestRoot 'parent dir' 'child dir' 'grandchild dir'
            if (Test-Path (Split-Path $nestedWithSpaces -Parent)) {
                Remove-Item (Split-Path $nestedWithSpaces -Parent) -Force -Recurse
            }

            Invoke-SystemUtility New-Directory mkdir @('-p', $nestedWithSpaces) | Out-Null
            Test-Path $nestedWithSpaces | Should -Be $true
        }

        It 'mkdir handles -p flag when passed as switch parameter' {
            $baseDir = Join-Path $script:TestRoot 'switch_p_test'
            $dir1 = Join-Path $baseDir 'dir1'
            $dir2 = Join-Path $baseDir 'dir2'
            
            if (Test-Path $baseDir) {
                Remove-Item $baseDir -Force -Recurse
            }
            New-Item -ItemType Directory -Path $baseDir -Force | Out-Null

            # Test -p as a switch parameter (PowerShell style)
            New-Directory -Parent $dir1, $dir2 | Out-Null
            Test-Path $dir1 | Should -Be $true
            Test-Path $dir2 | Should -Be $true
        }

        It 'mkdir creates multiple directories in current directory' {
            $testBase = Join-Path $script:TestRoot 'current_dir_test'
            if (Test-Path $testBase) {
                Remove-Item $testBase -Force -Recurse
            }
            New-Item -ItemType Directory -Path $testBase -Force | Out-Null

            Push-Location $testBase
            try {
                Invoke-SystemUtility New-Directory mkdir @('-p', 'core', 'fragment', 'path', 'file') | Out-Null
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
            $result = Invoke-SystemUtility Get-DiskUsage df
            $result | Should -Not -BeNullOrEmpty
            if (@($result).Count -gt 0) {
                $result[0].PSObject.Properties.Name | Should -Contain 'Name'
                $result[0].PSObject.Properties.Name | Should -Contain 'Used(GB)'
            }
        }

        It 'htop shows top CPU processes' {
            $result = Invoke-SystemUtility Get-TopProcesses htop
            $result | Should -Not -BeNullOrEmpty
            if (@($result).Count -gt 0) {
                (@($result).Count -le 10) | Should -Be $true
                $result[0].PSObject.Properties.Name | Should -Contain 'Name'
            }
        }

        It 'ports shows network port information' {
            Setup-CapturingCommandMock -CommandName 'netstat' -Output "Active Connections`nTCP    0.0.0.0:80"

            { Invoke-SystemUtility Get-NetworkPorts ports } | Should -Not -Throw
        }

        It 'ptest tests network connectivity' {
            $original = Get-Command Test-NetworkConnection -ErrorAction SilentlyContinue

            function global:Test-NetworkConnection {
                [PSCustomObject]@{
                    ComputerName = 'localhost'
                    ResponseTime = 1
                    Status       = 'Success'
                }
            }

            try {
                $result = Invoke-SystemUtility Test-NetworkConnection ptest localhost
                $result | Should -Not -BeNullOrEmpty
            }
            finally {
                Remove-Item Function:\Test-NetworkConnection -Force -ErrorAction SilentlyContinue
                Remove-Item Function:\global:Test-NetworkConnection -Force -ErrorAction SilentlyContinue
                if ($original) {
                    Set-Item -Path Function:\global:Test-NetworkConnection -Value $original.ScriptBlock -Force
                }
            }
        }

        It 'dns resolves hostnames' {
            $original = Get-Command Resolve-DnsNameCustom -ErrorAction SilentlyContinue

            Remove-Item Function:\Resolve-DnsNameCustom -Force -ErrorAction SilentlyContinue
            Remove-Item Function:\global:Resolve-DnsNameCustom -Force -ErrorAction SilentlyContinue

            function global:Resolve-DnsNameCustom {
                [PSCustomObject]@{
                    Name      = 'localhost'
                    Type      = 'A'
                    IPAddress = '127.0.0.1'
                }
            }

            try {
                $result = Invoke-SystemUtility Resolve-DnsNameCustom dns localhost
                $result | Should -Not -BeNullOrEmpty
                if ($result -is [array] -and @($result).Count -gt 0) {
                    $result[0].Name | Should -Be 'localhost'
                }
                elseif ($result -is [PSCustomObject]) {
                    $result.Name | Should -Be 'localhost'
                }
            }
            finally {
                Remove-Item Function:\Resolve-DnsNameCustom -Force -ErrorAction SilentlyContinue
                Remove-Item Function:\global:Resolve-DnsNameCustom -Force -ErrorAction SilentlyContinue
                if ($original) {
                    Set-Item -Path Function:\global:Resolve-DnsNameCustom -Value $original.ScriptBlock -Force
                }
            }
        }
    }

    Context 'Archiving helpers' {
        It 'zip creates archives' {
            $tempDir = Join-Path $script:TestRoot 'test_zip'
            $zipFile = Join-Path $script:TestRoot 'test.zip'
            New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
            New-Item -ItemType File -Path (Join-Path $tempDir 'test.txt') -Value 'test' -Force | Out-Null

            Compress-ArchiveCustom -Path $tempDir -DestinationPath $zipFile
            Test-Path $zipFile | Should -Be $true
        }
    }
}
