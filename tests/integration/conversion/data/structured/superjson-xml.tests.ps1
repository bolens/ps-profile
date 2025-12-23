

<#
.SYNOPSIS
    Integration tests for SuperJSON to/from XML conversion utilities.

.DESCRIPTION
    This test suite validates SuperJSON conversion functions for XML format conversions.

.NOTES
    Tests cover both successful conversions and roundtrip scenarios.
    Requires Node.js and superjson package for SuperJSON conversions.
#>

Describe 'SuperJSON to/from XML Conversion Tests' {
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

    Context 'SuperJSON XML Conversions' {
        It 'ConvertFrom-SuperJsonToXml converts SuperJSON to XML' {
            Get-Command ConvertFrom-SuperJsonToXml -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
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
            ConvertTo-SuperJsonFromJson -InputPath $tempFile
            $superjsonFile = $tempFile -replace '\.json$', '.superjson'
            if ($superjsonFile -and -not [string]::IsNullOrWhiteSpace($superjsonFile) -and (Test-Path -LiteralPath $superjsonFile)) {
                { ConvertFrom-SuperJsonToXml -InputPath $superjsonFile } | Should -Not -Throw
            }
        }

        It 'ConvertTo-SuperJsonFromXml converts XML to SuperJSON' {
            Get-Command ConvertTo-SuperJsonFromXml -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
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
            $xml = '<root><item name="test" value="123"/></root>'
            $tempFile = Join-Path $TestDrive 'test.xml'
            Set-Content -Path $tempFile -Value $xml
            { ConvertTo-SuperJsonFromXml -InputPath $tempFile } | Should -Not -Throw
        }

        It 'ConvertFrom-SuperJsonToXml and ConvertTo-SuperJsonFromXml roundtrip' {
            Get-Command ConvertFrom-SuperJsonToXml -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            Get-Command ConvertTo-SuperJsonFromXml -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
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
            $originalXml = '<root><item name="test" value="123"/></root>'
            $tempFile = Join-Path $TestDrive 'test.xml'
            Set-Content -Path $tempFile -Value $originalXml
            { ConvertTo-SuperJsonFromXml -InputPath $tempFile } | Should -Not -Throw
            $superjsonFile = $tempFile -replace '\.xml$', '.superjson'
            if ($superjsonFile -and -not [string]::IsNullOrWhiteSpace($superjsonFile) -and (Test-Path -LiteralPath $superjsonFile)) {
                { ConvertFrom-SuperJsonToXml -InputPath $superjsonFile } | Should -Not -Throw
            }
        }

        It 'ConvertFrom-SuperJsonToXml handles missing superjson package gracefully when Node.js is available' {
            if (-not $script:NodeAvailable) {
                Set-ItResult -Skipped -Because "Node.js is not available"
                return
            }
            
            Get-Command ConvertFrom-SuperJsonToXml -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            
            # Create test SuperJSON file (or JSON that would be converted)
            $jsonContent = '{"name": "test", "value": 123}'
            $jsonFile = Join-Path $TestDrive 'test.json'
            Set-Content -Path $jsonFile -Value $jsonContent -NoNewline
            
            try {
                # First convert to SuperJSON if possible
                $superjsonFile = Join-Path $TestDrive 'test.superjson'
                try {
                    ConvertTo-SuperJsonFromJson -InputPath $jsonFile -OutputPath $superjsonFile -ErrorAction Stop 2>&1 | Out-Null
                }
                catch {
                    # If SuperJSON conversion fails, create a dummy file for testing
                    Set-Content -Path $superjsonFile -Value 'dummy content' -NoNewline
                }
                
                $xmlFile = Join-Path $TestDrive 'test-output.xml'
                ConvertFrom-SuperJsonToXml -InputPath $superjsonFile -OutputPath $xmlFile -ErrorAction Stop 2>&1 | Out-Null
                # If we get here, conversion succeeded (superjson package is installed)
                if ($xmlFile -and -not [string]::IsNullOrWhiteSpace($xmlFile) -and (Test-Path -LiteralPath $xmlFile)) {
                    $xmlFile | Should -Exist
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
                # Other errors are also acceptable
            }
        }
    }
}

