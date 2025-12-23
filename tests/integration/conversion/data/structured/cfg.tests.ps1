

<#
.SYNOPSIS
    Integration tests for CFG/ConfigParser format conversion utilities.

.DESCRIPTION
    This test suite validates CFG/ConfigParser format conversion functions including conversions to/from JSON, YAML, and INI.

.NOTES
    Tests cover both successful conversions and error handling scenarios.
    CFG/ConfigParser conversions require Python with configparser module (standard library).
    Some tests may be skipped if Python is not available.
#>

Describe 'CFG/ConfigParser Format Conversion Tests' {
    BeforeAll {
        $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
        Initialize-TestProfile -ProfileDir $script:ProfileDir -LoadBootstrap -LoadConversionModules 'Data' -LoadFilesFragment -EnsureFileConversion
        
        # Check for Python availability
        $script:PythonAvailable = $false
        if (Get-Command Get-PythonPath -ErrorAction SilentlyContinue) {
            try {
                $pythonPath = Get-PythonPath
                if ($pythonPath) {
                    $script:PythonAvailable = $true
                }
            }
            catch {
                $script:PythonAvailable = $false
            }
        }
    }

    Context 'CFG/ConfigParser Format Conversions' {
        It 'ConvertFrom-CfgToJson function exists' {
            Get-Command ConvertFrom-CfgToJson -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'ConvertTo-CfgFromJson function exists' {
            Get-Command ConvertTo-CfgFromJson -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'ConvertFrom-CfgToYaml function exists' {
            Get-Command ConvertFrom-CfgToYaml -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'ConvertTo-CfgFromYaml function exists' {
            Get-Command ConvertTo-CfgFromYaml -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'ConvertFrom-CfgToIni function exists' {
            Get-Command ConvertFrom-CfgToIni -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'ConvertTo-CfgFromIni function exists' {
            Get-Command ConvertTo-CfgFromIni -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'ConvertFrom-CfgToJson converts CFG to JSON' {
            if (-not $script:PythonAvailable) {
                Set-ItResult -Skipped -Because "Python is not available"
                return
            }
            
            $cfgContent = @"
[section1]
key1 = value1
key2 = value2

[section2]
key3 = value3
"@
            $cfgFile = Join-Path $TestDrive 'test.cfg'
            Set-Content -LiteralPath $cfgFile -Value $cfgContent -Encoding UTF8
            
            $jsonFile = Join-Path $TestDrive 'test.json'
            ConvertFrom-CfgToJson -InputPath $cfgFile -OutputPath $jsonFile
            
            if ($jsonFile -and -not [string]::IsNullOrWhiteSpace($jsonFile)) {
                Test-Path -LiteralPath $jsonFile | Should -Be $true
            }
            $jsonContent = Get-Content -LiteralPath $jsonFile -Raw
            $jsonContent | Should -Match 'section1'
            $jsonContent | Should -Match 'key1'
        }

        It 'ConvertTo-CfgFromJson converts JSON to CFG' {
            if (-not $script:PythonAvailable) {
                Set-ItResult -Skipped -Because "Python is not available"
                return
            }
            
            $jsonContent = '{"section1": {"key1": "value1", "key2": "value2"}, "section2": {"key3": "value3"}}'
            $jsonFile = Join-Path $TestDrive 'test.json'
            Set-Content -LiteralPath $jsonFile -Value $jsonContent -Encoding UTF8
            
            $cfgFile = Join-Path $TestDrive 'test.cfg'
            ConvertTo-CfgFromJson -InputPath $jsonFile -OutputPath $cfgFile
            
            if ($cfgFile -and -not [string]::IsNullOrWhiteSpace($cfgFile)) {
                Test-Path -LiteralPath $cfgFile | Should -Be $true
            }
            $cfgContent = Get-Content -LiteralPath $cfgFile -Raw
            $cfgContent | Should -Match '\[section1\]'
        }

        It 'ConvertFrom-CfgToYaml converts CFG to YAML' {
            if (-not $script:PythonAvailable) {
                Set-ItResult -Skipped -Because "Python is not available"
                return
            }
            
            $cfgContent = @"
[section1]
key1 = value1
"@
            $cfgFile = Join-Path $TestDrive 'test.cfg'
            Set-Content -LiteralPath $cfgFile -Value $cfgContent -Encoding UTF8
            
            $yamlFile = Join-Path $TestDrive 'test.yaml'
            ConvertFrom-CfgToYaml -InputPath $cfgFile -OutputPath $yamlFile
            
            if ($yamlFile -and -not [string]::IsNullOrWhiteSpace($yamlFile)) {
                Test-Path -LiteralPath $yamlFile | Should -Be $true
            }
        }

        It 'ConvertFrom-CfgToIni converts CFG to INI' {
            if (-not $script:PythonAvailable) {
                Set-ItResult -Skipped -Because "Python is not available"
                return
            }
            
            $cfgContent = @"
[section1]
key1 = value1
"@
            $cfgFile = Join-Path $TestDrive 'test.cfg'
            Set-Content -LiteralPath $cfgFile -Value $cfgContent -Encoding UTF8
            
            $iniFile = Join-Path $TestDrive 'test.ini'
            ConvertFrom-CfgToIni -InputPath $cfgFile -OutputPath $iniFile
            
            if ($iniFile -and -not [string]::IsNullOrWhiteSpace($iniFile)) {
                Test-Path -LiteralPath $iniFile | Should -Be $true
            }
            $iniContent = Get-Content -LiteralPath $iniFile -Raw
            $iniContent | Should -Match '\[section1\]'
        }

        It 'ConvertTo-CfgFromIni converts INI to CFG' {
            if (-not $script:PythonAvailable) {
                Set-ItResult -Skipped -Because "Python is not available"
                return
            }
            
            $iniContent = @"
[section1]
key1 = value1
"@
            $iniFile = Join-Path $TestDrive 'test.ini'
            Set-Content -LiteralPath $iniFile -Value $iniContent -Encoding UTF8
            
            $cfgFile = Join-Path $TestDrive 'test.cfg'
            ConvertTo-CfgFromIni -InputPath $iniFile -OutputPath $cfgFile
            
            if ($cfgFile -and -not [string]::IsNullOrWhiteSpace($cfgFile)) {
                Test-Path -LiteralPath $cfgFile | Should -Be $true
            }
        }

        It 'ConvertFrom-CfgToJson handles missing input file gracefully' {
            if (-not $script:PythonAvailable) {
                Set-ItResult -Skipped -Because "Python is not available"
                return
            }
            
            $nonExistentFile = Join-Path $TestDrive 'nonexistent.cfg'
            { ConvertFrom-CfgToJson -InputPath $nonExistentFile } | Should -Throw
        }

        It 'ConvertTo-CfgFromJson handles missing input file gracefully' {
            if (-not $script:PythonAvailable) {
                Set-ItResult -Skipped -Because "Python is not available"
                return
            }
            
            $nonExistentFile = Join-Path $TestDrive 'nonexistent.json'
            { ConvertTo-CfgFromJson -InputPath $nonExistentFile } | Should -Throw
        }

        It 'CFG roundtrip conversion (CFG → JSON → CFG)' {
            if (-not $script:PythonAvailable) {
                Set-ItResult -Skipped -Because "Python is not available"
                return
            }
            
            $originalCfg = @"
[section1]
key1 = value1
key2 = value2
"@
            $cfgFile = Join-Path $TestDrive 'original.cfg'
            Set-Content -LiteralPath $cfgFile -Value $originalCfg -Encoding UTF8
            
            # CFG to JSON
            $jsonFile = Join-Path $TestDrive 'intermediate.json'
            ConvertFrom-CfgToJson -InputPath $cfgFile -OutputPath $jsonFile
            
            # JSON to CFG
            $backToCfgFile = Join-Path $TestDrive 'back.cfg'
            ConvertTo-CfgFromJson -InputPath $jsonFile -OutputPath $backToCfgFile
            
            if ($backToCfgFile -and -not [string]::IsNullOrWhiteSpace($backToCfgFile)) {
                Test-Path -LiteralPath $backToCfgFile | Should -Be $true
            }
        }

        It 'CFG conversion functions require InputPath parameter' {
            $testCases = @(
                'ConvertFrom-CfgToJson'
                'ConvertTo-CfgFromJson'
                'ConvertFrom-CfgToYaml'
                'ConvertTo-CfgFromYaml'
                'ConvertFrom-CfgToIni'
                'ConvertTo-CfgFromIni'
            )
            
            foreach ($funcName in $testCases) {
                $func = Get-Command $funcName -ErrorAction SilentlyContinue
                if ($func) {
                    { & $funcName } | Should -Throw
                }
            }
        }
    }
}

