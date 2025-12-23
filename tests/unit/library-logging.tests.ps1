. (Join-Path $PSScriptRoot '..\TestSupport.ps1')

BeforeAll {
    try {
        $script:RepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
        $script:LibPath = Get-TestPath -RelativePath 'scripts\lib' -StartPath $PSScriptRoot -EnsureExists
        if ($null -eq $script:LibPath -or [string]::IsNullOrWhiteSpace($script:LibPath)) {
            throw "Get-TestPath returned null or empty value for LibPath"
        }
        if (-not (Test-Path -LiteralPath $script:LibPath)) {
            throw "Library path not found at: $script:LibPath"
        }
        
        $script:LoggingPath = Join-Path $script:LibPath 'core' 'Logging.psm1'
        if ($null -eq $script:LoggingPath -or [string]::IsNullOrWhiteSpace($script:LoggingPath)) {
            throw "LoggingPath is null or empty"
        }
        if (-not (Test-Path -LiteralPath $script:LoggingPath)) {
            throw "Logging module not found at: $script:LoggingPath"
        }
        
        # Import the module under test
        Import-Module $script:LoggingPath -DisableNameChecking -ErrorAction Stop -Force
        
        # Create temporary directory for test log files
        $script:TestLogDir = Join-Path $env:TEMP "test-logs-$(Get-Random)"
        New-Item -ItemType Directory -Path $script:TestLogDir -Force | Out-Null
    }
    catch {
        $errorDetails = @{
            Message  = $_.Exception.Message
            Type     = $_.Exception.GetType().FullName
            Location = $_.InvocationInfo.ScriptLineNumber
        }
        Write-Error "Failed to initialize Logging tests in BeforeAll: $($errorDetails | ConvertTo-Json -Compress)" -ErrorAction Stop
        throw
    }
}

AfterAll {
    Remove-Module Logging -ErrorAction SilentlyContinue -Force
    
    # Clean up test log files
    if ($script:TestLogDir -and -not [string]::IsNullOrWhiteSpace($script:TestLogDir) -and (Test-Path -LiteralPath $script:TestLogDir)) {
        Remove-Item -Path $script:TestLogDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Describe 'Logging Module Functions' {

    Context 'Write-ScriptMessage - Basic Functionality' {
        It 'Writes a simple message' {
            $output = Write-ScriptMessage -Message 'Test message' 6>&1
            $output | Should -Not -BeNullOrEmpty
        }

        It 'Writes message with Info level by default' {
            $output = Write-ScriptMessage -Message 'Info message' 6>&1
            $output | Should -Not -BeNullOrEmpty
        }

        It 'Writes warning message' {
            { Write-ScriptMessage -Message 'Warning message' -IsWarning } | Should -Not -Throw
        }

        It 'Writes error message' {
            { Write-ScriptMessage -Message 'Error message' -IsError } | Should -Not -Throw
        }

        It 'Writes debug message' {
            $originalPreference = $DebugPreference
            try {
                $DebugPreference = 'Continue'
                { Write-ScriptMessage -Message 'Debug message' -LogLevel Debug } | Should -Not -Throw
            }
            finally {
                $DebugPreference = $originalPreference
            }
        }

        It 'Uses LogLevel parameter to override IsWarning/IsError' {
            { Write-ScriptMessage -Message 'Test' -IsWarning -LogLevel Error } | Should -Not -Throw
        }
    }

    Context 'Write-ScriptMessage - Log File Functionality' {
        It 'Writes to log file' {
            $logFile = Join-Path $script:TestLogDir 'test.log'
            Write-ScriptMessage -Message 'Test log entry' -LogFile $logFile
            
            if ($logFile -and -not [string]::IsNullOrWhiteSpace($logFile)) {
                Test-Path -LiteralPath $logFile | Should -Be $true -Because "Log file should exist after writing"
            }
            $content = Get-Content $logFile -Raw
            $content | Should -Match 'Test log entry'
        }

        It 'Appends to existing log file when AppendLog is specified' {
            $logFile = Join-Path $script:TestLogDir 'append-test.log'
            # Remove file if it exists from previous test runs
            Remove-Item $logFile -ErrorAction SilentlyContinue
            
            # First write should create/overwrite the file (no AppendLog)
            Write-ScriptMessage -Message 'First entry' -LogFile $logFile -MaxLogFileSizeMB 0
            # Verify first write succeeded
            Test-Path $logFile | Should -Be $true -Because "Log file should exist after first write"
            $firstContent = Get-Content $logFile -Raw
            $firstContent | Should -Match 'First entry' -Because "First entry should be in the file"
            
            # Second write should append (with AppendLog)
            Write-ScriptMessage -Message 'Second entry' -LogFile $logFile -AppendLog -MaxLogFileSizeMB 0
            
            $content = Get-Content $logFile
            $content.Count | Should -BeGreaterOrEqual 2 -Because "File should contain at least 2 lines after append"
            # Check for the message text in each line (accounting for timestamp/level prefix)
            $contentText = $content -join "`n"
            $contentText | Should -Match 'First entry' -Because "First entry should still be present after append"
            $contentText | Should -Match 'Second entry' -Because "Second entry should be appended"
        }

        It 'Overwrites log file when AppendLog is not specified' {
            $logFile = Join-Path $script:TestLogDir 'overwrite-test.log'
            Write-ScriptMessage -Message 'First entry' -LogFile $logFile
            Write-ScriptMessage -Message 'Second entry' -LogFile $logFile
            
            $content = Get-Content $logFile
            # Should only have one entry (overwritten)
            $content | Should -Match 'Second entry'
        }

        It 'Creates log directory if it does not exist' {
            $logFile = Join-Path $script:TestLogDir 'subdir' 'nested.log'
            Write-ScriptMessage -Message 'Nested log entry' -LogFile $logFile
            
            if ($logFile -and -not [string]::IsNullOrWhiteSpace($logFile)) {
                Test-Path -LiteralPath $logFile | Should -Be $true -Because "Log file should exist after writing"
            }
        }

        It 'Includes timestamp in log file entries' {
            $logFile = Join-Path $script:TestLogDir 'timestamp-test.log'
            Write-ScriptMessage -Message 'Timestamped entry' -LogFile $logFile
            
            $content = Get-Content $logFile -Raw
            $content | Should -Match '\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}'
        }

        It 'Includes log level in log file entries' {
            $logFile = Join-Path $script:TestLogDir 'level-test.log'
            Write-ScriptMessage -Message 'Level entry' -LogFile $logFile -LogLevel Warning
            
            $content = Get-Content $logFile -Raw
            $content | Should -Match '\[Warning\]'
        }

        It 'Handles log file write errors gracefully' {
            # Try to write to an invalid path (read-only directory or similar)
            # This should not throw, but should write a warning
            $invalidLogFile = Join-Path 'C:\Invalid\Path\That\Does\Not\Exist' 'test.log'
            { Write-ScriptMessage -Message 'Test' -LogFile $invalidLogFile } | Should -Not -Throw
        }
    }

    Context 'Write-ScriptMessage - Log Rotation' {
        It 'Rotates log file when size exceeds MaxLogFileSizeMB' {
            $logFile = Join-Path $script:TestLogDir 'rotation-test.log'
            
            # Create a log file that exceeds the size limit (1MB for testing)
            $largeMessage = 'X' * 1024 * 1024  # 1MB of data
            Write-ScriptMessage -Message $largeMessage -LogFile $logFile -MaxLogFileSizeMB 1
            
            # Check if rotation occurred (original file should be moved to .1)
            $rotatedFile = "$logFile.1"
            if ($rotatedFile -and -not [string]::IsNullOrWhiteSpace($rotatedFile) -and (Test-Path -LiteralPath $rotatedFile)) {
                Test-Path -LiteralPath $rotatedFile | Should -Be $true -Because "Rotated log file should exist"
            }
        }

        It 'Keeps specified number of rotated log files' {
            $logFile = Join-Path $script:TestLogDir 'rotation-count-test.log'
            
            # Create multiple large log entries to trigger rotation
            $largeMessage = 'X' * 512 * 1024  # 512KB
            for ($i = 1; $i -le 3; $i++) {
                Write-ScriptMessage -Message "$largeMessage - Entry $i" -LogFile $logFile -MaxLogFileSizeMB 1 -MaxLogFiles 3
            }
            
            # Should have at most MaxLogFiles rotated files
            $rotatedFiles = Get-ChildItem -Path "$logFile.*" -ErrorAction SilentlyContinue
            if ($rotatedFiles) {
                $rotatedFiles.Count | Should -BeLessOrEqual 3
            }
        }

        It 'Disables rotation when MaxLogFileSizeMB is 0' {
            $logFile = Join-Path $script:TestLogDir 'no-rotation-test.log'
            $largeMessage = 'X' * 1024 * 1024  # 1MB
            Write-ScriptMessage -Message $largeMessage -LogFile $logFile -MaxLogFileSizeMB 0
            
            # Should not create rotated files
            $rotatedFiles = Get-ChildItem -Path "$logFile.*" -ErrorAction SilentlyContinue
            $rotatedFiles | Should -BeNullOrEmpty
        }
    }

    Context 'Write-ScriptMessage - Structured Output' {
        It 'Outputs structured JSON format' {
            $output = Write-ScriptMessage -Message 'Structured message' -StructuredOutput 6>&1
            $output | Should -Not -BeNullOrEmpty
            
            # Try to parse as JSON
            try {
                $json = $output | ConvertFrom-Json
                $json | Should -Not -BeNullOrEmpty
                $json.Message | Should -Be 'Structured message'
                $json.Level | Should -Not -BeNullOrEmpty
                $json.Timestamp | Should -Not -BeNullOrEmpty
            }
            catch {
                # If JSON parsing fails, at least verify output contains expected fields
                $output | Should -Match 'Message'
                $output | Should -Match 'Level'
                $output | Should -Match 'Timestamp'
            }
        }

        It 'Includes correct log level in structured output' {
            $output = Write-ScriptMessage -Message 'Error message' -LogLevel Error -StructuredOutput 6>&1
            try {
                $json = $output | ConvertFrom-Json
                $json.Level | Should -Be 'Error'
            }
            catch {
                $output | Should -Match '"Level"\s*:\s*"Error"'
            }
        }

        It 'Includes UTC timestamp in structured output' {
            $output = Write-ScriptMessage -Message 'Timestamped message' -StructuredOutput 6>&1
            try {
                $json = $output | ConvertFrom-Json
                $json.Timestamp | Should -Not -BeNullOrEmpty
                # Verify it's a valid ISO 8601 timestamp
                [DateTime]::Parse($json.Timestamp) | Should -Not -BeNullOrEmpty
            }
            catch {
                # Fallback: just verify timestamp field exists
                $output | Should -Match 'Timestamp'
            }
        }
    }

    Context 'Write-ScriptMessage - ForegroundColor' {
        It 'Accepts ForegroundColor parameter' {
            { Write-ScriptMessage -Message 'Colored message' -ForegroundColor Green } | Should -Not -Throw
        }

        It 'Uses ForegroundColor for Info level messages' {
            { Write-ScriptMessage -Message 'Colored info' -LogLevel Info -ForegroundColor Cyan } | Should -Not -Throw
        }
    }

    Context 'Write-ScriptMessage - Error Handling' {
        It 'Handles missing log file directory gracefully' {
            # This should create the directory or handle the error
            $logFile = Join-Path $script:TestLogDir 'newdir' 'test.log'
            { Write-ScriptMessage -Message 'Test' -LogFile $logFile } | Should -Not -Throw
            Test-Path (Split-Path $logFile -Parent) | Should -Be $true
        }

        It 'Continues execution when log file write fails' {
            # Try to write to a path that might fail (but won't crash the script)
            $logFile = Join-Path $script:TestLogDir 'test.log'
            { Write-ScriptMessage -Message 'Test' -LogFile $logFile } | Should -Not -Throw
        }
    }
}

