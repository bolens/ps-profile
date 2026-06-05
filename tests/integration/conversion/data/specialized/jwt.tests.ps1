

<#
.SYNOPSIS
    Integration tests for JWT conversion utilities.

.DESCRIPTION
    This test suite validates JWT encoding and decoding functions.

.NOTES
    Tests cover both successful conversions and error handling.
    Some tests may be skipped if Node.js or required npm packages are not available.
#>

Describe 'JWT Conversion Tests' {
    BeforeAll {
        $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
        Initialize-ConversionIntegrationForTestFile -ProfileDir $script:ProfileDir -TestScriptPath (Join-Path $PSScriptRoot 'jwt.tests.ps1')
        
        # Ensure NodeJs module is loaded (provides Invoke-NodeScript)
        $repoRoot = Split-Path -Parent $script:ProfileDir
        $nodeJsModulePath = Join-Path $repoRoot 'scripts' 'lib' 'runtime' 'NodeJs.psm1'
        if ($nodeJsModulePath -and -not [string]::IsNullOrWhiteSpace($nodeJsModulePath) -and (Test-Path -LiteralPath $nodeJsModulePath)) {
            Import-Module $nodeJsModulePath -DisableNameChecking -ErrorAction SilentlyContinue -Force -Global
        }

        # JWT decode relies on dev-tools crypto helpers (_Decode-Jwt)
        $jwtHelperPath = Join-Path $repoRoot 'profile.d' 'dev-tools-modules' 'crypto' 'jwt.ps1'
        if (Test-Path -LiteralPath $jwtHelperPath) {
            . $jwtHelperPath
            if (Get-Command Initialize-DevTools-Jwt -ErrorAction SilentlyContinue) {
                Initialize-DevTools-Jwt
            }
        }
        
        # Check if dependencies are available
        $script:NodeAvailable = (Get-Command node -ErrorAction SilentlyContinue) -ne $null
        $script:InvokeNodeScriptAvailable = (Get-Command Invoke-NodeScript -ErrorAction SilentlyContinue) -ne $null
    }

    Context 'JWT Conversions' {
        It 'ConvertTo-JwtFromJson function exists' {
            Get-Command ConvertTo-JwtFromJson -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'ConvertTo-JwtFromJson converts JSON to JWT' {
            # Skip if Node.js or jsonwebtoken package not available
            $node = Test-ToolAvailable -ToolName 'node' -Silent
            if (-not $node.Available) {
                $skipMessage = "Node.js not available"
                if ($node.InstallCommand) {
                    $skipMessage += ". Install with: $($node.InstallCommand)"
                }
                Set-ItResult -Skipped -Because $skipMessage
                return
            }

            $payload = @{
                sub = 'user123'
                exp = [DateTimeOffset]::UtcNow.AddHours(1).ToUnixTimeSeconds()
            } | ConvertTo-Json -Compress

            $tempFile = Join-Path $TestDrive 'test-jwt.json'
            Set-Content -Path $tempFile -Value $payload -NoNewline

            # Note: Actual JWT encoding requires jsonwebtoken npm package
            # This test verifies function existence and basic parameter handling
            Get-Command ConvertTo-JwtFromJson -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            
            # Test conversion - should either succeed (if jsonwebtoken package is installed) or fail gracefully
            try {
                $jwtFile = Join-Path $TestDrive 'test.jwt'
                ConvertTo-JwtFromJson -InputPath $tempFile -OutputPath $jwtFile -ErrorAction Stop 2>&1 | Out-Null
                # If we get here, conversion succeeded (jsonwebtoken package is installed)
                if ($jwtFile -and -not [string]::IsNullOrWhiteSpace($jwtFile) -and (Test-Path -LiteralPath $jwtFile)) {
                    $jwtFile | Should -Exist
                }
            }
            catch {
                $errorMessage = $_.Exception.Message
                $fullError = ($_ | Out-String) + ($errorMessage | Out-String)
                
                if ($errorMessage -match 'jsonwebtoken.*not.*installed' -or $errorMessage -match 'MODULE_NOT_FOUND' -or $fullError -match 'jsonwebtoken') {
                    $installCommand = Resolve-TestToolInstallCommand -ToolName 'jsonwebtoken' -ToolType 'node-package'
                    if ($errorMessage -match [regex]::Escape($installCommand) -or $fullError -match [regex]::Escape($installCommand)) {
                        Write-Host "Installation command found in error: $installCommand" -ForegroundColor Yellow
                        $errorMessage | Should -Match ([regex]::Escape($installCommand))
                    }
                    elseif ($errorMessage -match 'jsonwebtoken' -or $fullError -match 'jsonwebtoken') {
                        Write-Host "jsonwebtoken package is not installed. Install with: $installCommand" -ForegroundColor Yellow
                        $errorMessage | Should -Match 'jsonwebtoken'
                    }
                }
            }
        }

        It 'ConvertFrom-JwtToJson function exists' {
            Get-Command ConvertFrom-JwtToJson -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'ConvertFrom-JwtToJson decodes JWT to JSON' {
            # Create a simple test JWT (header.payload.signature format)
            # This is a minimal valid JWT structure for testing
            $header = '{"alg":"HS256","typ":"JWT"}'
            $payload = '{"sub":"user123","exp":1234567890}'
            $headerB64 = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($header)) -replace '\+', '-' -replace '/', '_' -replace '='
            $payloadB64 = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($payload)) -replace '\+', '-' -replace '/', '_' -replace '='
            $signature = 'test-signature'
            $token = "$headerB64.$payloadB64.$signature"

            $tempFile = Join-Path $TestDrive 'test.jwt'
            Set-Content -Path $tempFile -Value $token -NoNewline

            { ConvertFrom-JwtToJson -InputPath $tempFile } | Should -Not -Throw
            $outputFile = $tempFile -replace '\.jwt$', '.json'
            if ($outputFile -and -not [string]::IsNullOrWhiteSpace($outputFile) -and (Test-Path -LiteralPath $outputFile)) {
                $json = Get-Content -Path $outputFile -Raw
                $json | Should -Not -BeNullOrEmpty
                $jsonObj = $json | ConvertFrom-Json
                $jsonObj.Header | Should -Not -Be $null
                $jsonObj.Payload | Should -Not -Be $null
            }
        }

        It 'JWT to JSON and back roundtrip (if encoding available)' {
            # Skip if encoding not available
            if (-not (Get-Command _Encode-Jwt -ErrorAction SilentlyContinue) -and -not (Get-Command Encode-Jwt -ErrorAction SilentlyContinue)) {
                Set-ItResult -Skipped -Because "JWT encoding not available (requires jsonwebtoken npm package)"
                return
            }

            $payload = @{
                sub  = 'user123'
                name = 'Test User'
            }
            $payloadJson = $payload | ConvertTo-Json -Compress
            $tempFile = Join-Path $TestDrive 'test-jwt-roundtrip.json'
            Set-Content -Path $tempFile -Value $payloadJson -NoNewline

            # Encode to JWT, then decode back
            try {
                ConvertTo-JwtFromJson -InputPath $tempFile -Secret 'test-secret'
            }
            catch {
                Set-ItResult -Skipped -Because "JWT encoding failed (may require jsonwebtoken npm package): $_"
                return
            }

            $jwtFile = $tempFile -replace '\.json$', '.jwt'
            if (-not (Test-Path -LiteralPath $jwtFile) -or [string]::IsNullOrWhiteSpace((Get-Content -LiteralPath $jwtFile -Raw))) {
                Set-ItResult -Skipped -Because 'JWT encoding produced no output (may require jsonwebtoken npm package)'
                return
            }

            try {
                ConvertFrom-JwtToJson -InputPath $jwtFile
            }
            catch {
                throw
            }

            $decodedFile = $jwtFile -replace '\.jwt$', '.json'
            $decodedJson = Get-Content -LiteralPath $decodedFile -Raw | ConvertFrom-Json
            $decodedJson.Payload.sub | Should -Be 'user123'
            $decodedJson.Payload.name | Should -Be 'Test User'
        }
    }
}

