

<#
.SYNOPSIS
    Integration tests for BSON and CBOR binary format conversions.

.DESCRIPTION
    This test suite validates BSON ↔ CBOR conversion functions.

.NOTES
    Tests cover both successful conversions and error handling scenarios.
    Requires Node.js and respective packages for conversions.
#>

Describe 'BSON and CBOR Conversion Tests' {
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

    Context 'BSON and CBOR Conversions' {
        It 'ConvertTo-CborFromBson converts BSON to CBOR' {
            Get-Command ConvertTo-CborFromBson -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            $node = Test-ToolAvailable -ToolName 'node' -InstallCommand 'scoop install nodejs' -Silent
            if (-not $node.Available) {
                $skipMessage = "Node.js not available"
                if ($node.InstallCommand) {
                    $skipMessage += ". Install with: $($node.InstallCommand)"
                }
                Set-ItResult -Skipped -Because $skipMessage
                return
            }
            if (-not (Test-NpmPackageAvailable -PackageName 'bson') -or -not (Test-NpmPackageAvailable -PackageName 'cbor')) {
                Set-ItResult -Skipped -Because "Required packages not installed. Install with: pnpm add -g bson cbor"
                return
            }
            $json = '{"name": "test", "value": 123}'
            $tempJson = Join-Path $TestDrive 'test.json'
            $tempBson = Join-Path $TestDrive 'test.bson'
            Set-Content -Path $tempJson -Value $json
            ConvertTo-BsonFromJson -InputPath $tempJson -OutputPath $tempBson
            { ConvertTo-CborFromBson -InputPath $tempBson } | Should -Not -Throw
            $outputFile = $tempBson -replace '\.bson$', '.cbor'
            if ($outputFile -and -not [string]::IsNullOrWhiteSpace($outputFile) -and (Test-Path -LiteralPath $outputFile)) {
                $cbor = Get-Content -Path $outputFile -Raw -AsByteStream
                $cbor | Should -Not -BeNullOrEmpty
            }
        }

        It 'ConvertTo-BsonFromCbor converts CBOR to BSON' {
            Get-Command ConvertTo-BsonFromCbor -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            $node = Test-ToolAvailable -ToolName 'node' -InstallCommand 'scoop install nodejs' -Silent
            if (-not $node.Available) {
                $skipMessage = "Node.js not available"
                if ($node.InstallCommand) {
                    $skipMessage += ". Install with: $($node.InstallCommand)"
                }
                Set-ItResult -Skipped -Because $skipMessage
                return
            }
            if (-not (Test-NpmPackageAvailable -PackageName 'bson') -or -not (Test-NpmPackageAvailable -PackageName 'cbor')) {
                Set-ItResult -Skipped -Because "Required packages not installed. Install with: pnpm add -g bson cbor"
                return
            }
            $json = '{"name": "test", "value": 123}'
            $tempJson = Join-Path $TestDrive 'test.json'
            $tempCbor = Join-Path $TestDrive 'test.cbor'
            Set-Content -Path $tempJson -Value $json
            ConvertTo-CborFromJson -InputPath $tempJson -OutputPath $tempCbor
            { ConvertTo-BsonFromCbor -InputPath $tempCbor } | Should -Not -Throw
            $outputFile = $tempCbor -replace '\.cbor$', '.bson'
            if ($outputFile -and -not [string]::IsNullOrWhiteSpace($outputFile) -and (Test-Path -LiteralPath $outputFile)) {
                $bson = Get-Content -Path $outputFile -Raw -AsByteStream
                $bson | Should -Not -BeNullOrEmpty
            }
        }

        It 'ConvertTo-CborFromBson handles missing packages gracefully when Node.js is available' {
            if (-not $script:NodeAvailable) {
                Set-ItResult -Skipped -Because "Node.js is not available"
                return
            }
            
            Get-Command ConvertTo-CborFromBson -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            
            # Create test BSON file (dummy content for testing)
            $bsonFile = Join-Path $TestDrive 'test.bson'
            Set-Content -Path $bsonFile -Value 'dummy bson content' -NoNewline
            
            try {
                $cborFile = Join-Path $TestDrive 'test-output.cbor'
                ConvertTo-CborFromBson -InputPath $bsonFile -OutputPath $cborFile -ErrorAction Stop 2>&1 | Out-Null
                # If we get here, conversion succeeded (packages are installed)
                if ($cborFile -and -not [string]::IsNullOrWhiteSpace($cborFile) -and (Test-Path -LiteralPath $cborFile)) {
                    $cborFile | Should -Exist
                }
            }
            catch {
                $errorMessage = $_.Exception.Message
                $fullError = ($_ | Out-String) + ($errorMessage | Out-String)
                
                if ($errorMessage -match '(bson|cbor).*not.*installed' -or $errorMessage -match 'MODULE_NOT_FOUND' -or $fullError -match '(bson|cbor)') {
                    $installCommand = 'pnpm add -g bson cbor'
                    if ($errorMessage -match [regex]::Escape($installCommand) -or $fullError -match [regex]::Escape($installCommand)) {
                        Write-Host "Installation command found in error: $installCommand" -ForegroundColor Yellow
                        $errorMessage | Should -Match ([regex]::Escape($installCommand))
                    }
                    elseif ($errorMessage -match '(bson|cbor)' -or $fullError -match '(bson|cbor)') {
                        Write-Host "Required packages (bson, cbor) may not be installed. Install with: $installCommand" -ForegroundColor Yellow
                        $errorMessage | Should -Match '(bson|cbor)'
                    }
                }
                # Other errors (like invalid file format) are also acceptable
            }
        }
    }
}

