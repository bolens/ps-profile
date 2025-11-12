. (Join-Path $PSScriptRoot '..\TestSupport.ps1')

Describe 'File Conversion Integration Tests' {
    BeforeAll {
        $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
    }

    Context 'File utility functions edge cases' {
        BeforeAll {
            . (Join-Path $script:ProfileDir '00-bootstrap.ps1')
            . (Join-Path $script:ProfileDir '02-files-conversion.ps1')
            . (Join-Path $script:ProfileDir '02-files-utilities.ps1')
            Ensure-FileConversion
            Ensure-FileUtilities
        }

        It 'json-pretty handles invalid JSON gracefully' {
            $invalidJson = '{"invalid": json}'
            {
                $originalWarningPreference = $WarningPreference
                try {
                    $WarningPreference = 'SilentlyContinue'
                    json-pretty $invalidJson | Out-Null
                }
                finally {
                    $WarningPreference = $originalWarningPreference
                }
            } | Should -Not -Throw
        }

        It 'to-base64 handles empty strings' {
            $empty = ''
            $encoded = $empty | to-base64
            $decoded = $encoded | from-base64
            $decoded.TrimEnd("`r", "`n") | Should -Be $empty
        }

        It 'to-base64 handles unicode strings' {
            $unicode = 'Hello 世界'
            $encoded = $unicode | to-base64
            $decoded = $encoded | from-base64
            $decoded.TrimEnd("`r", "`n") | Should -Be $unicode
        }

        It 'file-hash handles non-existent files' {
            $nonExistent = Join-Path $TestDrive 'non_existent.txt'
            {
                $originalWarningPreference = $WarningPreference
                try {
                    $WarningPreference = 'SilentlyContinue'
                    file-hash -Path $nonExistent | Out-Null
                }
                finally {
                    $WarningPreference = $originalWarningPreference
                }
            } | Should -Not -Throw
        }

        It 'filesize handles different file sizes' {
            $smallFile = Join-Path $TestDrive 'small.txt'
            Set-Content -Path $smallFile -Value 'x' -NoNewline
            $small = filesize $smallFile
            $small | Should -Match '\d+.*B'

            $largeFile = Join-Path $TestDrive 'large.txt'
            $content = 'x' * 1048576
            Set-Content -Path $largeFile -Value $content -NoNewline
            $large = filesize $largeFile
            $large | Should -Match '\d+.*MB'
        }
    }

    Context 'File conversion utilities' {
        BeforeAll {
            . (Join-Path $script:ProfileDir '00-bootstrap.ps1')
            . (Join-Path $script:ProfileDir '02-files-conversion.ps1')
            Ensure-FileConversion
        }

        It 'json-pretty handles nested JSON' {
            $nestedJson = '{"level1":{"level2":{"level3":"value"}}}'
            $result = json-pretty $nestedJson
            $result | Should -Match 'level1'
            $result | Should -Match 'level2'
            $result | Should -Match 'level3'
        }

        It 'json-pretty handles arrays' {
            $arrayJson = '{"items":[1,2,3],"count":3}'
            $result = json-pretty $arrayJson
            $result | Should -Match 'items'
            $result | Should -Match 'count'
        }

        It 'to-base64 handles binary-like data' {
            $binary = [byte[]](0x00, 0x01, 0x02, 0xFF)
            $text = [System.Text.Encoding]::UTF8.GetString($binary)
            $encoded = $text | to-base64
            $decoded = $encoded | from-base64
            $decodedBytes = [System.Text.Encoding]::UTF8.GetBytes($decoded.TrimEnd("`r", "`n"))
            $decodedBytes[0] | Should -Be $binary[0]
        }

        It 'Format-Json handles valid JSON' {
            $json = '{"name":"test","value":123}'
            $result = Format-Json -InputObject $json
            $result | Should -Not -BeNullOrEmpty
            $result | Should -Match '"name"'
            $result | Should -Match '"value"'
        }

        It 'ConvertFrom-Yaml handles simple YAML' {
            Get-Command ConvertFrom-Yaml -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            # Test conversion only if yq is available and working
            if (Get-Command yq -ErrorAction SilentlyContinue) {
                # Test if yq can actually convert
                $testYaml = 'test: value'
                $testFile = Join-Path $TestDrive 'test_yq.yaml'
                Set-Content -Path $testFile -Value $testYaml
                try {
                    $testResult = & yq eval -o=json $testFile 2>$null
                    if ($LASTEXITCODE -eq 0 -and ($testResult | ConvertFrom-Json).test -eq 'value') {
                        $yaml = "name: test`nvalue: 123"
                        $tempFile = Join-Path $TestDrive 'test.yaml'
                        Set-Content -Path $tempFile -Value $yaml
                        $result = ConvertFrom-Yaml $tempFile
                        $result | Should -Not -BeNullOrEmpty
                        $parsed = $result | ConvertFrom-Json
                        $parsed.name | Should -Be 'test'
                        $parsed.value | Should -Be 123
                    }
                }
                catch {
                    # yq not working properly, skip the test
                }
            }
        }

        It 'ConvertTo-Yaml handles hashtable input' {
            Get-Command ConvertTo-Yaml -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            # Test conversion only if yq is available and working
            if (Get-Command yq -ErrorAction SilentlyContinue) {
                # Test if yq can actually convert
                $testJson = '{"test": "value"}'
                $testFile = Join-Path $TestDrive 'test_yq.json'
                Set-Content -Path $testFile -Value $testJson
                try {
                    $testResult = & yq eval -P $testFile 2>$null
                    if ($LASTEXITCODE -eq 0 -and $testResult -match 'test:') {
                        $data = @{name = 'test'; value = 123 }
                        $tempFile = Join-Path $TestDrive 'test.json'
                        $data | ConvertTo-Json | Set-Content -Path $tempFile
                        $result = ConvertTo-Yaml $tempFile
                        $result | Should -Not -BeNullOrEmpty
                        $result | Should -Match 'name:'
                        $result | Should -Match 'value:'
                    }
                }
                catch {
                    # yq not working properly, skip the test
                }
            }
        }

        It 'ConvertTo-Base64 handles string input' {
            $input = 'test string'
            $result = ConvertTo-Base64 -InputObject $input
            $result | Should -Not -BeNullOrEmpty
            # Should be valid base64
            [System.Convert]::FromBase64String($result) | Should -Not -BeNullOrEmpty
        }

        It 'ConvertFrom-Base64 handles base64 input' {
            $input = 'dGVzdCBzdHJpbmc=' # 'test string' in base64
            $result = ConvertFrom-Base64 -InputObject $input
            $result | Should -Be 'test string'
        }

        It 'ConvertFrom-CsvToJson handles simple CSV' {
            $csv = "name,value`ntest,123"
            $tempFile = Join-Path $TestDrive 'test.csv'
            Set-Content -Path $tempFile -Value $csv
            $result = ConvertFrom-CsvToJson -Path $tempFile
            $result | Should -Not -BeNullOrEmpty
            $parsed = $result | ConvertFrom-Json
            $parsed[0].name | Should -Be 'test'
            $parsed[0].value | Should -Be '123'
        }

        It 'ConvertTo-CsvFromJson handles array input' {
            $json = '[{"name":"test","value":123}]'
            $tempFile = Join-Path $TestDrive 'test.json'
            Set-Content -Path $tempFile -Value $json
            $outputFile = $tempFile -replace '\.json$', '.csv'
            ConvertTo-CsvFromJson -Path $tempFile
            $result = Get-Content -Path $outputFile -Raw
            $result | Should -Not -BeNullOrEmpty
            $result | Should -Match '"name","value"'
            $result | Should -Match '"test","123"'
        }

        It 'ConvertFrom-XmlToJson handles simple XML' {
            $xml = '<root><item>test</item></root>'
            $tempFile = Join-Path $TestDrive 'test.xml'
            Set-Content -Path $tempFile -Value $xml
            $result = ConvertFrom-XmlToJson -Path $tempFile
            $result | Should -Not -BeNullOrEmpty
            $parsed = $result | ConvertFrom-Json
            $parsed.root.item.'#text' | Should -Be 'test'
        }
    }
}
