. (Join-Path $PSScriptRoot '..\TestSupport.ps1')

Describe 'JsonUtilities Module Functions' {
    BeforeAll {
        # Import the JsonUtilities module (Common.psm1 no longer exists)
        $libPath = Get-TestPath -RelativePath 'scripts\lib' -StartPath $PSScriptRoot -EnsureExists
        Import-Module (Join-Path $libPath 'JsonUtilities.psm1') -DisableNameChecking -ErrorAction Stop
        $script:TestTempDir = New-TestTempDirectory -Prefix 'JsonUtilitiesTests'
    }

    AfterAll {
        if ($script:TestTempDir -and (Test-Path $script:TestTempDir)) {
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
            Test-Path $testFile | Should -Be $true

            $result = Read-JsonFile -Path $testFile
            $result.Name | Should -Be 'Test'
            $result.Value | Should -Be 456
        }

        It 'Creates directory when EnsureDirectory is specified' {
            $testData = @{ Test = 'value' }
            $testFile = Join-Path $script:TestTempDir 'subdir' 'output.json'

            { Write-JsonFile -Path $testFile -InputObject $testData -EnsureDirectory } | Should -Not -Throw
            Test-Path $testFile | Should -Be $true
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
    }
}

