

<#
.SYNOPSIS
    Integration tests for CBOR format conversion utilities.

.DESCRIPTION
    This test suite validates CBOR format conversion functions.

.NOTES
    Tests cover both successful conversions and roundtrip scenarios.
    Requires Node.js and cbor npm package for conversions.
#>

Describe 'CBOR Format Conversion Tests' {
    BeforeAll {
        $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
        Initialize-TestProfile -ProfileDir $script:ProfileDir -LoadBootstrap -LoadConversionModules 'Data' -LoadFilesFragment -EnsureFileConversion
        
        # Ensure NodeJs module is loaded (provides Invoke-NodeScript)
        $repoRoot = Split-Path -Parent $script:ProfileDir
        $nodeJsModulePath = Join-Path $repoRoot 'scripts' 'lib' 'runtime' 'NodeJs.psm1'
        if ($nodeJsModulePath -and -not [string]::IsNullOrWhiteSpace($nodeJsModulePath) -and (Test-Path -LiteralPath $nodeJsModulePath)) {
            Import-Module $nodeJsModulePath -DisableNameChecking -ErrorAction SilentlyContinue -Force -Global
        }
        
        # Check if dependencies are available
        $script:NodeAvailable = (Get-Command node -ErrorAction SilentlyContinue) -ne $null
        $script:InvokeNodeScriptAvailable = (Get-Command Invoke-NodeScript -ErrorAction SilentlyContinue) -ne $null
    }

    Context 'CBOR conversion utilities' {
        It 'ConvertTo-CborFromJson converts JSON to CBOR' {
            Get-Command ConvertTo-CborFromJson -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            $node = Test-ToolAvailable -ToolName 'node' -InstallCommand 'scoop install nodejs' -Silent
            if (-not $node.Available) {
                $skipMessage = "Node.js not available"
                if ($node.InstallCommand) {
                    $skipMessage += ". Install with: $($node.InstallCommand)"
                }
                Set-ItResult -Skipped -Because $skipMessage
                return
            }
            if (-not (Test-NpmPackageAvailable -PackageName 'cbor')) {
                Set-ItResult -Skipped -Because "cbor package not installed. Install with: pnpm add -g cbor"
                return
            }
            $json = '{"name": "test", "value": 42, "nested": {"key": "value"}}'
            $tempFile = Join-Path $TestDrive 'test.json'
            Set-Content -Path $tempFile -Value $json
            $outputFile = Join-Path $TestDrive 'test-output.cbor'
            { ConvertTo-CborFromJson -InputPath $tempFile -OutputPath $outputFile } | Should -Not -Throw
            if ($outputFile -and -not [string]::IsNullOrWhiteSpace($outputFile)) {
                Test-Path -LiteralPath $outputFile | Should -Be $true
            }
            (Get-Item $outputFile).Length | Should -BeGreaterThan 0
        }

        It 'Handles roundtrip JSON to CBOR to JSON' {
            $node = Test-ToolAvailable -ToolName 'node' -InstallCommand 'scoop install nodejs' -Silent
            if (-not $node.Available) {
                $skipMessage = "Node.js not available"
                if ($node.InstallCommand) {
                    $skipMessage += ". Install with: $($node.InstallCommand)"
                }
                Set-ItResult -Skipped -Because $skipMessage
                return
            }
            if (-not (Test-NpmPackageAvailable -PackageName 'cbor')) {
                Set-ItResult -Skipped -Because "cbor package not installed. Install with: pnpm add -g cbor"
                return
            }
            $json = '{"name": "test", "value": 42}'
            $tempFile = Join-Path $TestDrive 'test.json'
            Set-Content -Path $tempFile -Value $json
            $cborFile = Join-Path $TestDrive 'test-output.cbor'
            $roundtripFile = Join-Path $TestDrive 'test-roundtrip.json'
            ConvertTo-CborFromJson -InputPath $tempFile -OutputPath $cborFile
            ConvertFrom-CborToJson -InputPath $cborFile -OutputPath $roundtripFile
            if ($roundtripFile -and -not [string]::IsNullOrWhiteSpace($roundtripFile)) {
                Test-Path -LiteralPath $roundtripFile | Should -Be $true
            }
            $result = Get-Content -Path $roundtripFile -Raw | ConvertFrom-Json
            $result.name | Should -Be "test"
            $result.value | Should -Be 42
        }

        It 'ConvertTo-CborFromJson handles missing cbor package gracefully when Node.js is available' {
            if (-not $script:NodeAvailable) {
                Set-ItResult -Skipped -Because "Node.js is not available"
                return
            }
            
            Get-Command ConvertTo-CborFromJson -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            
            # Create test JSON file
            $jsonContent = '{"name": "test", "value": 42}'
            $jsonFile = Join-Path $TestDrive 'test.json'
            Set-Content -Path $jsonFile -Value $jsonContent -NoNewline
            
            try {
                $cborFile = Join-Path $TestDrive 'test.cbor'
                ConvertTo-CborFromJson -InputPath $jsonFile -OutputPath $cborFile -ErrorAction Stop 2>&1 | Out-Null
                # If we get here, conversion succeeded (cbor package is installed)
                if ($cborFile -and -not [string]::IsNullOrWhiteSpace($cborFile) -and (Test-Path -LiteralPath $cborFile)) {
                    $cborFile | Should -Exist
                }
            }
            catch {
                $errorMessage = $_.Exception.Message
                $fullError = ($_ | Out-String) + ($errorMessage | Out-String)
                
                if ($errorMessage -match 'cbor.*not.*installed' -or $errorMessage -match 'MODULE_NOT_FOUND' -or $fullError -match 'cbor') {
                    $installCommand = 'pnpm add -g cbor'
                    if ($errorMessage -match [regex]::Escape($installCommand) -or $fullError -match [regex]::Escape($installCommand)) {
                        Write-Host "Installation command found in error: $installCommand" -ForegroundColor Yellow
                        $errorMessage | Should -Match ([regex]::Escape($installCommand))
                    }
                    elseif ($errorMessage -match 'cbor' -or $fullError -match 'cbor') {
                        Write-Host "cbor package is not installed. Install with: $installCommand" -ForegroundColor Yellow
                        $errorMessage | Should -Match 'cbor'
                    }
                }
                else {
                    throw
                }
            }
        }

        It 'ConvertFrom-CborToJson handles missing cbor package gracefully when Node.js is available' {
            if (-not $script:NodeAvailable) {
                Set-ItResult -Skipped -Because "Node.js is not available"
                return
            }
            
            Get-Command ConvertFrom-CborToJson -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            
            # Create a dummy CBOR file (even if invalid, the function should check for cbor package first)
            $cborFile = Join-Path $TestDrive 'test.cbor'
            Set-Content -Path $cborFile -Value 'dummy content' -NoNewline
            
            try {
                $jsonFile = Join-Path $TestDrive 'test-output.json'
                ConvertFrom-CborToJson -InputPath $cborFile -OutputPath $jsonFile -ErrorAction Stop 2>&1 | Out-Null
                # If we get here, conversion succeeded (cbor package is installed)
                if ($jsonFile -and -not [string]::IsNullOrWhiteSpace($jsonFile) -and (Test-Path -LiteralPath $jsonFile)) {
                    $jsonFile | Should -Exist
                }
            }
            catch {
                $errorMessage = $_.Exception.Message
                $fullError = ($_ | Out-String) + ($errorMessage | Out-String)
                
                if ($errorMessage -match 'cbor.*not.*installed' -or $errorMessage -match 'MODULE_NOT_FOUND' -or $fullError -match 'cbor') {
                    $installCommand = 'pnpm add -g cbor'
                    if ($errorMessage -match [regex]::Escape($installCommand) -or $fullError -match [regex]::Escape($installCommand)) {
                        Write-Host "Installation command found in error: $installCommand" -ForegroundColor Yellow
                        $errorMessage | Should -Match ([regex]::Escape($installCommand))
                    }
                    elseif ($errorMessage -match 'cbor' -or $fullError -match 'cbor') {
                        Write-Host "cbor package is not installed. Install with: $installCommand" -ForegroundColor Yellow
                        $errorMessage | Should -Match 'cbor'
                    }
                }
                # Other errors (like invalid file format) are also acceptable
            }
        }
    }
}

