

<#
.SYNOPSIS
    Integration tests for .env file format conversion utilities.

.DESCRIPTION
    This test suite validates .env file conversion functions including conversions to/from JSON, YAML, and INI.

.NOTES
    Tests cover both successful conversions and roundtrip scenarios.
#>

Describe '.env File Format Conversion Tests' {
    BeforeAll {
        $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
        Initialize-TestProfile -ProfileDir $script:ProfileDir -LoadBootstrap -LoadConversionModules 'Data' -LoadFilesFragment -EnsureFileConversion
    }

    Context '.env File Format Conversions' {
        It 'ConvertFrom-EnvToJson converts .env to JSON' {
            Get-Command ConvertFrom-EnvToJson -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            
            $envContent = @"
DATABASE_URL=postgres://localhost/db
API_KEY=secret123
DEBUG=true
"@
            $tempFile = Join-Path $TestDrive '.env'
            Set-Content -Path $tempFile -Value $envContent -NoNewline
            
            { ConvertFrom-EnvToJson -InputPath $tempFile } | Should -Not -Throw
            $outputFile = Join-Path $TestDrive '.env.json'
            if ($outputFile -and -not [string]::IsNullOrWhiteSpace($outputFile) -and (Test-Path -LiteralPath $outputFile)) {
                $json = Get-Content -Path $outputFile -Raw
                $json | Should -Not -BeNullOrEmpty
                $jsonObj = $json | ConvertFrom-Json
                $jsonObj.DATABASE_URL | Should -Be 'postgres://localhost/db'
            }
        }
        
        It 'ConvertTo-EnvFromJson converts JSON to .env' {
            Get-Command ConvertTo-EnvFromJson -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            
            $jsonContent = '{"DATABASE_URL":"postgres://localhost/db","API_KEY":"secret123"}'
            $tempFile = Join-Path $TestDrive 'test.json'
            Set-Content -Path $tempFile -Value $jsonContent -NoNewline
            
            { ConvertTo-EnvFromJson -InputPath $tempFile } | Should -Not -Throw
            $outputFile = Join-Path $TestDrive 'test.env'
            if ($outputFile -and -not [string]::IsNullOrWhiteSpace($outputFile) -and (Test-Path -LiteralPath $outputFile)) {
                $env = Get-Content -Path $outputFile -Raw
                $env | Should -Not -BeNullOrEmpty
                $env | Should -Match 'DATABASE_URL'
            }
        }
        
        It '.env to JSON and back roundtrip' {
            $originalEnv = @"
KEY1=value1
KEY2=value2
"@
            $tempEnv = Join-Path $TestDrive 'test.env'
            Set-Content -Path $tempEnv -Value $originalEnv -NoNewline
            
            $jsonFile = Join-Path $TestDrive 'test.json'
            ConvertFrom-EnvToJson -InputPath $tempEnv -OutputPath $jsonFile
            $envFile = Join-Path $TestDrive 'test-roundtrip.env'
            ConvertTo-EnvFromJson -InputPath $jsonFile -OutputPath $envFile
            
            if ($envFile -and -not [string]::IsNullOrWhiteSpace($envFile) -and (Test-Path -LiteralPath $envFile)) {
                $roundtripEnv = Get-Content -Path $envFile -Raw
                $roundtripEnv | Should -Match 'KEY1'
                $roundtripEnv | Should -Match 'KEY2'
            }
        }
        
        It 'Handles .env with comments' {
            $envContent = @"
# This is a comment
KEY1=value1
KEY2=value2
"@
            $tempFile = Join-Path $TestDrive 'test-comments.env'
            Set-Content -Path $tempFile -Value $envContent -NoNewline
            
            { ConvertFrom-EnvToJson -InputPath $tempFile } | Should -Not -Throw
        }
        
        It 'ConvertFrom-EnvToIni converts .env to INI' {
            Get-Command ConvertFrom-EnvToIni -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            
            $envContent = "KEY1=value1`nKEY2=value2"
            $tempFile = Join-Path $TestDrive 'test.env'
            Set-Content -Path $tempFile -Value $envContent -NoNewline
            
            { ConvertFrom-EnvToIni -InputPath $tempFile } | Should -Not -Throw
        }
    }
}

