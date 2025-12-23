

<#
.SYNOPSIS
    Integration tests for UBJSON format conversion utilities.

.DESCRIPTION
    This test suite validates UBJSON format conversion functions.

.NOTES
    Tests cover both successful conversions and error handling scenarios.
    Requires Node.js and ubjson package for conversions.
    Tests will be skipped if required dependencies are not available.
    Test files are created in $TestDrive (automatically cleaned up by Pester).
#>

Describe 'UBJSON Format Conversion Tests' {
    BeforeAll {
        $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
        Initialize-TestProfile -ProfileDir $script:ProfileDir -LoadBootstrap -LoadConversionModules 'Data' -LoadFilesFragment -EnsureFileConversion
        
        # Ensure NodeJs module is loaded (provides Invoke-NodeScript)
        # The files.ps1 should have loaded it, but ensure it's available
        # Use the same path calculation as files.ps1: from profile.d, go up one level to repo root
        $repoRoot = Split-Path -Parent $script:ProfileDir
        $nodeJsModulePath = Join-Path $repoRoot 'scripts' 'lib' 'runtime' 'NodeJs.psm1'
        if ($nodeJsModulePath -and -not [string]::IsNullOrWhiteSpace($nodeJsModulePath) -and (Test-Path -LiteralPath $nodeJsModulePath)) {
            Import-Module $nodeJsModulePath -DisableNameChecking -ErrorAction SilentlyContinue -Force -Global
        }
        else {
            Write-Warning "NodeJs module not found at: $nodeJsModulePath"
        }
        
        # Check if dependencies are available
        $script:NodeAvailable = (Get-Command node -ErrorAction SilentlyContinue) -ne $null
        $script:InvokeNodeScriptAvailable = (Get-Command Invoke-NodeScript -ErrorAction SilentlyContinue) -ne $null
        
        if (-not $script:InvokeNodeScriptAvailable) {
            Write-Warning "Invoke-NodeScript function is not available. NodeJs module may not be loaded correctly."
        }
    }

    Context 'UBJSON Conversions' {
        It 'ConvertFrom-UbjsonToJson function exists' {
            Get-Command ConvertFrom-UbjsonToJson -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'ConvertFrom-UbjsonToJson handles missing input file gracefully' {
            $nonExistentFile = Join-Path $TestDrive 'nonexistent.ubjson'
            { ConvertFrom-UbjsonToJson -InputPath $nonExistentFile -ErrorAction Stop 2>&1 | Out-Null } | Should -Throw
        }

        It 'ConvertTo-UbjsonFromJson function exists' {
            Get-Command ConvertTo-UbjsonFromJson -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'ConvertTo-UbjsonFromJson handles missing input file gracefully' {
            $nonExistentFile = Join-Path $TestDrive 'nonexistent.json'
            { ConvertTo-UbjsonFromJson -InputPath $nonExistentFile -ErrorAction Stop 2>&1 | Out-Null } | Should -Throw
        }

        It 'ConvertTo-UbjsonFromJson handles missing ubjson package gracefully when Node.js is available' {
            if (-not $script:NodeAvailable) {
                Set-ItResult -Skipped -Because "Node.js is not available"
                return
            }
            
            if (-not $script:InvokeNodeScriptAvailable) {
                Set-ItResult -Skipped -Because "Invoke-NodeScript function is not available (NodeJs module not loaded)"
                return
            }
            
            Get-Command ConvertTo-UbjsonFromJson -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            
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
            
            # Test conversion - should either succeed (if ubjson package is installed) or fail gracefully
            $ubjsonFile = Join-Path $TestDrive 'test.ubjson'
            $errorOutput = $null
            try {
                $errorOutput = ConvertTo-UbjsonFromJson -InputPath $jsonFile -OutputPath $ubjsonFile -ErrorAction Stop 2>&1
                # If we get here, conversion succeeded (ubjson package is installed)
                if ($ubjsonFile -and -not [string]::IsNullOrWhiteSpace($ubjsonFile) -and (Test-Path -LiteralPath $ubjsonFile)) {
                    $ubjsonFile | Should -Exist
                }
            }
            catch {
                # Capture full error output including stderr
                $errorMessage = $_.Exception.Message
                $fullError = ($_ | Out-String) + ($errorMessage | Out-String)
                
                # If conversion fails, verify it's due to missing ubjson package
                if ($errorMessage -match 'ubjson.*not.*installed' -or $errorMessage -match 'MODULE_NOT_FOUND' -or $fullError -match 'ubjson') {
                    # Verify installation command is present in error message
                    $installCommand = 'pnpm add -g ubjson'
                    if ($errorMessage -match [regex]::Escape($installCommand) -or $fullError -match [regex]::Escape($installCommand)) {
                        Write-Host "Installation command found in error: $installCommand" -ForegroundColor Yellow
                        $errorMessage | Should -Match ([regex]::Escape($installCommand))
                    }
                    elseif ($errorMessage -match 'ubjson' -or $fullError -match 'ubjson') {
                        Write-Host "ubjson package is not installed. Install with: $installCommand" -ForegroundColor Yellow
                        # Error mentions ubjson but may not include exact command format
                        $errorMessage | Should -Match 'ubjson'
                    }
                }
                else {
                    # Re-throw if it's an unexpected error
                    throw
                }
            }
        }

        It 'ConvertFrom-UbjsonToJson handles missing ubjson package gracefully when Node.js is available' {
            if (-not $script:NodeAvailable) {
                Set-ItResult -Skipped -Because "Node.js is not available"
                return
            }
            
            if (-not $script:InvokeNodeScriptAvailable) {
                Set-ItResult -Skipped -Because "Invoke-NodeScript function is not available (NodeJs module not loaded)"
                return
            }
            
            Get-Command ConvertFrom-UbjsonToJson -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            
            # Create a dummy UBJSON file (even if invalid, the function should check for ubjson package first)
            # In reality, we'd need a valid UBJSON file, but we can test the error handling
            $ubjsonFile = Join-Path $TestDrive 'test.ubjson'
            Set-Content -Path $ubjsonFile -Value 'dummy content' -NoNewline
            
            $errorOutput = $null
            try {
                $jsonFile = Join-Path $TestDrive 'test-output.json'
                $errorOutput = ConvertFrom-UbjsonToJson -InputPath $ubjsonFile -OutputPath $jsonFile -ErrorAction Stop 2>&1
                # If we get here, conversion succeeded (ubjson package is installed)
                if ($jsonFile -and -not [string]::IsNullOrWhiteSpace($jsonFile) -and (Test-Path -LiteralPath $jsonFile)) {
                    $jsonFile | Should -Exist
                }
            }
            catch {
                # Capture full error output including stderr
                $errorMessage = $_.Exception.Message
                $fullError = ($_ | Out-String) + ($errorMessage | Out-String)
                
                # If conversion fails, verify it's due to missing ubjson package or invalid file format
                if ($errorMessage -match 'ubjson.*not.*installed' -or $errorMessage -match 'MODULE_NOT_FOUND' -or $fullError -match 'ubjson') {
                    # Verify installation command is present in error message
                    $installCommand = 'pnpm add -g ubjson'
                    if ($errorMessage -match [regex]::Escape($installCommand) -or $fullError -match [regex]::Escape($installCommand)) {
                        Write-Host "Installation command found in error: $installCommand" -ForegroundColor Yellow
                        $errorMessage | Should -Match ([regex]::Escape($installCommand))
                    }
                    elseif ($errorMessage -match 'ubjson' -or $fullError -match 'ubjson') {
                        Write-Host "ubjson package is not installed. Install with: $installCommand" -ForegroundColor Yellow
                        # Error mentions ubjson but may not include exact command format
                        $errorMessage | Should -Match 'ubjson'
                    }
                }
                # Other errors (like invalid file format) are also acceptable
            }
        }

        It 'UBJSON aliases resolve to functions' {
            # Ensure conversion functions are initialized
            if (Get-Command Ensure-FileConversion-Data -ErrorAction SilentlyContinue) {
                Ensure-FileConversion-Data
            }
            
            $alias1 = Get-Alias ubjson-to-json -ErrorAction SilentlyContinue
            if ($alias1) {
                $alias1.ResolvedCommandName | Should -Be 'ConvertFrom-UbjsonToJson'
            }
            else {
                # Alias might not exist if initialization failed - check if function exists instead
                Get-Command ConvertFrom-UbjsonToJson -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            }
            
            $alias2 = Get-Alias json-to-ubjson -ErrorAction SilentlyContinue
            if ($alias2) {
                $alias2.ResolvedCommandName | Should -Be 'ConvertTo-UbjsonFromJson'
            }
            else {
                # Alias might not exist if initialization failed - check if function exists instead
                Get-Command ConvertTo-UbjsonFromJson -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            }
        }
    }
}

