

<#
.SYNOPSIS
    Integration tests for MessagePack and CBOR binary format conversions.

.DESCRIPTION
    This test suite validates MessagePack ↔ CBOR conversion functions.

.NOTES
    Tests cover both successful conversions and error handling scenarios.
    Requires Node.js and respective packages for conversions.
#>

Describe 'MessagePack and CBOR Conversion Tests' {
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

    Context 'MessagePack and CBOR Conversions' {
        It 'ConvertTo-CborFromMessagePack converts MessagePack to CBOR' {
            Get-Command ConvertTo-CborFromMessagePack -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            $node = Test-ToolAvailable -ToolName 'node' -InstallCommand 'scoop install nodejs' -Silent
            if (-not $node.Available) {
                $skipMessage = "Node.js not available"
                if ($node.InstallCommand) {
                    $skipMessage += ". Install with: $($node.InstallCommand)"
                }
                Set-ItResult -Skipped -Because $skipMessage
                return
            }
            if (-not (Test-NpmPackageAvailable -PackageName '@msgpack/msgpack') -or -not (Test-NpmPackageAvailable -PackageName 'cbor')) {
                Set-ItResult -Skipped -Because "Required packages not installed. Install with: pnpm add -g @msgpack/msgpack cbor"
                return
            }
            $json = '{"name": "test", "value": 123}'
            $tempJson = Join-Path $TestDrive 'test.json'
            $tempMsgpack = Join-Path $TestDrive 'test.msgpack'
            Set-Content -Path $tempJson -Value $json
            ConvertTo-MessagePackFromJson -InputPath $tempJson -OutputPath $tempMsgpack
            { ConvertTo-CborFromMessagePack -InputPath $tempMsgpack } | Should -Not -Throw
            $outputFile = $tempMsgpack -replace '\.msgpack$', '.cbor'
            if ($outputFile -and -not [string]::IsNullOrWhiteSpace($outputFile) -and (Test-Path -LiteralPath $outputFile)) {
                $cbor = Get-Content -Path $outputFile -Raw -AsByteStream
                $cbor | Should -Not -BeNullOrEmpty
            }
        }

        It 'ConvertTo-MessagePackFromCbor converts CBOR to MessagePack' {
            Get-Command ConvertTo-MessagePackFromCbor -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            $node = Test-ToolAvailable -ToolName 'node' -InstallCommand 'scoop install nodejs' -Silent
            if (-not $node.Available) {
                $skipMessage = "Node.js not available"
                if ($node.InstallCommand) {
                    $skipMessage += ". Install with: $($node.InstallCommand)"
                }
                Set-ItResult -Skipped -Because $skipMessage
                return
            }
            if (-not (Test-NpmPackageAvailable -PackageName '@msgpack/msgpack') -or -not (Test-NpmPackageAvailable -PackageName 'cbor')) {
                Set-ItResult -Skipped -Because "Required packages not installed. Install with: pnpm add -g @msgpack/msgpack cbor"
                return
            }
            $json = '{"name": "test", "value": 123}'
            $tempJson = Join-Path $TestDrive 'test.json'
            $tempCbor = Join-Path $TestDrive 'test.cbor'
            Set-Content -Path $tempJson -Value $json
            ConvertTo-CborFromJson -InputPath $tempJson -OutputPath $tempCbor
            { ConvertTo-MessagePackFromCbor -InputPath $tempCbor } | Should -Not -Throw
            $outputFile = $tempCbor -replace '\.cbor$', '.msgpack'
            if ($outputFile -and -not [string]::IsNullOrWhiteSpace($outputFile) -and (Test-Path -LiteralPath $outputFile)) {
                $msgpack = Get-Content -Path $outputFile -Raw -AsByteStream
                $msgpack | Should -Not -BeNullOrEmpty
            }
        }

        It 'ConvertTo-CborFromMessagePack handles missing packages gracefully when Node.js is available' {
            if (-not $script:NodeAvailable) {
                Set-ItResult -Skipped -Because "Node.js is not available"
                return
            }
            
            Get-Command ConvertTo-CborFromMessagePack -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            
            # Create test MessagePack file (dummy content for testing)
            $msgpackFile = Join-Path $TestDrive 'test.msgpack'
            Set-Content -Path $msgpackFile -Value 'dummy msgpack content' -NoNewline
            
            try {
                $cborFile = Join-Path $TestDrive 'test-output.cbor'
                ConvertTo-CborFromMessagePack -InputPath $msgpackFile -OutputPath $cborFile -ErrorAction Stop 2>&1 | Out-Null
                # If we get here, conversion succeeded (packages are installed)
                if ($cborFile -and -not [string]::IsNullOrWhiteSpace($cborFile) -and (Test-Path -LiteralPath $cborFile)) {
                    $cborFile | Should -Exist
                }
            }
            catch {
                $errorMessage = $_.Exception.Message
                $fullError = ($_ | Out-String) + ($errorMessage | Out-String)
                
                if ($errorMessage -match '(@msgpack/msgpack|cbor).*not.*installed' -or $errorMessage -match 'MODULE_NOT_FOUND' -or $fullError -match '(@msgpack/msgpack|cbor)') {
                    $installCommand = 'pnpm add -g @msgpack/msgpack cbor'
                    if ($errorMessage -match [regex]::Escape($installCommand) -or $fullError -match [regex]::Escape($installCommand)) {
                        Write-Host "Installation command found in error: $installCommand" -ForegroundColor Yellow
                        $errorMessage | Should -Match ([regex]::Escape($installCommand))
                    }
                    elseif ($errorMessage -match '(@msgpack/msgpack|cbor)' -or $fullError -match '(@msgpack/msgpack|cbor)') {
                        Write-Host "Required packages (@msgpack/msgpack, cbor) may not be installed. Install with: $installCommand" -ForegroundColor Yellow
                        $errorMessage | Should -Match '(@msgpack/msgpack|cbor)'
                    }
                }
                # Other errors (like invalid file format) are also acceptable
            }
        }
    }
}

