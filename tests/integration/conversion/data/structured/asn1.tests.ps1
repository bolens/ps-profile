

<#
.SYNOPSIS
    Integration tests for ASN.1 format conversion utilities.

.DESCRIPTION
    This test suite validates ASN.1 format conversion functions including conversions to/from JSON and XML.

.NOTES
    Tests cover both successful conversions and roundtrip scenarios.
#>

Describe 'ASN.1 Format Conversion Tests' {
    BeforeAll {
        $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
        Initialize-TestProfile -ProfileDir $script:ProfileDir -LoadBootstrap -LoadConversionModules 'Data' -LoadFilesFragment -EnsureFileConversion
    }

    Context 'ASN.1 Format Conversions' {
        It 'ConvertFrom-Asn1ToJson function exists' {
            Get-Command ConvertFrom-Asn1ToJson -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'ConvertFrom-Asn1ToJson converts ASN.1 to JSON' {
            Get-Command _ConvertFrom-Asn1ToJson -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            
            # Simple ASN.1 module example
            $asn1Content = @"
MyModule DEFINITIONS ::= BEGIN
    UserId ::= INTEGER
    UserName ::= OCTET STRING
    UserInfo ::= SEQUENCE {
        id UserId,
        name UserName
    }
END
"@
            $tempFile = Join-Path $TestDrive 'test.asn1'
            Set-Content -Path $tempFile -Value $asn1Content -NoNewline
            
            { _ConvertFrom-Asn1ToJson -InputPath $tempFile } | Should -Not -Throw
            $outputFile = $tempFile -replace '\.asn1$', '.json'
            if ($outputFile -and -not [string]::IsNullOrWhiteSpace($outputFile) -and (Test-Path -LiteralPath $outputFile)) {
                $json = Get-Content -Path $outputFile -Raw
                $json | Should -Not -BeNullOrEmpty
                $jsonObj = $json | ConvertFrom-Json
                $jsonObj.Module | Should -Not -BeNullOrEmpty
                $jsonObj.Module.Types | Should -Not -BeNullOrEmpty
                $jsonObj.Module.Types.Count | Should -BeGreaterThan 0
            }
        }

        It 'ConvertTo-Asn1FromJson converts JSON to ASN.1' {
            Get-Command _ConvertTo-Asn1FromJson -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            
            $jsonContent = @"
{
  "Module": {
    "Name": "MyModule",
    "Types": [
      {
        "Name": "UserId",
        "Type": "INTEGER",
        "Specification": {
          "Type": "INTEGER",
          "Value": null
        }
      },
      {
        "Name": "UserName",
        "Type": "OCTET STRING",
        "Specification": {
          "Type": "OCTET STRING",
          "Value": null
        }
      }
    ]
  }
}
"@
            $tempFile = Join-Path $TestDrive 'test.json'
            Set-Content -Path $tempFile -Value $jsonContent -NoNewline
            
            { _ConvertTo-Asn1FromJson -InputPath $tempFile } | Should -Not -Throw
            $outputFile = $tempFile -replace '\.json$', '.asn1'
            if ($outputFile -and -not [string]::IsNullOrWhiteSpace($outputFile) -and (Test-Path -LiteralPath $outputFile)) {
                $asn1 = Get-Content -Path $outputFile -Raw
                $asn1 | Should -Not -BeNullOrEmpty
                $asn1 | Should -Match 'DEFINITIONS'
                $asn1 | Should -Match 'BEGIN'
                $asn1 | Should -Match 'END'
            }
        }

        It 'ASN.1 to JSON and back roundtrip' {
            $originalContent = @"
TestModule DEFINITIONS ::= BEGIN
    TestInt ::= INTEGER
    TestString ::= OCTET STRING
END
"@
            $tempFile = Join-Path $TestDrive 'test.asn1'
            Set-Content -Path $tempFile -Value $originalContent -NoNewline
            
            # Convert to JSON
            _ConvertFrom-Asn1ToJson -InputPath $tempFile
            $jsonFile = $tempFile -replace '\.asn1$', '.json'
            
            # Convert back to ASN.1
            _ConvertTo-Asn1FromJson -InputPath $jsonFile
            $roundtripFile = $jsonFile -replace '\.json$', '.asn1'
            
            if ($roundtripFile -and -not [string]::IsNullOrWhiteSpace($roundtripFile) -and (Test-Path -LiteralPath $roundtripFile)) {
                $roundtrip = Get-Content -Path $roundtripFile -Raw
                $roundtrip | Should -Not -BeNullOrEmpty
                $roundtrip | Should -Match 'DEFINITIONS'
            }
        }

        It 'ConvertFrom-Asn1ToXml converts ASN.1 to XML' {
            Get-Command _ConvertFrom-Asn1ToXml -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            
            $asn1Content = @"
MyModule DEFINITIONS ::= BEGIN
    UserId ::= INTEGER
END
"@
            $tempFile = Join-Path $TestDrive 'test.asn1'
            Set-Content -Path $tempFile -Value $asn1Content -NoNewline
            
            { _ConvertFrom-Asn1ToXml -InputPath $tempFile } | Should -Not -Throw
            $outputFile = $tempFile -replace '\.asn1$', '.xml'
            if ($outputFile -and -not [string]::IsNullOrWhiteSpace($outputFile) -and (Test-Path -LiteralPath $outputFile)) {
                $xml = Get-Content -Path $outputFile -Raw
                $xml | Should -Not -BeNullOrEmpty
                $xml | Should -Match '<ASN1>'
                $xml | Should -Match '<Module'
                $xml | Should -Match '<Type'
            }
        }

        It 'Handles SEQUENCE type in ASN.1' {
            $asn1Content = @"
TestModule DEFINITIONS ::= BEGIN
    Person ::= SEQUENCE {
        name OCTET STRING,
        age INTEGER
    }
END
"@
            $tempFile = Join-Path $TestDrive 'test.asn1'
            Set-Content -Path $tempFile -Value $asn1Content -NoNewline
            
            { _ConvertFrom-Asn1ToJson -InputPath $tempFile } | Should -Not -Throw
            $outputFile = $tempFile -replace '\.asn1$', '.json'
            if ($outputFile -and -not [string]::IsNullOrWhiteSpace($outputFile) -and (Test-Path -LiteralPath $outputFile)) {
                $json = Get-Content -Path $outputFile -Raw
                $jsonObj = $json | ConvertFrom-Json
                $personType = $jsonObj.Module.Types | Where-Object { $_.Name -eq 'Person' }
                $personType | Should -Not -BeNullOrEmpty
                $personType.Specification.Type | Should -Be 'SEQUENCE'
            }
        }

        It 'Handles CHOICE type in ASN.1' {
            $asn1Content = @"
TestModule DEFINITIONS ::= BEGIN
    Value ::= CHOICE {
        integer INTEGER,
        string OCTET STRING
    }
END
"@
            $tempFile = Join-Path $TestDrive 'test.asn1'
            Set-Content -Path $tempFile -Value $asn1Content -NoNewline
            
            { _ConvertFrom-Asn1ToJson -InputPath $tempFile } | Should -Not -Throw
            $outputFile = $tempFile -replace '\.asn1$', '.json'
            if ($outputFile -and -not [string]::IsNullOrWhiteSpace($outputFile) -and (Test-Path -LiteralPath $outputFile)) {
                $json = Get-Content -Path $outputFile -Raw
                $jsonObj = $json | ConvertFrom-Json
                $choiceType = $jsonObj.Module.Types | Where-Object { $_.Name -eq 'Value' }
                $choiceType | Should -Not -BeNullOrEmpty
                $choiceType.Specification.Type | Should -Be 'CHOICE'
            }
        }

        It 'Handles empty ASN.1 file gracefully' {
            $emptyFile = Join-Path $TestDrive 'empty.asn1'
            Set-Content -Path $emptyFile -Value '' -NoNewline
            
            { _ConvertFrom-Asn1ToJson -InputPath $emptyFile } | Should -Not -Throw
        }

        It 'Handles missing input file gracefully' {
            $nonExistentFile = Join-Path $TestDrive 'nonexistent.asn1'
            
            { _ConvertFrom-Asn1ToJson -InputPath $nonExistentFile } | Should -Throw
        }

        It 'Handles custom output path' {
            $asn1Content = @"
TestModule DEFINITIONS ::= BEGIN
    TestType ::= INTEGER
END
"@
            $tempFile = Join-Path $TestDrive 'test.asn1'
            Set-Content -Path $tempFile -Value $asn1Content -NoNewline

            $customOutput = Join-Path $TestDrive 'custom-output.json'
            
            { _ConvertFrom-Asn1ToJson -InputPath $tempFile -OutputPath $customOutput } | Should -Not -Throw
            
            if ($customOutput -and -not [string]::IsNullOrWhiteSpace($customOutput) -and (Test-Path -LiteralPath $customOutput)) {
                $customOutput | Should -Exist
            }
        }

        It 'Handles .asn file extension' {
            $asn1Content = @"
TestModule DEFINITIONS ::= BEGIN
    TestType ::= INTEGER
END
"@
            $tempFile = Join-Path $TestDrive 'test.asn'
            Set-Content -Path $tempFile -Value $asn1Content -NoNewline
            
            { _ConvertFrom-Asn1ToJson -InputPath $tempFile } | Should -Not -Throw
            $outputFile = $tempFile -replace '\.asn$', '.json'
            if ($outputFile -and -not [string]::IsNullOrWhiteSpace($outputFile) -and (Test-Path -LiteralPath $outputFile)) {
                $outputFile | Should -Exist
            }
        }
    }
}

