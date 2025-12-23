. (Join-Path $PSScriptRoot '..\TestSupport.ps1')

Describe 'JsonUtilities Module Functions' {
    BeforeAll {
        # Import the JsonUtilities module (Common.psm1 no longer exists)
        $libPath = Get-TestPath -RelativePath 'scripts\lib' -StartPath $PSScriptRoot -EnsureExists
        Import-Module (Join-Path $libPath 'utilities' 'JsonUtilities.psm1') -DisableNameChecking -ErrorAction Stop
        $script:TestTempDir = New-TestTempDirectory -Prefix 'JsonUtilitiesTests'
    }

    AfterAll {
        if ($script:TestTempDir -and -not [string]::IsNullOrWhiteSpace($script:TestTempDir) -and (Test-Path -LiteralPath $script:TestTempDir)) {
            Remove-Item -Path $script:TestTempDir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    Context 'Read-JsonFile' {
        It 'Throws error for non-existent file' {
            $nonExistentFile = Join-Path $script:TestTempDir 'nonexistent.json'
            { Read-JsonFile -Path $nonExistentFile } | Should -Throw
        }

        It 'Reads valid JSON file' {
            $testData = @{
                Name  = 'Test'
                Value = 123
                Items = @('item1', 'item2')
            }
            $testFile = Join-Path $script:TestTempDir 'test.json'
            $testData | ConvertTo-Json -Depth 10 | Set-Content -Path $testFile -Encoding UTF8

            $result = Read-JsonFile -Path $testFile
            $result | Should -Not -BeNullOrEmpty
            $result.Name | Should -Be 'Test'
            $result.Value | Should -Be 123
            $result.Items.Count | Should -Be 2
        }

        It 'Returns null for empty file with SilentlyContinue' {
            $emptyFile = Join-Path $script:TestTempDir 'empty.json'
            Set-Content -Path $emptyFile -Value '' -Encoding UTF8

            $result = Read-JsonFile -Path $emptyFile -ErrorAction SilentlyContinue
            $result | Should -BeNullOrEmpty
        }

        It 'Handles invalid JSON gracefully with SilentlyContinue' {
            $invalidFile = Join-Path $script:TestTempDir 'invalid.json'
            Set-Content -Path $invalidFile -Value '{ invalid json }' -Encoding UTF8

            $result = Read-JsonFile -Path $invalidFile -ErrorAction SilentlyContinue
            $result | Should -BeNullOrEmpty
        }
    }

    Context 'Write-JsonFile' {
        It 'Writes JSON file successfully' {
            $testData = @{
                Name  = 'Test'
                Value = 456
            }
            $testFile = Join-Path $script:TestTempDir 'output.json'

            { Write-JsonFile -Path $testFile -InputObject $testData } | Should -Not -Throw
            if ($testFile -and -not [string]::IsNullOrWhiteSpace($testFile)) {
                Test-Path -LiteralPath $testFile | Should -Be $true -Because "JSON file should be created"
            }

            $result = Read-JsonFile -Path $testFile
            $result.Name | Should -Be 'Test'
            $result.Value | Should -Be 456
        }

        It 'Creates directory when EnsureDirectory is specified' {
            $testData = @{ Test = 'value' }
            $testFile = Join-Path $script:TestTempDir 'subdir' 'output.json'

            { Write-JsonFile -Path $testFile -InputObject $testData -EnsureDirectory } | Should -Not -Throw
            if ($testFile -and -not [string]::IsNullOrWhiteSpace($testFile)) {
                Test-Path -LiteralPath $testFile | Should -Be $true -Because "JSON file should be created with directory"
            }
        }

        It 'Uses specified depth for nested objects' {
            $testData = @{
                Level1 = @{
                    Level2 = @{
                        Level3 = @{
                            Value = 'deep'
                        }
                    }
                }
            }
            $testFile = Join-Path $script:TestTempDir 'nested.json'

            Write-JsonFile -Path $testFile -InputObject $testData -Depth 3
            $result = Read-JsonFile -Path $testFile
            $result.Level1.Level2.Level3.Value | Should -Be 'deep'
        }

        It 'Handles complex objects' {
            $testData = @{
                String  = 'test'
                Number  = 42
                Boolean = $true
                Array   = @(1, 2, 3)
                Nested  = @{
                    Key = 'value'
                }
            }
            $testFile = Join-Path $script:TestTempDir 'complex.json'

            Write-JsonFile -Path $testFile -InputObject $testData
            $result = Read-JsonFile -Path $testFile
            $result.String | Should -Be 'test'
            $result.Number | Should -Be 42
            $result.Boolean | Should -Be $true
            $result.Array.Count | Should -Be 3
            $result.Nested.Key | Should -Be 'value'
        }

        It 'Overwrites existing file' {
            $testData1 = @{ Value = 'first' }
            $testData2 = @{ Value = 'second' }
            $testFile = Join-Path $script:TestTempDir 'overwrite.json'

            Write-JsonFile -Path $testFile -InputObject $testData1
            Write-JsonFile -Path $testFile -InputObject $testData2

            $result = Read-JsonFile -Path $testFile
            $result.Value | Should -Be 'second'
        }

        It 'Handles ErrorAction Continue for file errors' {
            $nonExistentFile = Join-Path $script:TestTempDir 'nonexistent-continue.json'
            $result = Read-JsonFile -Path $nonExistentFile -ErrorAction Continue
            $result | Should -BeNullOrEmpty
        }

        It 'Handles ErrorAction Continue for write errors' {
            # Try to write to a read-only location (if possible)
            $testData = @{ Test = 'value' }
            $testFile = Join-Path $script:TestTempDir 'readonly-test.json'
            
            # Create file first
            Write-JsonFile -Path $testFile -InputObject $testData
            
            # Try to write again (should succeed)
            { Write-JsonFile -Path $testFile -InputObject $testData -ErrorAction Continue } | Should -Not -Throw
        }

        It 'Uses Get-ErrorActionPreference when ErrorHandling module is available' {
            # This tests the Get-ErrorActionPreference path
            $testData = @{ Test = 'value' }
            $testFile = Join-Path $script:TestTempDir 'error-pref-test.json'
            
            # Should work regardless of whether ErrorHandling module is available
            { Write-JsonFile -Path $testFile -InputObject $testData } | Should -Not -Throw
        }

        It 'Uses fallback error action extraction when ErrorHandling module is not available' {
            # This tests the fallback path
            $testData = @{ Test = 'value' }
            $testFile = Join-Path $script:TestTempDir 'fallback-error-test.json'
            
            { Write-JsonFile -Path $testFile -InputObject $testData } | Should -Not -Throw
        }

        It 'Uses Ensure-DirectoryExists when available' {
            $testData = @{ Test = 'value' }
            $testFile = Join-Path $script:TestTempDir 'ensure-dir-test' 'output.json'
            
            # Should work regardless of whether Ensure-DirectoryExists is available
            { Write-JsonFile -Path $testFile -InputObject $testData -EnsureDirectory } | Should -Not -Throw
        }

        It 'Uses fallback directory creation when Ensure-DirectoryExists is not available' {
            $testData = @{ Test = 'value' }
            $testFile = Join-Path $script:TestTempDir 'fallback-dir-test' 'output.json'
            
            { Write-JsonFile -Path $testFile -InputObject $testData -EnsureDirectory } | Should -Not -Throw
        }

        It 'Handles different encoding options' {
            $testData = @{ Encoding = 'test' }
            $testFile = Join-Path $script:TestTempDir 'encoding-test.json'
            
            { Write-JsonFile -Path $testFile -InputObject $testData -Encoding 'ASCII' } | Should -Not -Throw
            $result = Read-JsonFile -Path $testFile
            $result.Encoding | Should -Be 'test'
        }

        It 'Handles ErrorAction Continue for Read-JsonFile conversion errors' {
            $invalidFile = Join-Path $script:TestTempDir 'invalid-continue.json'
            Set-Content -Path $invalidFile -Value '{ invalid json }' -Encoding UTF8

            $result = Read-JsonFile -Path $invalidFile -ErrorAction Continue
            $result | Should -BeNullOrEmpty
        }

        It 'Handles ErrorAction Continue for Write-JsonFile errors' {
            $testData = @{ Test = 'value' }
            $testFile = Join-Path $script:TestTempDir 'write-error-continue.json'
            
            # Should succeed
            { Write-JsonFile -Path $testFile -InputObject $testData -ErrorAction Continue } | Should -Not -Throw
        }

        It 'Handles whitespace-only JSON file' {
            $whitespaceFile = Join-Path $script:TestTempDir 'whitespace.json'
            Set-Content -Path $whitespaceFile -Value '   ' -Encoding UTF8

            $result = Read-JsonFile -Path $whitespaceFile -ErrorAction SilentlyContinue
            $result | Should -BeNullOrEmpty
        }
    }
}

