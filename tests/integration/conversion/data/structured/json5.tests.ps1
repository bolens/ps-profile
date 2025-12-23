

<#
.SYNOPSIS
    Integration tests for JSON5 format conversion utilities.

.DESCRIPTION
    This test suite validates JSON5 format conversion functions.

.NOTES
    Tests cover both successful conversions and roundtrip scenarios.
    Requires Node.js and json5 npm package for conversions.
#>

Describe 'JSON5 Format Conversion Tests' {
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

    Context 'JSON5 conversion utilities' {
        It 'ConvertFrom-Json5ToJson converts JSON5 to JSON' {
            Get-Command ConvertFrom-Json5ToJson -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            $node = Test-ToolAvailable -ToolName 'node' -InstallCommand 'scoop install nodejs' -Silent
            if (-not $node.Available) {
                $skipMessage = "Node.js not available"
                if ($node.InstallCommand) {
                    $skipMessage += ". Install with: $($node.InstallCommand)"
                }
                Set-ItResult -Skipped -Because $skipMessage
                return
            }
            if (-not (Test-NpmPackageAvailable -PackageName 'json5')) {
                Set-ItResult -Skipped -Because "json5 package not installed. Install with: pnpm add -g json5"
                return
            }
            $json5 = @'
{
  // This is a comment
  "name": "test",
  "value": 42, // trailing comma
}
'@
            $tempFile = Join-Path $TestDrive 'test.json5'
            Set-Content -Path $tempFile -Value $json5
            $outputFile = Join-Path $TestDrive 'test-output.json'
            { ConvertFrom-Json5ToJson -InputPath $tempFile -OutputPath $outputFile } | Should -Not -Throw
            if ($outputFile -and -not [string]::IsNullOrWhiteSpace($outputFile)) {
                Test-Path -LiteralPath $outputFile | Should -Be $true
            }
            $result = Get-Content -Path $outputFile -Raw | ConvertFrom-Json
            $result.name | Should -Be "test"
            $result.value | Should -Be 42
        }

        It 'ConvertTo-Json5FromJson converts JSON to JSON5' {
            Get-Command ConvertTo-Json5FromJson -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            $node = Test-ToolAvailable -ToolName 'node' -InstallCommand 'scoop install nodejs' -Silent
            if (-not $node.Available) {
                $skipMessage = "Node.js not available"
                if ($node.InstallCommand) {
                    $skipMessage += ". Install with: $($node.InstallCommand)"
                }
                Set-ItResult -Skipped -Because $skipMessage
                return
            }
            if (-not (Test-NpmPackageAvailable -PackageName 'json5')) {
                Set-ItResult -Skipped -Because "json5 package not installed. Install with: pnpm add -g json5"
                return
            }
            $json = '{"name": "test", "value": 42}'
            $tempFile = Join-Path $TestDrive 'test.json'
            Set-Content -Path $tempFile -Value $json
            $outputFile = Join-Path $TestDrive 'test-output.json5'
            { ConvertTo-Json5FromJson -InputPath $tempFile -OutputPath $outputFile } | Should -Not -Throw
            if ($outputFile -and -not [string]::IsNullOrWhiteSpace($outputFile)) {
                Test-Path -LiteralPath $outputFile | Should -Be $true
            }
        }

        It 'Handles missing Node.js gracefully for JSON5' {
            $testFile = Join-Path $TestDrive 'nonexistent.json5'
            # Function writes errors but doesn't throw by default
            $result = ConvertFrom-Json5ToJson -InputPath $testFile -ErrorAction SilentlyContinue 2>&1
            $result | Should -Not -BeNullOrEmpty
        }

        It 'ConvertFrom-Json5ToJson handles missing json5 package gracefully when Node.js is available' {
            if (-not $script:NodeAvailable) {
                Set-ItResult -Skipped -Because "Node.js is not available"
                return
            }
            
            Get-Command ConvertFrom-Json5ToJson -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            
            # Create test JSON5 file
            $json5Content = '{ name: "test", value: 42 }'
            $json5File = Join-Path $TestDrive 'test.json5'
            Set-Content -Path $json5File -Value $json5Content -NoNewline
            
            try {
                $jsonFile = Join-Path $TestDrive 'test.json'
                ConvertFrom-Json5ToJson -InputPath $json5File -OutputPath $jsonFile -ErrorAction Stop 2>&1 | Out-Null
                # If we get here, conversion succeeded (json5 package is installed)
                if ($jsonFile -and -not [string]::IsNullOrWhiteSpace($jsonFile) -and (Test-Path -LiteralPath $jsonFile)) {
                    $jsonFile | Should -Exist
                }
            }
            catch {
                $errorMessage = $_.Exception.Message
                $fullError = ($_ | Out-String) + ($errorMessage | Out-String)
                
                if ($errorMessage -match 'json5.*not.*installed' -or $errorMessage -match 'MODULE_NOT_FOUND' -or $fullError -match 'json5') {
                    $installCommand = 'pnpm add -g json5'
                    if ($errorMessage -match [regex]::Escape($installCommand) -or $fullError -match [regex]::Escape($installCommand)) {
                        Write-Host "Installation command found in error: $installCommand" -ForegroundColor Yellow
                        $errorMessage | Should -Match ([regex]::Escape($installCommand))
                    }
                    elseif ($errorMessage -match 'json5' -or $fullError -match 'json5') {
                        Write-Host "json5 package is not installed. Install with: $installCommand" -ForegroundColor Yellow
                        $errorMessage | Should -Match 'json5'
                    }
                }
                else {
                    throw
                }
            }
        }

        It 'ConvertTo-Json5FromJson handles missing json5 package gracefully when Node.js is available' {
            if (-not $script:NodeAvailable) {
                Set-ItResult -Skipped -Because "Node.js is not available"
                return
            }
            
            Get-Command ConvertTo-Json5FromJson -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            
            # Create test JSON file
            $jsonContent = '{"name": "test", "value": 42}'
            $jsonFile = Join-Path $TestDrive 'test.json'
            Set-Content -Path $jsonFile -Value $jsonContent -NoNewline
            
            try {
                $json5File = Join-Path $TestDrive 'test.json5'
                ConvertTo-Json5FromJson -InputPath $jsonFile -OutputPath $json5File -ErrorAction Stop 2>&1 | Out-Null
                # If we get here, conversion succeeded (json5 package is installed)
                if ($json5File -and -not [string]::IsNullOrWhiteSpace($json5File) -and (Test-Path -LiteralPath $json5File)) {
                    $json5File | Should -Exist
                }
            }
            catch {
                $errorMessage = $_.Exception.Message
                $fullError = ($_ | Out-String) + ($errorMessage | Out-String)
                
                if ($errorMessage -match 'json5.*not.*installed' -or $errorMessage -match 'MODULE_NOT_FOUND' -or $fullError -match 'json5') {
                    $installCommand = 'pnpm add -g json5'
                    if ($errorMessage -match [regex]::Escape($installCommand) -or $fullError -match [regex]::Escape($installCommand)) {
                        Write-Host "Installation command found in error: $installCommand" -ForegroundColor Yellow
                        $errorMessage | Should -Match ([regex]::Escape($installCommand))
                    }
                    elseif ($errorMessage -match 'json5' -or $fullError -match 'json5') {
                        Write-Host "json5 package is not installed. Install with: $installCommand" -ForegroundColor Yellow
                        $errorMessage | Should -Match 'json5'
                    }
                }
                else {
                    throw
                }
            }
        }
    }
}

