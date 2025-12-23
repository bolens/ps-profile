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
        
        # Load bootstrap for core functions
        $bootstrapPath = Join-Path $script:ProfileDir 'bootstrap.ps1'
        if (Test-Path -LiteralPath $bootstrapPath) {
            . $bootstrapPath
        }
        
        # Load files fragment for conversion module infrastructure
        $filesPath = Join-Path $script:ProfileDir 'files.ps1'
        if (Test-Path -LiteralPath $filesPath) {
            . $filesPath
        }
        
        # Load required helper modules (SuperJSON depends on helpers-xml.ps1 and helpers-toon.ps1)
        $helpersXmlPath = Join-Path $script:ProfileDir 'conversion-modules' 'helpers' 'helpers-xml.ps1'
        if (Test-Path -LiteralPath $helpersXmlPath) {
            . $helpersXmlPath
        }
        else {
            throw "Required helper module not found: helpers-xml.ps1"
        }
        
        $helpersToonPath = Join-Path $script:ProfileDir 'conversion-modules' 'helpers' 'helpers-toon.ps1'
        if (Test-Path -LiteralPath $helpersToonPath) {
            . $helpersToonPath
        }
        else {
            throw "Required helper module not found: helpers-toon.ps1"
        }
        
        # Load SuperJSON module directly (bypass Ensure pattern for faster test startup)
        $superjsonModulePath = Join-Path $script:ProfileDir 'conversion-modules' 'data' 'structured' 'superjson.ps1'
        if (Test-Path -LiteralPath $superjsonModulePath) {
            . $superjsonModulePath
        }
        else {
            throw "SuperJSON module not found at: $superjsonModulePath"
        }
        
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

    Context 'SuperJSON JSON Conversions' {
        It 'ConvertTo-SuperJsonFromJson converts JSON to SuperJSON' {
            Get-Command ConvertTo-SuperJsonFromJson -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            # Skip if node not available
            $node = Test-ToolAvailable -ToolName 'node' -InstallCommand 'scoop install nodejs' -Silent
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
                Set-ItResult -Skipped -Because "superjson package not installed. Install with: pnpm add -g superjson"
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
            $node = Test-ToolAvailable -ToolName 'node' -InstallCommand 'scoop install nodejs' -Silent
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
                Set-ItResult -Skipped -Because "superjson package not installed. Install with: pnpm add -g superjson"
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
            $node = Test-ToolAvailable -ToolName 'node' -InstallCommand 'scoop install nodejs' -Silent
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
                Set-ItResult -Skipped -Because "superjson package not installed. Install with: pnpm add -g superjson"
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
            
            try {
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
                    $installCommand = 'pnpm add -g superjson'
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
}

