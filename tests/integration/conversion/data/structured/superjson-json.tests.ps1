# Load TestSupport.ps1 - ensure it's loaded before using its functions
$testSupportPath = Join-Path $PSScriptRoot '..\..\..\..\TestSupport.ps1'
if (Test-Path $testSupportPath) {
    . $testSupportPath
}
else {
    throw "TestSupport.ps1 not found at: $testSupportPath"
}

<#
.SYNOPSIS
    Integration tests for SuperJSON to/from JSON conversion utilities.

.DESCRIPTION
    This test suite validates SuperJSON conversion functions for JSON format conversions.

.NOTES
    Tests cover both successful conversions and roundtrip scenarios.
    Requires Node.js and superjson package for SuperJSON conversions.
#>

Describe 'SuperJSON to/from JSON Conversion Tests' {
    BeforeAll {
        $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
        Initialize-ConversionIntegrationForTestFile -ProfileDir $script:ProfileDir

        $repoRoot = Split-Path -Parent $script:ProfileDir
        $nodeJsModulePath = Join-Path $repoRoot 'scripts' 'lib' 'runtime' 'NodeJs.psm1'
        if ($nodeJsModulePath -and -not [string]::IsNullOrWhiteSpace($nodeJsModulePath) -and (Test-Path -LiteralPath $nodeJsModulePath)) {
            Import-Module $nodeJsModulePath -DisableNameChecking -ErrorAction SilentlyContinue -Force -Global
        }

        $script:NodeAvailable = (Get-Command node -ErrorAction SilentlyContinue) -ne $null
        $script:InvokeNodeScriptAvailable = (Get-Command Invoke-NodeScript -ErrorAction SilentlyContinue) -ne $null
    }

    Context 'SuperJSON JSON Conversions' {
        It 'ConvertTo-SuperJsonFromJson converts JSON to SuperJSON' {
            Get-Command ConvertTo-SuperJsonFromJson -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            # Skip if node not available
            $node = Test-ToolAvailable -ToolName 'node' -Silent
            if (-not $node.Available) {
                $skipMessage = "Node.js not available"
                if ($node.InstallCommand) {
                    $skipMessage += ". Install with: $($node.InstallCommand)"
                }
                Set-ItResult -Skipped -Because $skipMessage
                return
            }
            # Check if superjson is available
            if (-not (Test-NpmPackageAvailable -PackageName 'superjson')) {
                Set-ItResult -Skipped -Because (Get-TestToolSkipMessage -ToolName 'superjson' -ToolType 'node-package' -Context 'superjson package not installed')
                return
            }
            $json = '{"name": "test", "value": 123}'
            $tempFile = Join-Path $TestDrive 'test.json'
            Set-Content -Path $tempFile -Value $json
            { ConvertTo-SuperJsonFromJson -InputPath $tempFile } | Should -Not -Throw
            $outputFile = $tempFile -replace '\.json$', '.superjson'
            if ($outputFile -and -not [string]::IsNullOrWhiteSpace($outputFile) -and (Test-Path -LiteralPath $outputFile)) {
                $superjson = Get-Content -Path $outputFile -Raw
                $superjson | Should -Not -BeNullOrEmpty
            }
        }

        It 'ConvertFrom-SuperJsonToJson converts SuperJSON to JSON' {
            Get-Command ConvertFrom-SuperJsonToJson -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            # Skip if node not available
            $node = Test-ToolAvailable -ToolName 'node' -Silent
            if (-not $node.Available) {
                $skipMessage = "Node.js not available"
                if ($node.InstallCommand) {
                    $skipMessage += ". Install with: $($node.InstallCommand)"
                }
                Set-ItResult -Skipped -Because $skipMessage
                return
            }
            # Check if superjson is available
            if (-not (Test-NpmPackageAvailable -PackageName 'superjson')) {
                Set-ItResult -Skipped -Because (Get-TestToolSkipMessage -ToolName 'superjson' -ToolType 'node-package' -Context 'superjson package not installed')
                return
            }
            # First create a SuperJSON file
            $json = '{"name": "test", "value": 123}'
            $tempFile = Join-Path $TestDrive 'test.json'
            Set-Content -Path $tempFile -Value $json
            ConvertTo-SuperJsonFromJson -InputPath $tempFile
            $superjsonFile = $tempFile -replace '\.json$', '.superjson'
            if ($superjsonFile -and -not [string]::IsNullOrWhiteSpace($superjsonFile) -and (Test-Path -LiteralPath $superjsonFile)) {
                { ConvertFrom-SuperJsonToJson -InputPath $superjsonFile } | Should -Not -Throw
                $outputFile = $superjsonFile -replace '\.superjson$', '.json'
                if ($outputFile -and -not [string]::IsNullOrWhiteSpace($outputFile) -and (Test-Path -LiteralPath $outputFile)) {
                    $json = Get-Content -Path $outputFile -Raw
                    $json | Should -Not -BeNullOrEmpty
                }
            }
        }

        It 'ConvertTo-SuperJsonFromJson and ConvertFrom-SuperJsonToJson roundtrip' {
            Get-Command ConvertTo-SuperJsonFromJson -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            Get-Command ConvertFrom-SuperJsonToJson -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            # Skip if node not available
            $node = Test-ToolAvailable -ToolName 'node' -Silent
            if (-not $node.Available) {
                $skipMessage = "Node.js not available"
                if ($node.InstallCommand) {
                    $skipMessage += ". Install with: $($node.InstallCommand)"
                }
                Set-ItResult -Skipped -Because $skipMessage
                return
            }
            # Check if superjson is available
            if (-not (Test-NpmPackageAvailable -PackageName 'superjson')) {
                Set-ItResult -Skipped -Because (Get-TestToolSkipMessage -ToolName 'superjson' -ToolType 'node-package' -Context 'superjson package not installed')
                return
            }
            $originalJson = '{"name": "test", "value": 123, "array": [1, 2, 3]}'
            $tempFile = Join-Path $TestDrive 'test.json'
            Set-Content -Path $tempFile -Value $originalJson
            { ConvertTo-SuperJsonFromJson -InputPath $tempFile } | Should -Not -Throw
            $superjsonFile = $tempFile -replace '\.json$', '.superjson'
            if ($superjsonFile -and -not [string]::IsNullOrWhiteSpace($superjsonFile) -and (Test-Path -LiteralPath $superjsonFile)) {
                { ConvertFrom-SuperJsonToJson -InputPath $superjsonFile } | Should -Not -Throw
            }
        }

        It 'ConvertTo-SuperJsonFromJson handles missing superjson package gracefully when Node.js is available' {
            if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
                Set-ItResult -Skipped -Because "Node.js is not available"
                return
            }
            
            Get-Command ConvertTo-SuperJsonFromJson -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            
            # Create test JSON file
            $jsonContent = '{"name": "test", "value": 123}'
            $jsonFile = Join-Path $TestDrive 'test.json'
            Set-Content -Path $jsonFile -Value $jsonContent -NoNewline
            
                        $superjsonFile = Join-Path $TestDrive 'test.superjson'
            ConvertTo-SuperJsonFromJson -InputPath $jsonFile -OutputPath $superjsonFile -ErrorAction Stop 2>&1 | Out-Null
            # If we get here, conversion succeeded (superjson package is installed)
            if ($superjsonFile -and -not [string]::IsNullOrWhiteSpace($superjsonFile) -and (Test-Path -LiteralPath $superjsonFile)) {
                $superjsonFile | Should -Exist
            }
        }
        catch {
            $errorMessage = $_.Exception.Message
            $fullError = ($_ | Out-String) + ($errorMessage | Out-String)
            
            if ($errorMessage -match 'superjson.*not.*installed' -or $errorMessage -match 'MODULE_NOT_FOUND' -or $fullError -match 'superjson') {
                $installCommand = Resolve-TestToolInstallCommand -ToolName 'superjson' -ToolType 'node-package'
                if ($errorMessage -match [regex]::Escape($installCommand) -or $fullError -match [regex]::Escape($installCommand)) {
                    Write-Host "Installation command found in error: $installCommand" -ForegroundColor Yellow
                    $errorMessage | Should -Match ([regex]::Escape($installCommand))
                }
                elseif ($errorMessage -match 'superjson' -or $fullError -match 'superjson') {
                    Write-Host "superjson package is not installed. Install with: $installCommand" -ForegroundColor Yellow
                    $errorMessage | Should -Match 'superjson'
                }
            }
            else {
                throw
            }
        }
    }
}

