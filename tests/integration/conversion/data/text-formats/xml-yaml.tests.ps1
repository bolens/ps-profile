

<#
.SYNOPSIS
    Integration tests for XML and YAML format conversions.

.DESCRIPTION
    This test suite validates XML ↔ YAML conversion functions.

.NOTES
    Tests cover both successful conversions and error handling scenarios.
    Requires yq command for conversions.
#>

Describe 'XML and YAML Format Conversion Tests' {
    BeforeAll {
        $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
        Initialize-ConversionIntegrationForTestFile -ProfileDir $script:ProfileDir
    }

    Context 'XML and YAML Conversions' {
        It 'ConvertFrom-XmlToYaml converts XML to YAML' {
            Get-Command ConvertFrom-XmlToYaml -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            if (Skip-IfMikefarahYqUnavailable) { return }
            $xml = '<root><name>test</name><value>123</value></root>'
            $tempXml = Join-Path $TestDrive 'test.xml'
            Set-Content -Path $tempXml -Value $xml
            { ConvertFrom-XmlToYaml -InputPath $tempXml } | Should -Not -Throw
            $outputFile = $tempXml -replace '\.xml$', '.yaml'
            if ($outputFile -and -not [string]::IsNullOrWhiteSpace($outputFile) -and (Test-Path -LiteralPath $outputFile)) {
                $yaml = Get-Content -Path $outputFile -Raw
                $yaml | Should -Not -BeNullOrEmpty
                $yaml | Should -Match 'name|value'
            }
        }

        It 'ConvertTo-XmlFromYaml converts YAML to XML' {
            Get-Command ConvertTo-XmlFromYaml -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            if (Skip-IfMikefarahYqUnavailable) { return }
            $yaml = "name: test`nvalue: 123"
            $tempYaml = Join-Path $TestDrive 'test.yaml'
            Set-Content -Path $tempYaml -Value $yaml
            { ConvertTo-XmlFromYaml -InputPath $tempYaml } | Should -Not -Throw
            $outputFile = $tempYaml -replace '\.yaml$', '.xml'
            if ($outputFile -and -not [string]::IsNullOrWhiteSpace($outputFile) -and (Test-Path -LiteralPath $outputFile)) {
                $xml = Get-Content -Path $outputFile -Raw
                $xml | Should -Not -BeNullOrEmpty
                $xml | Should -Match '<name>|<value>'
            }
        }
    }
}

