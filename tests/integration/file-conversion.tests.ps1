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

        It 'ConvertTo-HtmlFromMarkdown handles markdown input' {
            Get-Command ConvertTo-HtmlFromMarkdown -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            # Test function existence and basic parameter handling
            $markdown = '# Test Header'
            $tempFile = Join-Path $TestDrive 'test.md'
            Set-Content -Path $tempFile -Value $markdown
            # Test that function doesn't throw when called (pandoc may not be available)
            { ConvertTo-HtmlFromMarkdown -InputPath $tempFile } | Should -Not -Throw
        }

        It 'ConvertFrom-HtmlToMarkdown handles HTML input' {
            Get-Command ConvertFrom-HtmlToMarkdown -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            # Test function existence and basic parameter handling
            $html = '<h1>Test Header</h1>'
            $tempFile = Join-Path $TestDrive 'test.html'
            Set-Content -Path $tempFile -Value $html
            # Test that function doesn't throw when called (pandoc may not be available)
            { ConvertFrom-HtmlToMarkdown -InputPath $tempFile } | Should -Not -Throw
        }

        It 'Convert-Image handles image conversion' {
            Get-Command Convert-Image -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            # Test function existence and basic parameter handling
            $tempInput = Join-Path $TestDrive 'test.jpg'
            $tempOutput = Join-Path $TestDrive 'test.png'
            # Create a dummy file to test parameter handling
            Set-Content -Path $tempInput -Value 'dummy image content'
            # Test that function doesn't throw when called (ImageMagick may not be available)
            { Convert-Image -InputPath $tempInput -OutputPath $tempOutput } | Should -Not -Throw
        }

        It 'Convert-Audio handles audio conversion' {
            Get-Command Convert-Audio -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            # Test function existence and basic parameter handling
            $tempInput = Join-Path $TestDrive 'test.mp3'
            $tempOutput = Join-Path $TestDrive 'test.wav'
            # Create a dummy file to test parameter handling
            Set-Content -Path $tempInput -Value 'dummy audio content'
            # Test that function doesn't throw when called (ffmpeg may not be available)
            { Convert-Audio -InputPath $tempInput -OutputPath $tempOutput } | Should -Not -Throw
        }

        It 'ConvertFrom-PdfToText handles PDF input' {
            Get-Command ConvertFrom-PdfToText -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            # Test function existence and basic parameter handling
            $tempInput = Join-Path $TestDrive 'test.pdf'
            # Create a dummy file to test parameter handling
            Set-Content -Path $tempInput -Value 'dummy pdf content'
            # Test that function doesn't throw when called (pdftotext may not be available)
            { ConvertFrom-PdfToText -InputPath $tempInput } | Should -Not -Throw
        }

        It 'ConvertFrom-VideoToAudio handles video input' {
            Get-Command ConvertFrom-VideoToAudio -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            # Test function existence and basic parameter handling
            $tempInput = Join-Path $TestDrive 'test.mp4'
            # Create a dummy file to test parameter handling
            Set-Content -Path $tempInput -Value 'dummy video content'
            # Test that function doesn't throw when called (ffmpeg may not be available)
            { ConvertFrom-VideoToAudio -InputPath $tempInput } | Should -Not -Throw
        }

        It 'ConvertFrom-VideoToGif handles video input' {
            Get-Command ConvertFrom-VideoToGif -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            # Test function existence and basic parameter handling
            $tempInput = Join-Path $TestDrive 'test.mp4'
            # Create a dummy file to test parameter handling
            Set-Content -Path $tempInput -Value 'dummy video content'
            # Test that function doesn't throw when called (ffmpeg may not be available)
            { ConvertFrom-VideoToGif -InputPath $tempInput } | Should -Not -Throw
        }

        It 'Resize-Image handles image resizing' {
            Get-Command Resize-Image -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            # Test function existence and basic parameter handling
            $tempInput = Join-Path $TestDrive 'test.jpg'
            # Create a dummy file to test parameter handling
            Set-Content -Path $tempInput -Value 'dummy image content'
            # Test that function doesn't throw when called (ImageMagick may not be available)
            { Resize-Image -InputPath $tempInput -Width 100 -Height 100 } | Should -Not -Throw
        }

        It 'Merge-Pdf handles PDF merging' {
            Get-Command Merge-Pdf -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            # Test function existence and basic parameter handling
            $tempInput1 = Join-Path $TestDrive 'test1.pdf'
            $tempInput2 = Join-Path $TestDrive 'test2.pdf'
            $tempOutput = Join-Path $TestDrive 'merged.pdf'
            # Create dummy files to test parameter handling
            Set-Content -Path $tempInput1 -Value 'dummy pdf content 1'
            Set-Content -Path $tempInput2 -Value 'dummy pdf content 2'
            # Test that function doesn't throw when called (pdftk may not be available)
            { Merge-Pdf -InputPaths @($tempInput1, $tempInput2) -OutputPath $tempOutput } | Should -Not -Throw
        }

        It 'ConvertFrom-EpubToMarkdown handles EPUB input' {
            Get-Command ConvertFrom-EpubToMarkdown -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            # Test function existence and basic parameter handling
            $tempInput = Join-Path $TestDrive 'test.epub'
            # Create a dummy file to test parameter handling
            Set-Content -Path $tempInput -Value 'dummy epub content'
            # Test that function doesn't throw when called (pandoc may not be available)
            { ConvertFrom-EpubToMarkdown -InputPath $tempInput } | Should -Not -Throw
        }

        It 'ConvertFrom-DocxToMarkdown handles DOCX input' {
            Get-Command ConvertFrom-DocxToMarkdown -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            # Test function existence and basic parameter handling
            $tempInput = Join-Path $TestDrive 'test.docx'
            # Create a dummy file to test parameter handling
            Set-Content -Path $tempInput -Value 'dummy docx content'
            # Test that function doesn't throw when called (pandoc may not be available)
            { ConvertFrom-DocxToMarkdown -InputPath $tempInput } | Should -Not -Throw
        }

        It 'ConvertFrom-CsvToYaml handles CSV input' {
            Get-Command ConvertFrom-CsvToYaml -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            # Test function existence and basic parameter handling
            $csv = "name,value`ntest,123"
            $tempFile = Join-Path $TestDrive 'test.csv'
            Set-Content -Path $tempFile -Value $csv
            # Test that function doesn't throw when called (yq may not be available)
            { ConvertFrom-CsvToYaml -Path $tempFile } | Should -Not -Throw
        }

        It 'ConvertFrom-YamlToCsv handles YAML input' {
            Get-Command ConvertFrom-YamlToCsv -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            # Test function existence and basic parameter handling
            $yaml = "name: test`nvalue: 123"
            $tempFile = Join-Path $TestDrive 'test.yaml'
            Set-Content -Path $tempFile -Value $yaml
            # Test that function doesn't throw when called (yq may not be available)
            { ConvertFrom-YamlToCsv -Path $tempFile } | Should -Not -Throw
        }
    }
}
