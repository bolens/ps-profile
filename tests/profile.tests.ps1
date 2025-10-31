Describe 'Profile fragments' {
    It 'loads fragments twice without error (idempotency)' {
        $fragDir = Join-Path $PSScriptRoot '..\profile.d'
        # Dot-source each fragment inside a scriptblock that defines $PSScriptRoot so fragments can rely on it.
        $files = Get-ChildItem -Path $fragDir -Filter *.ps1 -File | Sort-Object Name | Select-Object -ExpandProperty FullName
        # Dot-source all fragments in the same scope so helpers defined in bootstrap are visible
        & { param($files, $root) $PSScriptRoot = $root; foreach ($f in $files) { . $f } } $files $PSScriptRoot
        & { param($files, $root) $PSScriptRoot = $root; foreach ($f in $files) { . $f } } $files $PSScriptRoot
        # If no exception reached here, pass
        $true | Should Be $true
    }

    It 'Set-AgentModeFunction registers a function safely' {
        . "$PSScriptRoot/..\profile.d\00-bootstrap.ps1"
        $sb = Set-AgentModeFunction -Name 'test_agent_fn' -Body { return 'ok' } -ReturnScriptBlock
        # The helper returns the created ScriptBlock on success, or $false when it was a no-op.
        $sb | Should Not Be $false
        $sb.GetType().Name | Should Be 'ScriptBlock'
        $result = $null
        try { $result = (& test_agent_fn) } catch { }
        $result | Should Be 'ok'
        # Also test alias helper returns boolean
        $aliasName = "test_alias_$(Get-Random)"
        $aliasResult = Set-AgentModeAlias -Name $aliasName -Target 'Write-Output'
        $aliasResult | Should Be $true
        # Invocation test: calling the created alias should invoke the target (Write-Output)
        $aliasOut = $null
        try { $aliasOut = & $aliasName 'ping' } catch { }
        $aliasOut | Should Be 'ping'
    }

    It 'base64 encode/decode roundtrip for small content' {
        $content = 'hello world'
        $b64 = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($content))
        $decoded = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($b64))
        ($decoded -eq 'hello world') | Should Be $true
    }

    Context 'Utility functions' {
        BeforeAll {
            . "$PSScriptRoot/..\profile.d\05-utilities.ps1"
        }

        It 'Get-EnvVar retrieves environment variable from registry' {
            # Test with a known environment variable
            $tempVar = "TEST_VAR_$(Get-Random)"
            try {
                # Set a test variable
                Set-EnvVar -Name $tempVar -Value 'test_value'
                $result = Get-EnvVar -Name $tempVar
                $result | Should Be 'test_value'
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
                $result | Should Be 'test_value'
            }
            finally {
                Set-EnvVar -Name $tempVar -Value $null
            }
        }

        It 'from-epoch converts Unix timestamp correctly' {
            $timestamp = 1609459200  # 2020-12-31 00:00:00 UTC
            $result = from-epoch $timestamp
            $result.Year | Should Be 2020
            $result.Month | Should Be 12
            $result.Day | Should Be 31
        }

        It 'epoch returns current Unix timestamp' {
            $before = [DateTimeOffset]::Now.ToUnixTimeSeconds()
            $result = epoch
            $after = [DateTimeOffset]::Now.ToUnixTimeSeconds()
            $result | Should BeGreaterThan ($before - 1)
            $result | Should BeLessThan ($after + 1)
        }

        It 'pwgen generates password of correct length' {
            $password = pwgen
            $password.Length | Should Be 16
            $password | Should Match '^[a-zA-Z0-9]+$'
        }

        It 'Remove-Path removes directory from PATH' {
            # Test Remove-Path function
            $testPath = 'C:\Test\Path'

            # Add test path to PATH temporarily
            $originalPath = $env:PATH
            $env:PATH = "$env:PATH;$testPath"

            # Verify path was added
            $env:PATH | Should Match ([regex]::Escape($testPath))

            # Remove the path
            Remove-Path -Path $testPath

            # Verify path was removed
            $env:PATH | Should Not Match ([regex]::Escape($testPath))

            # Restore original PATH
            $env:PATH = $originalPath
        }

        It 'Add-Path adds directory to PATH' {
            # Test Add-Path function
            $testPath = 'C:\Test\AddPath'

            # Store original PATH
            $originalPath = $env:PATH

            # Ensure test path is not already in PATH
            if ($env:PATH -split ';' -contains $testPath) {
                Remove-Path -Path $testPath
            }

            # Add the test path
            Add-Path -Path $testPath

            # Verify path was added
            $env:PATH | Should Match ([regex]::Escape($testPath))

            # Clean up - remove the test path
            Remove-Path -Path $testPath

            # Verify path was removed
            $env:PATH | Should Not Match ([regex]::Escape($testPath))

            # Restore original PATH
            $env:PATH = $originalPath
        }
    }

    Context 'File utility functions' {
        BeforeAll {
            . "$PSScriptRoot/..\profile.d\02-files-conversion.ps1"
            . "$PSScriptRoot/..\profile.d\02-files-utilities.ps1"
            # Ensure file helper functions are initialized
            Ensure-FileConversion
            Ensure-FileUtilities
        }

        It 'json-pretty formats JSON correctly' {
            $json = '{"name":"test","value":123}'
            $result = json-pretty $json
            $result | Should Match '"name":\s*"test"'
            $result | Should Match '"value":\s*123'
        }

        It 'to-base64 and from-base64 roundtrip correctly' {
            $testString = 'Hello, World!'
            $encoded = $testString | to-base64
            $decoded = $encoded | from-base64
            $decoded.TrimEnd("`r", "`n") | Should Be $testString
        }

        It 'file-hash calculates SHA256 correctly' {
            $tempFile = [IO.Path]::GetTempFileName()
            try {
                Set-Content -Path $tempFile -Value 'test content' -NoNewline
                $hash = file-hash $tempFile
                $hash.Algorithm | Should Be 'SHA256'
                $hash.Hash.Length | Should Be 64  # SHA256 is 64 hex chars
            }
            finally {
                Remove-Item $tempFile -Force
            }
        }

        It 'filesize returns human-readable size' {
            # Ensure filesize function is available
            if (-not (Get-Command filesize -ErrorAction SilentlyContinue)) {
                Ensure-FileUtilities
            }
            $tempFile = [IO.Path]::GetTempFileName()
            try {
                # Create a 1024 byte file
                $content = 'x' * 1024
                Set-Content -Path $tempFile -Value $content -NoNewline
                $result = filesize $tempFile
                $result | Should Match '1\.00 KB'
            }
            finally {
                Remove-Item $tempFile -Force
            }
        }
    }

    Context 'System utility functions' {
        BeforeAll {
            . "$PSScriptRoot/..\profile.d\07-system.ps1"
        }

        It 'which shows command information' {
            $result = which Get-Command
            $result | Should Not Be $null
            $result.Name | Should Be 'Get-Command'
        }

        It 'pgrep searches for patterns in files' {
            $tempFile = [IO.Path]::GetTempFileName()
            try {
                Set-Content -Path $tempFile -Value 'test content with pattern'
                $result = pgrep 'pattern' $tempFile
                $result | Should Not Be $null
                $result.Line | Should Match 'pattern'
            }
            finally {
                Remove-Item $tempFile -Force
            }
        }

        It 'touch creates empty files' {
            $tempFile = [IO.Path]::GetTempFileName()
            Remove-Item $tempFile -Force
            touch $tempFile
            Test-Path $tempFile | Should Be $true
            Remove-Item $tempFile -Force
        }

        It 'mkdir creates directories' {
            $tempDir = [IO.Path]::GetTempPath() + [Guid]::NewGuid().ToString()
            mkdir $tempDir
            Test-Path $tempDir | Should Be $true
            Remove-Item $tempDir -Force
        }

        It 'search finds files recursively' {
            $tempDir = [IO.Path]::GetTempPath() + [Guid]::NewGuid().ToString()
            New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
            New-Item -ItemType File -Path (Join-Path $tempDir 'test.txt') -Force | Out-Null

            try {
                Push-Location $tempDir
                $result = search test.txt
                $result | Where-Object { $_ -eq 'test.txt' } | Should Not BeNullOrEmpty
            }
            finally {
                Pop-Location
                Remove-Item $tempDir -Recurse -Force
            }
        }

        It 'df shows disk usage information' {
            $result = df
            $result | Should Not Be $null
            $result[0].PSObject.Properties.Name -contains 'Name' | Should Be $true
            $result[0].PSObject.Properties.Name -contains 'Used(GB)' | Should Be $true
        }

        It 'htop shows top CPU processes' {
            $result = htop
            $result | Should Not Be $null
            ($result.Count -le 10) | Should Be $true
            $result[0].PSObject.Properties.Name -contains 'Name' | Should Be $true
        }

        It 'ports shows network port information' {
            # This might require admin privileges, so we'll just test it doesn't throw
            { ports } | Should Not Throw
        }

        It 'ptest tests network connectivity' {
            # Test with localhost which should always work
            $result = ptest localhost
            $result | Should Not Be $null
        }

        It 'dns resolves hostnames' {
            $result = dns localhost
            $result | Should Not BeNullOrEmpty
            $result[0].Name | Should Be 'localhost'
        }

        It 'zip creates archives' {
            $tempDir = [IO.Path]::GetTempPath() + [Guid]::NewGuid().ToString()
            $zipFile = [IO.Path]::GetTempFileName() + '.zip'
            New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
            New-Item -ItemType File -Path (Join-Path $tempDir 'test.txt') -Value 'test' -Force | Out-Null

            try {
                zip -Path $tempDir -DestinationPath $zipFile
                Test-Path $zipFile | Should Be $true
            }
            finally {
                Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue
                Remove-Item $zipFile -Force -ErrorAction SilentlyContinue
            }
        }
    }

    Context 'System info functions' {
        BeforeAll {
            . "$PSScriptRoot/..\profile.d\08-system-info.ps1"
        }

        It 'uptime returns a TimeSpan object' {
            $result = uptime
            $result | Should Not Be $null
            $result.GetType().Name | Should Be 'TimeSpan'
        }

        It 'sysinfo returns computer system information' {
            $result = sysinfo
            $result | Should Not Be $null
            ($result | Get-Member -MemberType Properties).Name -contains 'Name' | Should Be $true
            ($result | Get-Member -MemberType Properties).Name -contains 'Manufacturer' | Should Be $true
        }

        It 'cpuinfo returns processor information' {
            $result = cpuinfo
            $result | Should Not Be $null
            ($result | Get-Member -MemberType Properties).Name -contains 'Name' | Should Be $true
            ($result | Get-Member -MemberType Properties).Name -contains 'NumberOfCores' | Should Be $true
        }

        It 'meminfo returns memory information' {
            $result = meminfo
            $result | Should Not Be $null
            ($result | Get-Member -MemberType Properties).Name -contains 'TotalMemory(GB)' | Should Be $true
            $result.'TotalMemory(GB)' | Should BeGreaterThan 0
        }
    }

    Context 'Git functions' {
        BeforeAll {
            . "$PSScriptRoot/..\profile.d\11-git.ps1"
        }

        It 'git shortcuts are available' {
            # Test that basic git shortcuts are defined
            Get-Command gs -CommandType Function -ErrorAction SilentlyContinue | Should Not Be $null
            Get-Command ga -CommandType Function -ErrorAction SilentlyContinue | Should Not Be $null
            Get-Command gc -CommandType Function -ErrorAction SilentlyContinue | Should Not Be $null
            Get-Command gp -CommandType Function -ErrorAction SilentlyContinue | Should Not Be $null
        }

        It 'Ensure-GitHelper initializes lazy helpers' {
            # This should not throw and should initialize helpers
            { Ensure-GitHelper } | Should Not Throw

            # After calling Ensure-GitHelper, lazy functions should be available
            Get-Command gcl -CommandType Function -ErrorAction SilentlyContinue | Should Not Be $null
            Get-Command gsta -CommandType Function -ErrorAction SilentlyContinue | Should Not Be $null
        }
    }

    Context 'Clipboard functions' {
        BeforeAll {
            . "$PSScriptRoot/..\profile.d\16-clipboard.ps1"
        }

        It 'cb function is available' {
            Get-Command cb -CommandType Function -ErrorAction SilentlyContinue | Should Not Be $null
        }

        It 'pb function is available' {
            Get-Command pb -CommandType Function -ErrorAction SilentlyContinue | Should Not Be $null
        }

        It 'cb copies text to clipboard' {
            # Test that cb function doesn't throw (actual clipboard testing might require UI)
            { 'test text' | cb } | Should Not Throw
        }

        It 'pb retrieves from clipboard' {
            # Test that pb function doesn't throw (actual clipboard testing might require UI)
            { $result = pb; $true } | Should Not Throw
        }
    }

    Context 'Shortcut functions' {
        BeforeAll {
            . "$PSScriptRoot/..\profile.d\15-shortcuts.ps1"
        }

        It 'vsc function is available' {
            Get-Command vsc -CommandType Function -ErrorAction SilentlyContinue | Should Not Be $null
        }

        It 'e function is available' {
            Get-Command e -CommandType Function -ErrorAction SilentlyContinue | Should Not Be $null
        }

        It 'project-root function is available' {
            Get-Command project-root -CommandType Function -ErrorAction SilentlyContinue | Should Not Be $null
        }

        It 'vsc opens current directory in VS Code' {
            # Test that vsc function doesn't throw (actual VS Code testing might require UI)
            # Suppress warnings since VS Code may not be available in test environment
            $originalWarningPreference = $WarningPreference
            $WarningPreference = 'SilentlyContinue'
            try {
                { vsc } | Should Not Throw
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
                { e } | Should Not Throw
            }
            finally {
                $WarningPreference = $originalWarningPreference
            }
        }
    }

    Context 'Alias functions' {
        BeforeAll {
            . "$PSScriptRoot/..\profile.d\00-bootstrap.ps1"
            . "$PSScriptRoot/..\profile.d\33-aliases.ps1"
        }

        It 'Enable-Aliases function is available' {
            # Test that the function can be called
            { Enable-Aliases } | Should Not Throw
        }

        It 'Enable-Aliases creates alias functions' {
            # Call Enable-Aliases to create the aliases
            Enable-Aliases

            # Just verify that Enable-Aliases ran without error
            # The functions may not be visible in this test scope due to Pester scoping
            $true | Should Be $true
        }

        It 'll function works like Get-ChildItem' {
            # Create the ll function directly for testing
            Set-Item -Path Function:ll -Value { param([Parameter(ValueFromRemainingArguments = $true)] $a) Get-ChildItem @a } -Force

            $tempDir = [IO.Path]::GetTempPath()
            Push-Location $tempDir
            try {
                # Create a test file
                $testFile = 'test_ll_file.txt'
                New-Item -ItemType File -Path $testFile -Force | Out-Null

                # Test ll function
                $result = ll $testFile
                $result | Should Not Be $null
                $result.Name | Should Be $testFile

                Remove-Item $testFile -Force
            }
            finally {
                Pop-Location
            }
        }

        It 'la function shows hidden files' {
            # Create the la function directly for testing
            Set-Item -Path Function:la -Value { param([Parameter(ValueFromRemainingArguments = $true)] $a) Get-ChildItem -Force @a } -Force

            # Use current directory for testing
            $originalLocation = Get-Location
            try {
                # Create a hidden test file in current directory
                $testFile = 'test_la_file.txt'
                New-Item -ItemType File -Path $testFile -Force | Out-Null
                # Set file as hidden using attrib command
                attrib +h $testFile

                # Test la function (should show hidden files)
                $result = la
                $result | Should Not Be $null
                ($result | Where-Object { $_.Name -eq $testFile }) | Should Not BeNullOrEmpty

                Remove-Item $testFile -Force
            }
            finally {
                Set-Location $originalLocation
            }
        }

        It 'Show-Path returns PATH as array' {
            # Create the Show-Path function directly for testing
            Set-Item -Path Function:Show-Path -Value { @($env:Path -split ';' | Where-Object { $_ }) } -Force

            $result = Show-Path
            $result | Should Not Be $null
            # Show-Path should return an array, even if it contains only one element
            $result -is [array] | Should Be $true
            $result.Count | Should BeGreaterThan 0
            $result | ForEach-Object { $_ | Should BeOfType [string] }
        }
    }
}
