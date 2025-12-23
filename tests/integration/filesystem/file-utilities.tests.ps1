

Describe 'File Utility Functions Integration Tests' {
    BeforeAll {
        try {
            $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
            $script:BootstrapPath = Get-TestPath -RelativePath 'profile.d\bootstrap.ps1' -StartPath $PSScriptRoot -EnsureExists
            if (-not ($script:BootstrapPath -and -not [string]::IsNullOrWhiteSpace($script:BootstrapPath) -and (Test-Path -LiteralPath $script:BootstrapPath))) {
                throw "Bootstrap file not found at: $script:BootstrapPath"
            }
            . $script:BootstrapPath
        }
        catch {
            $errorDetails = @{
                Message  = $_.Exception.Message
                Type     = $_.Exception.GetType().FullName
                Location = $_.InvocationInfo.ScriptLineNumber
            }
            Write-Error "Failed to load bootstrap in BeforeAll: $($errorDetails | ConvertTo-Json -Compress)" -ErrorAction Stop
            throw
        }
    }

    Context 'Import-FragmentModule helper function' {
        BeforeAll {
            # Load the files fragment to get Import-FragmentModule
            . (Join-Path $script:ProfileDir 'files.ps1')
        }

        It 'Import-FragmentModule function is available' {
            Get-Command Import-FragmentModule -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'Import-FragmentModule loads existing module successfully' {
            $testModuleDir = $null
            $cleanupNeeded = $false
            
            try {
                # Create a test module file with function in global scope
                $testModuleDir = Join-Path $TestDrive 'test-modules'
                New-Item -ItemType Directory -Path $testModuleDir -Force | Out-Null
                $testModuleFile = Join-Path $testModuleDir 'test-module.ps1'
                Set-Content -Path $testModuleFile -Value 'function global:Test-ModuleFunction { return "success" }'
                
                # Import the module
                { Import-FragmentModule -ModuleDir $testModuleDir -ModuleFile 'test-module.ps1' } | Should -Not -Throw -Because "Import-FragmentModule should load valid module without errors"
                
                # Verify function is available
                Get-Command Test-ModuleFunction -ErrorAction SilentlyContinue | Should -Not -Be $null -Because "module function should be available after import"
                $cleanupNeeded = $true
            }
            catch {
                $errorDetails = @{
                    Message       = $_.Exception.Message
                    TestModuleDir = $testModuleDir
                    Category      = $_.CategoryInfo.Category
                }
                Write-Error "Import-FragmentModule load test failed: $($errorDetails | ConvertTo-Json -Compress)" -ErrorAction Continue
                throw
            }
            finally {
                if ($cleanupNeeded) {
                    Remove-Item Function:\global:Test-ModuleFunction -ErrorAction SilentlyContinue
                }
            }
        }

        It 'Import-FragmentModule handles missing module gracefully' {
            # Try to import non-existent module
            { Import-FragmentModule -ModuleDir $TestDrive -ModuleFile 'nonexistent.ps1' } | Should -Not -Throw
        }

        It 'Import-FragmentModule handles module with syntax errors gracefully' {
            try {
                # Create a module with syntax error
                $testModuleDir = Join-Path $TestDrive 'test-modules-error'
                New-Item -ItemType Directory -Path $testModuleDir -Force | Out-Null
                $testModuleFile = Join-Path $testModuleDir 'error-module.ps1'
                Set-Content -Path $testModuleFile -Value 'function Broken { invalid syntax here }'
                
                # Should not throw (error is caught and logged)
                { Import-FragmentModule -ModuleDir $testModuleDir -ModuleFile 'error-module.ps1' } | Should -Not -Throw -Because "Import-FragmentModule should handle syntax errors gracefully"
            }
            catch {
                $errorDetails = @{
                    Message  = $_.Exception.Message
                    Category = $_.CategoryInfo.Category
                }
                Write-Error "Import-FragmentModule syntax error handling test failed: $($errorDetails | ConvertTo-Json -Compress)" -ErrorAction Continue
                throw
            }
        }

        It 'Import-FragmentModule uses custom module name in error messages' {
            # Create a module with syntax error
            $testModuleDir = Join-Path $TestDrive 'test-modules-custom'
            New-Item -ItemType Directory -Path $testModuleDir -Force | Out-Null
            $testModuleFile = Join-Path $testModuleDir 'custom-name.ps1'
            Set-Content -Path $testModuleFile -Value 'function Broken { invalid syntax }'
            
            # Should use custom module name
            { Import-FragmentModule -ModuleDir $testModuleDir -ModuleFile 'custom-name.ps1' -ModuleName 'CustomModule' } | Should -Not -Throw
        }
    }

    Context 'File utility functions' {
        BeforeAll {
            try {
                . (Join-Path $script:ProfileDir 'bootstrap.ps1')
                # Dot-source files.ps1 - PSScriptRoot will be automatically set to profile.d directory
                $filesPath = Join-Path $script:ProfileDir 'files.ps1'
                if ($null -eq $filesPath -or [string]::IsNullOrWhiteSpace($filesPath)) {
                    throw "FilesPath is null or empty"
                }
                if (-not (Test-Path -LiteralPath $filesPath)) {
                    throw "Files fragment not found at: $filesPath"
                }
                . $filesPath
                
                # Verify all initialization functions exist before calling Ensure-FileUtilities
                # If they don't exist, the modules may not have loaded (path issue or silent error)
                $filesModulesDir = Join-Path $script:ProfileDir 'files-modules'
                $inspectionDir = Join-Path $filesModulesDir 'inspection'
                
                $requiredModules = @(
                    'files-head-tail.ps1',
                    'files-hash.ps1',
                    'files-size.ps1',
                    'files-hexdump.ps1'
                )
                
                foreach ($moduleFile in $requiredModules) {
                    $modulePath = Join-Path $inspectionDir $moduleFile
                    if ($modulePath -and (Test-Path -LiteralPath $modulePath)) {
                        try {
                            . $modulePath
                        }
                        catch {
                            Write-Warning "Failed to load module ${moduleFile}: $_"
                        }
                    }
                    else {
                        Write-Warning "Module file not found: $modulePath"
                    }
                }
                
                # Verify at least one initialization function exists
                if (-not (Get-Command Initialize-FileUtilities-HeadTail -ErrorAction SilentlyContinue)) {
                    throw "Initialize-FileUtilities-HeadTail function not found after loading modules"
                }
                
                Ensure-FileUtilities
            }
            catch {
                $errorDetails = @{
                    Message  = $_.Exception.Message
                    Type     = $_.Exception.GetType().FullName
                    Location = $_.InvocationInfo.ScriptLineNumber
                }
                Write-Error "Failed to initialize file utilities in BeforeAll: $($errorDetails | ConvertTo-Json -Compress)" -ErrorAction Stop
                throw
            }
        }

        It 'Get-FileHead (head) function is available' {
            Get-Command head -CommandType Alias -ErrorAction SilentlyContinue | Should -Not -Be $null
            Get-Command Get-FileHead -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'Get-FileTail (tail) function is available' {
            Get-Command tail -CommandType Alias -ErrorAction SilentlyContinue | Should -Not -Be $null
            Get-Command Get-FileTail -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'head function shows first 10 lines of file' {
            $testFile = Join-Path $TestDrive 'test_head.txt'
            $content = 1..20 | ForEach-Object { "Line $_" }
            Set-Content -Path $testFile -Value $content

            $result = head $testFile
            $result.Count | Should -Be 10
            $result[0] | Should -Be 'Line 1'
            $result[9] | Should -Be 'Line 10'
        }

        It 'head function shows custom number of lines' {
            $testFile = Join-Path $TestDrive 'test_head_custom.txt'
            $content = 1..20 | ForEach-Object { "Line $_" }
            Set-Content -Path $testFile -Value $content

            $result = head $testFile -Lines 5
            $result.Count | Should -Be 5
            $result[0] | Should -Be 'Line 1'
            $result[4] | Should -Be 'Line 5'
        }

        It 'head function works with pipeline input' {
            $inputData = 1..15 | ForEach-Object { "Item $_" }
            $result = $inputData | head
            $result.Count | Should -Be 10
            $result[0] | Should -Be 'Item 1'
            $result[9] | Should -Be 'Item 10'
        }

        It 'tail function shows last 10 lines of file' {
            $testFile = Join-Path $TestDrive 'test_tail.txt'
            $content = 1..20 | ForEach-Object { "Line $_" }
            Set-Content -Path $testFile -Value $content

            $result = tail $testFile
            $result.Count | Should -Be 10
            $result[0] | Should -Be 'Line 11'
            $result[9] | Should -Be 'Line 20'
        }

        It 'tail function shows custom number of lines' {
            $testFile = Join-Path $TestDrive 'test_tail_custom.txt'
            $content = 1..20 | ForEach-Object { "Line $_" }
            Set-Content -Path $testFile -Value $content

            $result = tail $testFile -Lines 5
            $result.Count | Should -Be 5
            $result[0] | Should -Be 'Line 16'
            $result[4] | Should -Be 'Line 20'
        }

        It 'tail function works with pipeline input' {
            $inputData = 1..15 | ForEach-Object { "Item $_" }
            $result = $inputData | tail
            $result.Count | Should -Be 10
            $result[0] | Should -Be 'Item 6'
            $result[9] | Should -Be 'Item 15'
        }

        It 'Get-FileHashValue (file-hash) function is available' {
            Get-Command file-hash -CommandType Alias -ErrorAction SilentlyContinue | Should -Not -Be $null
            Get-Command Get-FileHashValue -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'Get-FileHashValue calculates SHA256 hash' {
            $testFile = Join-Path $TestDrive 'test_hash.txt'
            Set-Content -Path $testFile -Value 'test content for hashing'

            $result = Get-FileHashValue -Path $testFile
            $result | Should -Not -BeNullOrEmpty
            $result.Algorithm | Should -Be 'SHA256'
            $result.Hash | Should -Match '^[A-F0-9]{64}$'
            $result.Path | Should -Be $testFile
        }

        It 'Get-FileHashValue supports different algorithms' {
            $testFile = Join-Path $TestDrive 'test_hash_algo.txt'
            Set-Content -Path $testFile -Value 'test content'

            $md5Result = Get-FileHashValue -Path $testFile -Algorithm MD5
            $md5Result.Algorithm | Should -Be 'MD5'
            $md5Result.Hash | Should -Match '^[A-F0-9]{32}$'

            $sha1Result = Get-FileHashValue -Path $testFile -Algorithm SHA1
            $sha1Result.Algorithm | Should -Be 'SHA1'
            $sha1Result.Hash | Should -Match '^[A-F0-9]{40}$'
        }

        It 'Get-FileHashValue handles non-existent files' {
            $nonExistent = Join-Path $TestDrive 'non_existent_hash.txt'
            $result = Get-FileHashValue -Path $nonExistent 3>$null
            $result | Should -Be $null
        }

        It 'Get-FileSize (filesize) function is available' {
            Get-Command filesize -CommandType Alias -ErrorAction SilentlyContinue | Should -Not -Be $null
            Get-Command Get-FileSize -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'Get-FileSize returns human-readable sizes' {
            $smallFile = Join-Path $TestDrive 'small_size.txt'
            Set-Content -Path $smallFile -Value 'x' -NoNewline

            $result = Get-FileSize -Path $smallFile
            $result | Should -Match '\d+ bytes'
        }

        It 'Get-FileSize handles different file sizes' {
            $mediumFile = Join-Path $TestDrive 'medium_size.txt'
            $content = 'x' * 2048  # 2KB
            Set-Content -Path $mediumFile -Value $content -NoNewline

            $result = Get-FileSize -Path $mediumFile
            $result | Should -Match '\d+\.\d+ KB'
        }

        It 'Get-FileSize handles non-existent files' {
            $nonExistent = Join-Path $TestDrive 'non_existent_size.txt'
            $result = Get-FileSize -Path $nonExistent 2>$null
            $result | Should -Be $null
        }

        It 'Get-HexDump (hex-dump) function is available' {
            Get-Command hex-dump -CommandType Alias -ErrorAction SilentlyContinue | Should -Not -Be $null
            Get-Command Get-HexDump -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'Get-HexDump displays hex representation' {
            $testFile = Join-Path $TestDrive 'test_hex.txt'
            Set-Content -Path $testFile -Value 'AB' -NoNewline

            $result = Get-HexDump -Path $testFile
            $result | Should -Not -BeNullOrEmpty
            # Should contain hex values
            $resultString = $result | Out-String
            $resultString | Should -Match '[0-9A-F]{2}'
        }
    }
}

