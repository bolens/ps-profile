. (Join-Path $PSScriptRoot '..\TestSupport.ps1')

<#
.SYNOPSIS
    Integration tests for SuperJSON conversion utilities.

.DESCRIPTION
    This test suite validates SuperJSON conversion functions including conversions
    to/from JSON, YAML, TOON, TOML, XML, and CSV formats.

.NOTES
    Tests cover both successful conversions and roundtrip scenarios.
    Requires Node.js and superjson package for SuperJSON conversions.
#>

Describe 'SuperJSON Conversion Integration Tests' {
    BeforeAll {
        $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
        . (Join-Path $script:ProfileDir '00-bootstrap.ps1')
        . (Join-Path $script:ProfileDir '02-files.ps1')
        Ensure-FileConversion-Data
    }

    Context 'SuperJSON conversion utilities' {
        It 'ConvertTo-SuperJsonFromJson converts JSON to SuperJSON' {
            Get-Command ConvertTo-SuperJsonFromJson -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            # Skip if node not available
            if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
                Set-ItResult -Skipped -Because "Node.js not available"
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
            if (Test-Path $outputFile) {
                $superjson = Get-Content -Path $outputFile -Raw
                $superjson | Should -Not -BeNullOrEmpty
            }
        }

        It 'ConvertFrom-SuperJsonToJson converts SuperJSON to JSON' {
            Get-Command ConvertFrom-SuperJsonToJson -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            # Skip if node not available
            if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
                Set-ItResult -Skipped -Because "Node.js not available"
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
            if (Test-Path $superjsonFile) {
                { ConvertFrom-SuperJsonToJson -InputPath $superjsonFile } | Should -Not -Throw
                $outputFile = $superjsonFile -replace '\.superjson$', '.json'
                if (Test-Path $outputFile) {
                    $json = Get-Content -Path $outputFile -Raw
                    $json | Should -Not -BeNullOrEmpty
                }
            }
        }

        It 'ConvertTo-SuperJsonFromJson and ConvertFrom-SuperJsonToJson roundtrip' {
            Get-Command ConvertTo-SuperJsonFromJson -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            Get-Command ConvertFrom-SuperJsonToJson -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            # Skip if node not available
            if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
                Set-ItResult -Skipped -Because "Node.js not available"
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
            if (Test-Path $superjsonFile) {
                { ConvertFrom-SuperJsonToJson -InputPath $superjsonFile } | Should -Not -Throw
            }
        }

        It 'ConvertFrom-SuperJsonToYaml converts SuperJSON to YAML' {
            Get-Command ConvertFrom-SuperJsonToYaml -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            # Skip if node not available
            if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
                Set-ItResult -Skipped -Because "Node.js not available"
                return
            }
            # Skip if yq not available
            if (-not (Get-Command yq -ErrorAction SilentlyContinue)) {
                Set-ItResult -Skipped -Because "yq command not available"
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
            if (Test-Path $superjsonFile) {
                { ConvertFrom-SuperJsonToYaml -InputPath $superjsonFile } | Should -Not -Throw
            }
        }

        It 'ConvertTo-SuperJsonFromYaml converts YAML to SuperJSON' {
            Get-Command ConvertTo-SuperJsonFromYaml -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            # Skip if node not available
            if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
                Set-ItResult -Skipped -Because "Node.js not available"
                return
            }
            # Skip if yq not available
            if (-not (Get-Command yq -ErrorAction SilentlyContinue)) {
                Set-ItResult -Skipped -Because "yq command not available"
                return
            }
            # Check if superjson is available
            if (-not (Test-NpmPackageAvailable -PackageName 'superjson')) {
                Set-ItResult -Skipped -Because "superjson package not installed. Install with: pnpm add -g superjson"
                return
            }
            $yaml = "name: test`nvalue: 123"
            $tempFile = Join-Path $TestDrive 'test.yaml'
            Set-Content -Path $tempFile -Value $yaml
            { ConvertTo-SuperJsonFromYaml -InputPath $tempFile } | Should -Not -Throw
        }

        It 'ConvertFrom-SuperJsonToToon converts SuperJSON to TOON' {
            Get-Command ConvertFrom-SuperJsonToToon -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            # Skip if node not available
            if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
                Set-ItResult -Skipped -Because "Node.js not available"
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
            if (Test-Path $superjsonFile) {
                { ConvertFrom-SuperJsonToToon -InputPath $superjsonFile } | Should -Not -Throw
            }
        }

        It 'ConvertTo-SuperJsonFromToon converts TOON to SuperJSON' {
            Get-Command ConvertTo-SuperJsonFromToon -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            # Skip if node not available
            if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
                Set-ItResult -Skipped -Because "Node.js not available"
                return
            }
            # Check if superjson is available
            if (-not (Test-NpmPackageAvailable -PackageName 'superjson')) {
                Set-ItResult -Skipped -Because "superjson package not installed. Install with: pnpm add -g superjson"
                return
            }
            $toon = "name `"test`"`nvalue 123"
            $tempFile = Join-Path $TestDrive 'test.toon'
            Set-Content -Path $tempFile -Value $toon
            { ConvertTo-SuperJsonFromToon -InputPath $tempFile } | Should -Not -Throw
        }

        It 'ConvertFrom-SuperJsonToToml converts SuperJSON to TOML' {
            Get-Command ConvertFrom-SuperJsonToToml -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            # Skip if node not available
            if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
                Set-ItResult -Skipped -Because "Node.js not available"
                return
            }
            # Skip if yq not available
            if (-not (Get-Command yq -ErrorAction SilentlyContinue)) {
                Set-ItResult -Skipped -Because "yq command not available"
                return
            }
            # Skip if PSToml not available
            if (-not (Get-Module -ListAvailable -Name PSToml -ErrorAction SilentlyContinue)) {
                Set-ItResult -Skipped -Because "PSToml module not available"
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
            if (Test-Path $superjsonFile) {
                { ConvertFrom-SuperJsonToToml -InputPath $superjsonFile } | Should -Not -Throw
            }
        }

        It 'ConvertTo-SuperJsonFromToml converts TOML to SuperJSON' {
            Get-Command ConvertTo-SuperJsonFromToml -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            # Skip if node not available
            if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
                Set-ItResult -Skipped -Because "Node.js not available"
                return
            }
            # Skip if yq not available
            if (-not (Get-Command yq -ErrorAction SilentlyContinue)) {
                Set-ItResult -Skipped -Because "yq command not available"
                return
            }
            # Check if superjson is available
            if (-not (Test-NpmPackageAvailable -PackageName 'superjson')) {
                Set-ItResult -Skipped -Because "superjson package not installed. Install with: pnpm add -g superjson"
                return
            }
            $toml = "name = `"test`"`nvalue = 123"
            $tempFile = Join-Path $TestDrive 'test.toml'
            Set-Content -Path $tempFile -Value $toml
            { ConvertTo-SuperJsonFromToml -InputPath $tempFile } | Should -Not -Throw
        }

        It 'ConvertFrom-SuperJsonToXml converts SuperJSON to XML' {
            Get-Command ConvertFrom-SuperJsonToXml -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            # Skip if node not available
            if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
                Set-ItResult -Skipped -Because "Node.js not available"
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
            if (Test-Path $superjsonFile) {
                { ConvertFrom-SuperJsonToXml -InputPath $superjsonFile } | Should -Not -Throw
            }
        }

        It 'ConvertTo-SuperJsonFromXml converts XML to SuperJSON' {
            Get-Command ConvertTo-SuperJsonFromXml -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            # Skip if node not available
            if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
                Set-ItResult -Skipped -Because "Node.js not available"
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

        It 'ConvertFrom-SuperJsonToCsv converts SuperJSON to CSV' {
            Get-Command ConvertFrom-SuperJsonToCsv -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            # Skip if node not available
            if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
                Set-ItResult -Skipped -Because "Node.js not available"
                return
            }
            # Check if superjson is available
            if (-not (Test-NpmPackageAvailable -PackageName 'superjson')) {
                Set-ItResult -Skipped -Because "superjson package not installed. Install with: pnpm add -g superjson"
                return
            }
            $json = '[{"name": "test", "value": 123}]'
            $tempFile = Join-Path $TestDrive 'test.json'
            Set-Content -Path $tempFile -Value $json
            ConvertTo-SuperJsonFromJson -InputPath $tempFile
            $superjsonFile = $tempFile -replace '\.json$', '.superjson'
            if (Test-Path $superjsonFile) {
                { ConvertFrom-SuperJsonToCsv -InputPath $superjsonFile } | Should -Not -Throw
            }
        }

        It 'ConvertTo-SuperJsonFromCsv converts CSV to SuperJSON' {
            Get-Command ConvertTo-SuperJsonFromCsv -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            # Skip if node not available
            if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
                Set-ItResult -Skipped -Because "Node.js not available"
                return
            }
            # Check if superjson is available
            if (-not (Test-NpmPackageAvailable -PackageName 'superjson')) {
                Set-ItResult -Skipped -Because "superjson package not installed. Install with: pnpm add -g superjson"
                return
            }
            $csv = "name,value`ntest,123"
            $tempFile = Join-Path $TestDrive 'test.csv'
            Set-Content -Path $tempFile -Value $csv
            { ConvertTo-SuperJsonFromCsv -InputPath $tempFile } | Should -Not -Throw
        }

        It 'ConvertFrom-SuperJsonToYaml and ConvertTo-SuperJsonFromYaml roundtrip' {
            Get-Command ConvertFrom-SuperJsonToYaml -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            Get-Command ConvertTo-SuperJsonFromYaml -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            # Skip if node not available
            if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
                Set-ItResult -Skipped -Because "Node.js not available"
                return
            }
            # Skip if yq not available
            if (-not (Get-Command yq -ErrorAction SilentlyContinue)) {
                Set-ItResult -Skipped -Because "yq command not available"
                return
            }
            # Check if superjson is available
            if (-not (Test-NpmPackageAvailable -PackageName 'superjson')) {
                Set-ItResult -Skipped -Because "superjson package not installed. Install with: pnpm add -g superjson"
                return
            }
            $originalYaml = "name: test`nvalue: 123"
            $tempFile = Join-Path $TestDrive 'test.yaml'
            Set-Content -Path $tempFile -Value $originalYaml
            { ConvertTo-SuperJsonFromYaml -InputPath $tempFile } | Should -Not -Throw
            $superjsonFile = $tempFile -replace '\.ya?ml$', '.superjson'
            if (Test-Path $superjsonFile) {
                { ConvertFrom-SuperJsonToYaml -InputPath $superjsonFile } | Should -Not -Throw
            }
        }

        It 'ConvertFrom-SuperJsonToToon and ConvertTo-SuperJsonFromToon roundtrip' {
            Get-Command ConvertFrom-SuperJsonToToon -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            Get-Command ConvertTo-SuperJsonFromToon -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            # Skip if node not available
            if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
                Set-ItResult -Skipped -Because "Node.js not available"
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
            if (Test-Path $superjsonFile) {
                { ConvertFrom-SuperJsonToToon -InputPath $superjsonFile } | Should -Not -Throw
                $toonFile = $superjsonFile -replace '\.superjson$', '.toon'
                if (Test-Path $toonFile) {
                    { ConvertTo-SuperJsonFromToon -InputPath $toonFile } | Should -Not -Throw
                }
            }
        }

        It 'ConvertFrom-SuperJsonToToml and ConvertTo-SuperJsonFromToml roundtrip' {
            Get-Command ConvertFrom-SuperJsonToToml -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            Get-Command ConvertTo-SuperJsonFromToml -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            # Skip if node not available
            if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
                Set-ItResult -Skipped -Because "Node.js not available"
                return
            }
            # Skip if yq not available
            if (-not (Get-Command yq -ErrorAction SilentlyContinue)) {
                Set-ItResult -Skipped -Because "yq command not available"
                return
            }
            # Skip if PSToml not available
            if (-not (Get-Module -ListAvailable -Name PSToml -ErrorAction SilentlyContinue)) {
                Set-ItResult -Skipped -Because "PSToml module not available"
                return
            }
            # Check if superjson is available
            if (-not (Test-NpmPackageAvailable -PackageName 'superjson')) {
                Set-ItResult -Skipped -Because "superjson package not installed. Install with: pnpm add -g superjson"
                return
            }
            $originalToml = "name = `"test`"`nvalue = 123"
            $tempFile = Join-Path $TestDrive 'test.toml'
            Set-Content -Path $tempFile -Value $originalToml
            { ConvertTo-SuperJsonFromToml -InputPath $tempFile } | Should -Not -Throw
            $superjsonFile = $tempFile -replace '\.toml$', '.superjson'
            if (Test-Path $superjsonFile) {
                { ConvertFrom-SuperJsonToToml -InputPath $superjsonFile } | Should -Not -Throw
            }
        }

        It 'ConvertFrom-SuperJsonToXml and ConvertTo-SuperJsonFromXml roundtrip' {
            Get-Command ConvertFrom-SuperJsonToXml -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            Get-Command ConvertTo-SuperJsonFromXml -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            # Skip if node not available
            if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
                Set-ItResult -Skipped -Because "Node.js not available"
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
            if (Test-Path $superjsonFile) {
                { ConvertFrom-SuperJsonToXml -InputPath $superjsonFile } | Should -Not -Throw
            }
        }
    }
}

