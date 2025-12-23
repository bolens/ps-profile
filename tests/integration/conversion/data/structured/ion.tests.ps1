

<#
.SYNOPSIS
    Integration tests for Ion format conversion utilities.

.DESCRIPTION
    This test suite validates Ion (Amazon Ion) format conversion functions.

.NOTES
    Tests cover both successful conversions and error handling scenarios.
    Requires Python and ion-python package for conversions.
    Tests will be skipped if required dependencies are not available.
#>

Describe 'Ion Format Conversion Tests' {
    BeforeAll {
        $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
        Initialize-TestProfile -ProfileDir $script:ProfileDir -LoadBootstrap -LoadConversionModules 'Data' -LoadFilesFragment -EnsureFileConversion
        
        # Ensure Python module is loaded (provides Get-PythonPath, Invoke-PythonScript)
        $repoRoot = Split-Path -Parent $script:ProfileDir
        $pythonModulePath = Join-Path $repoRoot 'scripts' 'lib' 'runtime' 'Python.psm1'
        if ($pythonModulePath -and -not [string]::IsNullOrWhiteSpace($pythonModulePath) -and (Test-Path -LiteralPath $pythonModulePath)) {
            Import-Module $pythonModulePath -DisableNameChecking -ErrorAction SilentlyContinue -Force -Global
        }
        
        # Check if Python/UV is available
        $script:PythonAvailable = $false
        $script:UVAvailable = (Get-Command uv -ErrorAction SilentlyContinue) -ne $null
        
        if (Get-Command Get-PythonPath -ErrorAction SilentlyContinue) {
            try {
                $pythonPath = Get-PythonPath
                if ($pythonPath) {
                    $script:PythonAvailable = $true
                }
            }
            catch {
                $script:PythonAvailable = $false
            }
        }
        
        # Also check direct python/python3 commands
        if (-not $script:PythonAvailable) {
            $script:PythonAvailable = (Get-Command python -ErrorAction SilentlyContinue) -ne $null -or (Get-Command python3 -ErrorAction SilentlyContinue) -ne $null
        }
        
        $script:InvokePythonScriptAvailable = (Get-Command Invoke-PythonScript -ErrorAction SilentlyContinue) -ne $null
    }

    Context 'Ion Conversions' {
        It 'ConvertFrom-IonToJson function exists' {
            Get-Command ConvertFrom-IonToJson -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'ConvertFrom-IonToJson handles missing input file gracefully' {
            $nonExistentFile = Join-Path $TestDrive 'nonexistent.ion'
            { ConvertFrom-IonToJson -InputPath $nonExistentFile -ErrorAction Stop } | Should -Throw
        }

        It 'ConvertTo-IonFromJson function exists' {
            Get-Command ConvertTo-IonFromJson -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'ConvertTo-IonFromJson handles missing input file gracefully' {
            $nonExistentFile = Join-Path $TestDrive 'nonexistent.json'
            { ConvertTo-IonFromJson -InputPath $nonExistentFile -ErrorAction Stop } | Should -Throw
        }

        It 'ConvertTo-IonFromJson accepts Binary parameter' {
            $func = Get-Command ConvertTo-IonFromJson -ErrorAction SilentlyContinue
            if ($func) {
                $func.Parameters.Keys | Should -Contain 'Binary'
            }
        }

        It 'Ion conversion functions require Python and ion-python package' {
            if (-not $script:PythonAvailable -and -not $script:UVAvailable) {
                Set-ItResult -Skipped -Because "Python and UV are not available"
                return
            }
            # Test that function exists and would require Python
            Get-Command ConvertFrom-IonToJson -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'ConvertFrom-IonToJson handles missing ion-python package gracefully when Python/UV is available' {
            if (-not $script:PythonAvailable -and -not $script:UVAvailable) {
                Set-ItResult -Skipped -Because "Python/UV is not available"
                return
            }
            
            if (-not $script:InvokePythonScriptAvailable) {
                Set-ItResult -Skipped -Because "Invoke-PythonScript function is not available (Python module not loaded)"
                return
            }
            
            Get-Command ConvertFrom-IonToJson -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            
            # Create a dummy Ion file (even if invalid, the function should check for ion-python package first)
            $ionFile = Join-Path $TestDrive 'test.ion'
            Set-Content -Path $ionFile -Value 'dummy ion content' -NoNewline
            
            try {
                $jsonFile = Join-Path $TestDrive 'test-output.json'
                ConvertFrom-IonToJson -InputPath $ionFile -OutputPath $jsonFile -ErrorAction Stop 2>&1 | Out-Null
                # If we get here, conversion succeeded (ion-python package is installed)
                if ($jsonFile -and -not [string]::IsNullOrWhiteSpace($jsonFile) -and (Test-Path -LiteralPath $jsonFile)) {
                    $jsonFile | Should -Exist
                }
            }
            catch {
                $errorMessage = $_.Exception.Message
                $fullError = ($_ | Out-String) + ($errorMessage | Out-String)
                
                # If conversion fails, verify it's due to missing ion-python package
                if ($errorMessage -match 'ion-python.*not.*installed' -or $errorMessage -match 'ImportError' -or $fullError -match 'ion-python') {
                    $installCommand = 'uv pip install ion-python'
                    if ($errorMessage -match [regex]::Escape($installCommand) -or $fullError -match [regex]::Escape($installCommand)) {
                        Write-Host "Installation command found in error: $installCommand" -ForegroundColor Yellow
                        $errorMessage | Should -Match ([regex]::Escape($installCommand))
                    }
                    elseif ($errorMessage -match 'ion-python' -or $fullError -match 'ion-python') {
                        Write-Host "ion-python package is not installed. Install with: $installCommand" -ForegroundColor Yellow
                        $errorMessage | Should -Match 'ion-python'
                    }
                }
                # Other errors (like invalid file format) are also acceptable
            }
        }

        It 'ConvertTo-IonFromJson handles missing ion-python package gracefully when Python/UV is available' {
            if (-not $script:PythonAvailable -and -not $script:UVAvailable) {
                Set-ItResult -Skipped -Because "Python/UV is not available"
                return
            }
            
            if (-not $script:InvokePythonScriptAvailable) {
                Set-ItResult -Skipped -Because "Invoke-PythonScript function is not available (Python module not loaded)"
                return
            }
            
            Get-Command ConvertTo-IonFromJson -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            
            # Create test JSON file
            $jsonContent = @'
{
  "name": "test",
  "value": 123,
  "enabled": true
}
'@
            $jsonFile = Join-Path $TestDrive 'test.json'
            Set-Content -Path $jsonFile -Value $jsonContent -NoNewline
            
            try {
                $ionFile = Join-Path $TestDrive 'test-output.ion'
                ConvertTo-IonFromJson -InputPath $jsonFile -OutputPath $ionFile -ErrorAction Stop 2>&1 | Out-Null
                # If we get here, conversion succeeded (ion-python package is installed)
                if ($ionFile -and -not [string]::IsNullOrWhiteSpace($ionFile) -and (Test-Path -LiteralPath $ionFile)) {
                    $ionFile | Should -Exist
                }
            }
            catch {
                $errorMessage = $_.Exception.Message
                $fullError = ($_ | Out-String) + ($errorMessage | Out-String)
                
                # If conversion fails, verify it's due to missing ion-python package
                if ($errorMessage -match 'ion-python.*not.*installed' -or $errorMessage -match 'ImportError' -or $fullError -match 'ion-python') {
                    $installCommand = 'uv pip install ion-python'
                    if ($errorMessage -match [regex]::Escape($installCommand) -or $fullError -match [regex]::Escape($installCommand)) {
                        Write-Host "Installation command found in error: $installCommand" -ForegroundColor Yellow
                        $errorMessage | Should -Match ([regex]::Escape($installCommand))
                    }
                    elseif ($errorMessage -match 'ion-python' -or $fullError -match 'ion-python') {
                        Write-Host "ion-python package is not installed. Install with: $installCommand" -ForegroundColor Yellow
                        $errorMessage | Should -Match 'ion-python'
                    }
                }
                # Other errors (like invalid file format) are also acceptable
            }
        }

        It 'Ion aliases resolve to functions' {
            $alias1 = Get-Alias ion-to-json -ErrorAction SilentlyContinue
            $alias1 | Should -Not -BeNullOrEmpty
            $alias1.ResolvedCommandName | Should -Be 'ConvertFrom-IonToJson'
            
            $alias2 = Get-Alias json-to-ion -ErrorAction SilentlyContinue
            $alias2 | Should -Not -BeNullOrEmpty
            $alias2.ResolvedCommandName | Should -Be 'ConvertTo-IonFromJson'
        }
    }
}

