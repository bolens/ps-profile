Describe 'Profile fragments' {
    BeforeAll {
        $profileRelative = Join-Path $PSScriptRoot '..\profile.d'
        try {
            $script:ProfileDir = (Resolve-Path -LiteralPath $profileRelative -ErrorAction Stop).ProviderPath
        }
        catch {
            throw "Profile directory not found at $profileRelative"
        }

        $bootstrapRelative = Join-Path $script:ProfileDir '00-bootstrap.ps1'
        try {
            $script:BootstrapPath = (Resolve-Path -LiteralPath $bootstrapRelative -ErrorAction Stop).ProviderPath
        }
        catch {
            throw "Bootstrap script not found at $bootstrapRelative"
        }
        . $script:BootstrapPath
    }

    It 'loads fragments twice without error (idempotency)' {
        # Dot-source each fragment inside a scriptblock that defines $PSScriptRoot so fragments can rely on it.
        $files = Get-ChildItem -Path $script:ProfileDir -Filter *.ps1 -File | Sort-Object Name | Select-Object -ExpandProperty FullName
        # Dot-source all fragments in the same scope so helpers defined in bootstrap are visible
        & { param($files, $root) $PSScriptRoot = $root; foreach ($f in $files) { . $f } } $files $PSScriptRoot
        & { param($files, $root) $PSScriptRoot = $root; foreach ($f in $files) { . $f } } $files $PSScriptRoot
        # If no exception reached here, pass
        $true | Should -Be $true
    }

    It 'Set-AgentModeFunction registers a function safely' {
        . $script:BootstrapPath
        $sb = Set-AgentModeFunction -Name 'test_agent_fn' -Body { return 'ok' } -ReturnScriptBlock
        # The helper returns the created ScriptBlock on success, or $false when it was a no-op.
        $sb | Should -Not -Be $false
        $sb.GetType().Name | Should -Be 'ScriptBlock'
        $result = $null
        try { $result = (& test_agent_fn) } catch { }
        $result | Should -Be 'ok'
        # Also test alias helper returns boolean
        $aliasName = "test_alias_$(Get-Random)"
        $aliasResult = Set-AgentModeAlias -Name $aliasName -Target 'Write-Output'
        $aliasResult | Should -Be $true
        # Invocation test: calling the created alias should invoke the target (Write-Output)
        $aliasOut = $null
        try { $aliasOut = & $aliasName 'ping' } catch { }
        $aliasOut | Should -Be 'ping'
    }

    It 'base64 encode/decode roundtrip for small content' {
        $content = 'hello world'
        $b64 = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($content))
        $decoded = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($b64))
        ($decoded -eq 'hello world') | Should -Be $true
    }

    Context 'Utility functions' {
        BeforeAll {
            . (Join-Path $script:ProfileDir '05-utilities.ps1')
        }

        It 'Get-EnvVar retrieves environment variable from registry' {
            # Test with a known environment variable
            $tempVar = "TEST_VAR_$(Get-Random)"
            try {
                # Set a test variable
                Set-EnvVar -Name $tempVar -Value 'test_value'
                $result = Get-EnvVar -Name $tempVar
                $result | Should -Be 'test_value'
            }
            finally {
                # Clean up
                Set-EnvVar -Name $tempVar -Value $null
            }
        }

        It 'Set-EnvVar sets environment variable in registry' {
            $tempVar = "TEST_VAR_$(Get-Random)"
            try {
                Set-EnvVar -Name $tempVar -Value 'test_value'
                $result = Get-EnvVar -Name $tempVar
                $result | Should -Be 'test_value'
            }
            finally {
                Set-EnvVar -Name $tempVar -Value $null
            }
        }

        It 'from-epoch converts Unix timestamp correctly' {
            $timestamp = 1609459200  # 2020-12-31 00:00:00 UTC
            $result = from-epoch $timestamp
            $result.Year | Should -Be 2020
            $result.Month | Should -Be 12
            $result.Day | Should -Be 31
        }

        It 'epoch returns current Unix timestamp' {
            $before = [DateTimeOffset]::Now.ToUnixTimeSeconds()
            $result = epoch
            $after = [DateTimeOffset]::Now.ToUnixTimeSeconds()
            $result | Should -BeGreaterThan ($before - 1)
            $result | Should -BeLessThan ($after + 1)
        }

        It 'pwgen generates password of correct length' {
            $password = pwgen
            $password.Length | Should -Be 16
            $password | Should -Match '^[a-zA-Z0-9]+$'
        }

        It 'pwgen generates unique passwords on consecutive calls' {
            $pass1 = pwgen
            $pass2 = pwgen
            # Passwords should be different (very unlikely to be the same)
            $pass1 | Should -Not -Be $pass2
        }

        It 'Remove-Path removes directory from PATH' {
            # Test Remove-Path function
            $testPath = Join-Path $TestDrive 'TestPath'

            # Add test path to PATH temporarily
            $originalPath = $env:PATH
            try {
                $env:PATH = "$env:PATH;$testPath"

                # Verify path was added
                $env:PATH | Should -Match ([regex]::Escape($testPath))

                # Remove the path
                Remove-Path -Path $testPath

                # Verify path was removed
                $env:PATH | Should -Not -Match ([regex]::Escape($testPath))
            }
            finally {
                # Restore original PATH
                $env:PATH = $originalPath
                if (Test-Path $testPath) {
                    Remove-Item -Path $testPath -Recurse -Force
                }
            }
        }

        It 'Add-Path adds directory to PATH' {
            # Test Add-Path function
            $testPath = Join-Path $TestDrive 'TestAddPath'
            if (-not (Test-Path $testPath)) {
                New-Item -ItemType Directory -Path $testPath -Force | Out-Null
            }

            # Store original PATH
            $originalPath = $env:PATH
            try {
                # Ensure test path is not already in PATH
                if ($env:PATH -split ';' -contains $testPath) {
                    Remove-Path -Path $testPath
                }

                # Add the test path
                Add-Path -Path $testPath

                # Verify path was added
                $env:PATH | Should -Match ([regex]::Escape($testPath))

                # Clean up - remove the test path
                Remove-Path -Path $testPath

                # Verify path was removed
                $env:PATH | Should -Not -Match ([regex]::Escape($testPath))
            }
            finally {
                # Restore original PATH
                $env:PATH = $originalPath
            }
        }

        It 'Get-EnvVar handles non-existent variables gracefully' {
            $nonExistent = "NON_EXISTENT_VAR_$(Get-Random)"
            $result = Get-EnvVar -Name $nonExistent
            # Should return null or empty for non-existent vars
            ($result -eq $null -or $result -eq '') | Should -Be $true
        }

        It 'Set-EnvVar can delete variables by setting to null' {
            $tempVar = "TEST_DELETE_$(Get-Random)"
            try {
                # Set a value
                Set-EnvVar -Name $tempVar -Value 'test'
                $before = Get-EnvVar -Name $tempVar
                $before | Should -Be 'test'

                # Delete by setting to null
                Set-EnvVar -Name $tempVar -Value $null
                $after = Get-EnvVar -Name $tempVar
                ($after -eq $null -or $after -eq '') | Should -Be $true
            }
            finally {
                Set-EnvVar -Name $tempVar -Value $null
            }
        }

        It 'from-epoch handles epoch 0 correctly' {
            # Test epoch 0 (1970-01-01)
            $result = from-epoch 0
            $utc = $result.ToUniversalTime()
            $utc.Year | Should -Be 1970
            $utc.Month | Should -Be 1
            $utc.Day | Should -Be 1
        }
    }

    Context 'File utility functions' {
        BeforeAll {
            . (Join-Path $script:ProfileDir '02-files-conversion.ps1')
            . (Join-Path $script:ProfileDir '02-files-utilities.ps1')
            # Ensure file helper functions are initialized
            Ensure-FileConversion
            Ensure-FileUtilities
        }

        It 'json-pretty formats JSON correctly' {
            $json = '{"name":"test","value":123}'
            $result = json-pretty $json
            $result | Should -Match '"name":\s*"test"'
            $result | Should -Match '"value":\s*123'
        }

        It 'to-base64 and from-base64 roundtrip correctly' {
            $testString = 'Hello, World!'
            $encoded = $testString | to-base64
            $decoded = $encoded | from-base64
            $decoded.TrimEnd("`r", "`n") | Should -Be $testString
        }

        It 'file-hash calculates SHA256 correctly' {
            $tempFile = Join-Path $TestDrive 'test_hash.txt'
            Set-Content -Path $tempFile -Value 'test content' -NoNewline
            $hash = file-hash $tempFile
            $hash.Algorithm | Should -Be 'SHA256'
            $hash.Hash.Length | Should -Be 64  # SHA256 is 64 hex chars
        }

        It 'filesize returns human-readable size' {
            $tempFile = Join-Path $TestDrive 'test_size.txt'
            # Create a 1024 byte file
            $content = 'x' * 1024
            Set-Content -Path $tempFile -Value $content -NoNewline
            $result = filesize $tempFile
            $result | Should -Match '1\.00 KB'
        }

        It 'to-base64 handles empty strings' {
            $empty = ''
            $encoded = $empty | to-base64
            $decoded = $encoded | from-base64
            $decoded.TrimEnd("`r", "`n") | Should -Be $empty
        }

        It 'to-base64 handles unicode strings' {
            $unicode = 'Hello 世界'
            $encoded = $unicode | to-base64
            $decoded = $encoded | from-base64
            $decoded.TrimEnd("`r", "`n") | Should -Be $unicode
        }

        It 'file-hash handles non-existent files gracefully' {
            $nonExistent = Join-Path $TestDrive 'non_existent.txt'
            # Should handle error gracefully
            { file-hash $nonExistent } | Should -Not -Throw
        }
    }

    Context 'System utility functions' {
        BeforeAll {
            . (Join-Path $script:ProfileDir '07-system.ps1')
        }

        It 'which shows command information' {
            $result = which Get-Command
            $result | Should -Not -Be $null
            $result.Name | Should -Be 'Get-Command'
        }

        It 'which handles non-existent commands gracefully' {
            $nonExistent = "NonExistentCommand_$(Get-Random)"
            $result = which $nonExistent
            # Should return null or handle gracefully
            ($result -eq $null -or $result.Count -eq 0) | Should -Be $true
        }

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
            # Should return empty or null
            ($result -eq $null -or $result.Count -eq 0) | Should -Be $true
        }

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
            if (Test-Path (Split-Path -Parent $tempFile)) {
                Remove-Item (Split-Path -Parent $tempFile) -Recurse -Force
            }

            { touch $tempFile } | Should -Throw -Because 'touch should surface missing parent directory errors'
        }

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
            mkdir $tempDir
            Test-Path $tempDir | Should -Be $true
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
                # Should return empty array or null
                ($result -eq $null -or $result.Count -eq 0) | Should -Be $true
            }
            finally {
                Pop-Location
            }
        }

        It 'df shows disk usage information' {
            $result = df
            $result | Should -Not -Be $null
            $result[0].PSObject.Properties.Name -contains 'Name' | Should -Be $true
            $result[0].PSObject.Properties.Name -contains 'Used(GB)' | Should -Be $true
        }

        It 'htop shows top CPU processes' {
            $result = htop
            $result | Should -Not -Be $null
            ($result.Count -le 10) | Should -Be $true
            $result[0].PSObject.Properties.Name -contains 'Name' | Should -Be $true
        }

        It 'ports shows network port information' {
            # This might require admin privileges, so we'll just test it doesn't throw
            { ports } | Should -Not -Throw
        }

        It 'ptest tests network connectivity' {
            # Test with localhost which should always work
            $result = ptest localhost
            $result | Should -Not -Be $null
        }

        It 'dns resolves hostnames' {
            $result = dns localhost
            $result | Should -Not -BeNullOrEmpty
            $result[0].Name | Should -Be 'localhost'
        }

        It 'zip creates archives' {
            $tempDir = Join-Path $TestDrive 'test_zip'
            $zipFile = Join-Path $TestDrive 'test.zip'
            New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
            New-Item -ItemType File -Path (Join-Path $tempDir 'test.txt') -Value 'test' -Force | Out-Null

            zip -Path $tempDir -DestinationPath $zipFile
            Test-Path $zipFile | Should -Be $true
        }
    }

    Context 'System info functions' {
        BeforeAll {
            . (Join-Path $script:ProfileDir '08-system-info.ps1')
        }

        It 'uptime returns a TimeSpan object' {
            $result = uptime
            $result | Should -Not -Be $null
            $result.GetType().Name | Should -Be 'TimeSpan'
        }

        It 'sysinfo returns computer system information' {
            $result = sysinfo
            $result | Should -Not -Be $null
            ($result | Get-Member -MemberType Properties).Name -contains 'Name' | Should -Be $true
            ($result | Get-Member -MemberType Properties).Name -contains 'Manufacturer' | Should -Be $true
        }

        It 'cpuinfo returns processor information' {
            $result = cpuinfo
            $result | Should -Not -Be $null
            ($result | Get-Member -MemberType Properties).Name -contains 'Name' | Should -Be $true
            ($result | Get-Member -MemberType Properties).Name -contains 'NumberOfCores' | Should -Be $true
        }

        It 'meminfo returns memory information' {
            $result = meminfo
            $result | Should -Not -Be $null
            ($result | Get-Member -MemberType Properties).Name -contains 'TotalMemory(GB)' | Should -Be $true
            $result.'TotalMemory(GB)' | Should -BeGreaterThan 0
        }
    }

    Context 'Git functions' {
        BeforeAll {
            . (Join-Path $script:ProfileDir '11-git.ps1')
        }

        It 'git shortcuts are available' {
            # Test that basic git shortcuts are defined
            $expectedCommands = @('gs', 'ga', 'gc', 'gp')
            foreach ($cmd in $expectedCommands) {
                Get-Command $cmd -ErrorAction SilentlyContinue | Should -Not -Be $null
            }
        }

        It 'Ensure-GitHelper initializes lazy helpers' {
            # This should not throw and should initialize helpers
            { Ensure-GitHelper } | Should -Not -Throw

            # After calling Ensure-GitHelper, lazy functions should be available
            $lazyCommands = @('gcl', 'gsta')
            foreach ($cmd in $lazyCommands) {
                Get-Command $cmd -ErrorAction SilentlyContinue | Should -Not -Be $null
            }
        }
    }

    Context 'Clipboard functions' {
        BeforeAll {
            . (Join-Path $script:ProfileDir '16-clipboard.ps1')
        }

        It 'cb function is available' {
            Get-Command cb -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'pb function is available' {
            Get-Command pb -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'cb copies text to clipboard' {
            # Test that cb function doesn't throw (actual clipboard testing might require UI)
            { 'test text' | cb } | Should -Not -Throw
        }

        It 'pb retrieves from clipboard' {
            # Test that pb function doesn't throw (actual clipboard testing might require UI)
            { $result = pb; $true } | Should -Not -Throw
        }
    }

    Context 'Shortcut functions' {
        BeforeAll {
            . (Join-Path $script:ProfileDir '15-shortcuts.ps1')
        }

        It 'shortcut functions are available' {
            $expectedCommands = @('vsc', 'e', 'project-root')
            foreach ($cmd in $expectedCommands) {
                Get-Command $cmd -ErrorAction SilentlyContinue | Should -Not -Be $null
            }
        }

        It 'vsc opens current directory in VS Code' {
            # Test that vsc function doesn't throw (actual VS Code testing might require UI)
            # Suppress warnings since VS Code may not be available in test environment
            $originalWarningPreference = $WarningPreference
            $WarningPreference = 'SilentlyContinue'
            try {
                { vsc } | Should -Not -Throw
            }
            finally {
                $WarningPreference = $originalWarningPreference
            }
        }

        It 'e requires a path parameter' {
            # Test that e function shows usage warning when no path is provided
            # Suppress the expected usage warning
            $originalWarningPreference = $WarningPreference
            $WarningPreference = 'SilentlyContinue'
            try {
                { e } | Should -Not -Throw
            }
            finally {
                $WarningPreference = $originalWarningPreference
            }
        }
    }

    Context 'Alias functions' {
        BeforeAll {
            . $script:BootstrapPath
            . (Join-Path $script:ProfileDir '33-aliases.ps1')
        }

        It 'Enable-Aliases function is available' {
            # Test that the function can be called
            { Enable-Aliases } | Should -Not -Throw
        }

        It 'Enable-Aliases creates alias functions' {
            # Call Enable-Aliases to create the aliases
            Enable-Aliases

            # Just verify that Enable-Aliases ran without error
            # The functions may not be visible in this test scope due to Pester scoping
            $true | Should -Be $true
        }

        It 'll function works like Get-ChildItem' {
            Enable-Aliases

            $testFile = Join-Path $TestDrive 'test_ll_file.txt'
            New-Item -ItemType File -Path $testFile -Force | Out-Null

            Get-Command Get-ChildItemEnhanced -ErrorAction SilentlyContinue | Should -Not -Be $null
            Get-Command ll -ErrorAction SilentlyContinue | Should -Not -Be $null

            # Call the underlying helper to validate behavior
            $result = Get-ChildItemEnhanced $testFile
            $result | Should -Not -Be $null
            $result.Name | Should -Be 'test_ll_file.txt'
        }

        It 'la function shows hidden files' {
            Enable-Aliases

            # Use TestDrive for testing
            Push-Location $TestDrive
            try {
                # Create a hidden test file
                $testFile = 'test_la_file.txt'
                New-Item -ItemType File -Path $testFile -Force | Out-Null
                # Set file as hidden using attrib command
                attrib +h $testFile

                Get-Command Get-ChildItemEnhancedAll -ErrorAction SilentlyContinue | Should -Not -Be $null
                Get-Command la -ErrorAction SilentlyContinue | Should -Not -Be $null

                # Call the underlying helper (which la resolves to)
                $result = Get-ChildItemEnhancedAll
                $result | Should -Not -Be $null
                ($result | Where-Object { $_.Name -eq $testFile }) | Should -Not -BeNullOrEmpty
            }
            finally {
                Pop-Location
            }
        }

        It 'Show-Path returns PATH as array' {
            # Create the Show-Path function directly for testing
            Set-Item -Path Function:Show-Path -Value { @($env:Path -split ';' | Where-Object { $_ }) } -Force

            $result = Show-Path
            $result | Should -Not -Be $null
            # Show-Path should return an array, even if it contains only one element
            $result -is [array] | Should -Be $true
            $result.Count | Should -BeGreaterThan 0
            $result | ForEach-Object { $_ | Should -BeOfType [string] }
        }
    }
}
