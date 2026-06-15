#
# Tests for file conversion and utility helpers.
#

BeforeAll {
    $current = Get-Item $PSScriptRoot
    while ($null -ne $current) {
        $testSupportPath = Join-Path $current.FullName 'TestSupport.ps1'
        if (Test-Path -LiteralPath $testSupportPath) {
            . $testSupportPath
            break
        }
        if ($current.Name -eq 'tests' -or $current.Parent -eq $null) { break }
        $current = $current.Parent
    }
    $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
    $script:TestTempRoot = New-TestTempDirectory -Prefix 'ProfileFileUtilities'
    . (Join-Path $script:ProfileDir 'bootstrap.ps1')
    . (Join-Path $script:ProfileDir 'files-module-registry.ps1')
    . (Join-Path $script:ProfileDir 'files.ps1')

    $conversionModulesDir = Join-Path $script:ProfileDir 'conversion-modules'
    if (Test-Path $conversionModulesDir) {
        $helpersDir = Join-Path $conversionModulesDir 'helpers'
        if (Test-Path $helpersDir) {
            foreach ($helperFile in @('helpers-xml.ps1', 'helpers-toon.ps1')) {
                $helperPath = Join-Path $helpersDir $helperFile
                if (Test-Path $helperPath) {
                    try {
                        . $helperPath
                    }
                    catch {
                        Write-Warning "Failed to load $helperFile : $($_.Exception.Message)"
                    }
                }
            }
        }

        $dataDir = Join-Path $conversionModulesDir 'data'
        if (Test-Path $dataDir) {
            $coreDir = Join-Path $dataDir 'core'
            if (Test-Path $coreDir) {
                foreach ($coreFile in @(
                        'core-basic-json.ps1', 'core-basic-yaml.ps1', 'core-basic-base64.ps1',
                        'core-basic-csv.ps1', 'core-basic-xml.ps1', 'core-json-extended.ps1', 'core-text-gaps.ps1'
                    )) {
                    $corePath = Join-Path $coreDir $coreFile
                    if (Test-Path $corePath) {
                        try {
                            . $corePath
                        }
                        catch {
                            Write-Warning "Failed to load $coreFile : $($_.Exception.Message)"
                        }
                    }
                }
            }

            $moduleDirs = @(
                @{ Dir = Join-Path $dataDir 'structured'; Files = @('toon.ps1', 'toml.ps1', 'superjson.ps1') },
                @{ Dir = Join-Path $dataDir 'binary'; Files = @('binary-schema-protobuf.ps1', 'binary-schema-avro.ps1', 'binary-schema-flatbuffers.ps1', 'binary-schema-thrift.ps1', 'binary-simple.ps1', 'binary-direct.ps1', 'binary-to-text.ps1') },
                @{ Dir = Join-Path $dataDir 'columnar'; Files = @('columnar-parquet.ps1', 'columnar-arrow.ps1', 'columnar-direct.ps1', 'columnar-to-csv.ps1') },
                @{ Dir = Join-Path $dataDir 'scientific'; Files = @('scientific-hdf5.ps1', 'scientific-netcdf.ps1', 'scientific-direct.ps1', 'scientific-to-columnar.ps1') }
            )

            foreach ($moduleDir in $moduleDirs) {
                if (Test-Path $moduleDir.Dir) {
                    foreach ($moduleFile in $moduleDir.Files) {
                        $modulePath = Join-Path $moduleDir.Dir $moduleFile
                        if (Test-Path $modulePath) {
                            try {
                                . $modulePath
                            }
                            catch {
                                # Silently continue - some modules may have dependencies that aren't available
                            }
                        }
                    }
                }
            }
        }
    }

    try {
        if (Get-Command Ensure-FileConversion-Data -ErrorAction SilentlyContinue) {
            $ErrorActionPreference = 'SilentlyContinue'
            Ensure-FileConversion-Data
            $ErrorActionPreference = 'Continue'
        }
    }
    catch {
        Write-Warning "File conversion data modules not fully available: $($_.Exception.Message)"
    }

    $documentDir = Join-Path $conversionModulesDir 'document'
    if (Test-Path $documentDir) {
        foreach ($docFile in @('document-markdown.ps1', 'document-latex.ps1', 'document-rst.ps1', 'document-common-html.ps1', 'document-common-docx.ps1', 'document-common-epub.ps1')) {
            $docPath = Join-Path $documentDir $docFile
            if (Test-Path $docPath) {
                try {
                    . $docPath
                }
                catch {
                    # Silently continue - some modules may have dependencies that aren't available
                }
            }
        }
    }

    try {
        if (Get-Command Ensure-FileConversion-Documents -ErrorAction SilentlyContinue) {
            $ErrorActionPreference = 'SilentlyContinue'
            Ensure-FileConversion-Documents
            $ErrorActionPreference = 'Continue'
        }
    }
    catch {
        Write-Warning "File conversion document modules not available: $($_.Exception.Message)"
    }

    try {
        if (Get-Command Initialize-FileConversion-MediaImages -ErrorAction SilentlyContinue) {
            Ensure-FileConversion-Media -ErrorAction SilentlyContinue
        }
    }
    catch {
        Write-Warning "File conversion media modules not available: $($_.Exception.Message)"
    }

    $filesModulesDir = Join-Path $script:ProfileDir 'files-modules'
    if (Test-Path $filesModulesDir) {
        $inspectionDir = Join-Path $filesModulesDir 'inspection'
        foreach ($moduleFile in @('files-head-tail.ps1', 'files-hash.ps1', 'files-size.ps1', 'files-hexdump.ps1')) {
            $modulePath = Join-Path $inspectionDir $moduleFile
            if (Test-Path $modulePath) {
                try {
                    . $modulePath
                }
                catch {
                    Write-Warning "Failed to load $moduleFile : $($_.Exception.Message)"
                }
            }
        }
    }

    $allModulesLoaded = $true
    foreach ($module in @(
            'Initialize-FileUtilities-HeadTail',
            'Initialize-FileUtilities-Hash',
            'Initialize-FileUtilities-Size',
            'Initialize-FileUtilities-HexDump'
        )) {
        if (-not (Get-Command $module -ErrorAction SilentlyContinue)) {
            $allModulesLoaded = $false
            break
        }
    }

    if ($allModulesLoaded) {
        try {
            Initialize-FileUtilities-HeadTail -ErrorAction Stop
            Initialize-FileUtilities-Hash -ErrorAction Stop
            Initialize-FileUtilities-Size -ErrorAction Stop
            Initialize-FileUtilities-HexDump -ErrorAction Stop
        }
        catch {
            Write-Warning "Failed to initialize file utility functions: $($_.Exception.Message)"
            Ensure-FileUtilities -ErrorAction SilentlyContinue
        }
    }
    else {
        Write-Warning 'File utility modules not fully available. Some tests may be skipped.'
    }
}

Describe 'Profile file utility functions' {
    Context 'Conversion helpers' {
        It 'json-pretty formats JSON correctly' {
            $json = '{"name":"test","value":123}'
            $result = json-pretty $json
            $result | Should -Match '"name"\s*:\s*"test"'
            $result | Should -Match '"value"\s*:\s*123'
        }

        It 'to-base64 and from-base64 roundtrip correctly' {
            $payload = 'Hello, World!'
            $encoded = $payload | to-base64
            $decoded = $encoded | from-base64
            $decoded.TrimEnd("`r", "`n") | Should -Be $payload
        }

        It 'to-base64 handles empty strings' {
            $encoded = '' | to-base64
            $decoded = $encoded | from-base64
            $decoded.TrimEnd("`r", "`n") | Should -Be ''
        }

        It 'to-base64 handles unicode strings' {
            $payload = 'Hello 世界'
            $encoded = $payload | to-base64
            $decoded = $encoded | from-base64
            $decoded.TrimEnd("`r", "`n") | Should -Be $payload
        }

        It 'Convert-XmlToJsonObject handles nested elements and text nodes' {
            $xml = [xml] '<root><parent><child>value</child><child>value2</child>text</parent></root>'
            $obj = Convert-XmlToJsonObject $xml.DocumentElement
            # Expect parent to contain children array and text node
            $obj.parent | Should -Not -Be $null
            $obj.parent.child | Should -BeOfType System.Object
            # child should be an array of two items
            $obj.parent.child.Count | Should -Be 2
            $obj.parent.'#text' | Should -Be 'text'
        }

        It 'ConvertFrom-XmlToJson produces valid JSON for nested XML' {
            $xml = '<root><items><item>one</item><item>two</item></items></root>'
            $tempFile = Join-Path $script:TestTempRoot 'test_nested.xml'
            Set-Content -Path $tempFile -Value $xml
            $result = ConvertFrom-XmlToJson -Path $tempFile
            $result | Should -Not -BeNullOrEmpty
            $parsed = $result | ConvertFrom-Json
            $parsed.root.items.item.Count | Should -Be 2
            $parsed.root.items.item[0].'#text' | Should -Be 'one'
        }

        It 'Get-FileHead returns first N lines from file' {
            $content = "line1`nline2`nline3`nline4`nline5`nline6`nline7`nline8`nline9`nline10`nline11`nline12"
            $tempFile = Join-Path $script:TestTempRoot 'test_head.txt'
            Set-Content -Path $tempFile -Value $content
            $result = Get-FileHead -Path $tempFile -Lines 5
            $result.Count | Should -Be 5
            $result[0] | Should -Be 'line1'
            $result[4] | Should -Be 'line5'
        }

        It 'Get-FileHead returns first 10 lines by default' {
            $content = (1..15 | ForEach-Object { "line$_" }) -join "`n"
            $tempFile = Join-Path $script:TestTempRoot 'test_head_default.txt'
            Set-Content -Path $tempFile -Value $content
            $result = Get-FileHead -Path $tempFile
            $result.Count | Should -Be 10
            $result[0] | Should -Be 'line1'
            $result[9] | Should -Be 'line10'
        }

        It 'Get-FileTail returns last N lines from file' {
            $content = "line1`nline2`nline3`nline4`nline5`nline6`nline7`nline8`nline9`nline10`nline11`nline12"
            $tempFile = Join-Path $script:TestTempRoot 'test_tail.txt'
            Set-Content -Path $tempFile -Value $content
            $result = Get-FileTail -Path $tempFile -Lines 5
            $result.Count | Should -Be 5
            $result[0] | Should -Be 'line8'
            $result[4] | Should -Be 'line12'
        }

        It 'Get-FileTail returns last 10 lines by default' {
            $content = (1..15 | ForEach-Object { "line$_" }) -join "`n"
            $tempFile = Join-Path $script:TestTempRoot 'test_tail_default.txt'
            Set-Content -Path $tempFile -Value $content
            $result = Get-FileTail -Path $tempFile
            $result.Count | Should -Be 10
            $result[0] | Should -Be 'line6'
            $result[9] | Should -Be 'line15'
        }

        It 'Get-FileHashValue calculates SHA256 hash correctly' {
            $tempFile = Join-Path $script:TestTempRoot 'test_hash.txt'
            Set-Content -Path $tempFile -Value 'test content for hashing' -NoNewline
            $hash = Get-FileHashValue -Path $tempFile
            $hash.Algorithm | Should -Be 'SHA256'
            $hash.Hash.Length | Should -Be 64
            $hash.Path | Should -Be $tempFile
        }

        It 'Get-FileHashValue supports different algorithms' {
            $tempFile = Join-Path $script:TestTempRoot 'test_hash_md5.txt'
            Set-Content -Path $tempFile -Value 'test content' -NoNewline
            $hash = Get-FileHashValue -Path $tempFile -Algorithm MD5
            $hash.Algorithm | Should -Be 'MD5'
            $hash.Hash.Length | Should -Be 32
        }

        It 'Get-FileSize returns human-readable size for small file' {
            $tempFile = Join-Path $script:TestTempRoot 'test_size_small.txt'
            Set-Content -Path $tempFile -Value 'x' -NoNewline
            $result = Get-FileSize -Path $tempFile
            $result | Should -Match '\d+ bytes'
        }

        It 'Get-FileSize returns human-readable size for KB file' {
            $tempFile = Join-Path $script:TestTempRoot 'test_size_kb.txt'
            $content = 'x' * 2048
            Set-Content -Path $tempFile -Value $content -NoNewline
            $result = Get-FileSize -Path $tempFile
            $result | Should -Match '\d+\.\d+ KB'
        }

        It 'Get-FileSize returns human-readable size for MB file' {
            $tempFile = Join-Path $script:TestTempRoot 'test_size_mb.txt'
            $content = 'x' * (1024 * 1024 * 2)
            Set-Content -Path $tempFile -Value $content -NoNewline
            $result = Get-FileSize -Path $tempFile
            $result | Should -Match '\d+\.\d+ MB'
        }

        It 'Get-HexDump produces hex output for file' {
            $tempFile = Join-Path $script:TestTempRoot 'test_hex.txt'
            Set-Content -Path $tempFile -Value 'AB' -NoNewline
            $result = Get-HexDump -Path $tempFile
            $result | Should -Not -BeNullOrEmpty
            # Should contain hex representation
            $result.ToString() | Should -Match '41 42'
        }

        It 'ConvertTo-HtmlFromRst function exists and can be called' {
            $tempFile = Join-Path $script:TestTempRoot 'test.rst'
            Set-Content -Path $tempFile -Value 'Test RST content' -NoNewline
            # Function should exist
            Get-Command ConvertTo-HtmlFromRst | Should -Not -BeNullOrEmpty
            # Should not throw when called (even if pandoc fails)
            { ConvertTo-HtmlFromRst -InputPath $tempFile } | Should -Not -Throw
        }

        It 'ConvertTo-PdfFromRst function exists and can be called' {
            $tempFile = Join-Path $script:TestTempRoot 'test.rst'
            Set-Content -Path $tempFile -Value 'Test RST content' -NoNewline
            Get-Command ConvertTo-PdfFromRst | Should -Not -BeNullOrEmpty
            { ConvertTo-PdfFromRst -InputPath $tempFile } | Should -Not -Throw
        }

        It 'ConvertTo-DocxFromRst function exists and can be called' {
            $tempFile = Join-Path $script:TestTempRoot 'test.rst'
            Set-Content -Path $tempFile -Value 'Test RST content' -NoNewline
            Get-Command ConvertTo-DocxFromRst | Should -Not -BeNullOrEmpty
            { ConvertTo-DocxFromRst -InputPath $tempFile } | Should -Not -Throw
        }

        It 'ConvertTo-LaTeXFromRst function exists and can be called' {
            $tempFile = Join-Path $script:TestTempRoot 'test.rst'
            Set-Content -Path $tempFile -Value 'Test RST content' -NoNewline
            Get-Command ConvertTo-LaTeXFromRst | Should -Not -BeNullOrEmpty
            { ConvertTo-LaTeXFromRst -InputPath $tempFile } | Should -Not -Throw
        }

        It 'ConvertTo-HtmlFromLaTeX function exists and can be called' {
            $tempFile = Join-Path $script:TestTempRoot 'test.tex'
            Set-Content -Path $tempFile -Value '\documentclass{article}\begin{document}Test\end{document}' -NoNewline
            Get-Command ConvertTo-HtmlFromLaTeX | Should -Not -BeNullOrEmpty
            { ConvertTo-HtmlFromLaTeX -InputPath $tempFile } | Should -Not -Throw
        }

        It 'ConvertTo-PdfFromLaTeX function exists and can be called' {
            $tempFile = Join-Path $script:TestTempRoot 'test.tex'
            Set-Content -Path $tempFile -Value '\documentclass{article}\begin{document}Test\end{document}' -NoNewline
            Get-Command ConvertTo-PdfFromLaTeX | Should -Not -BeNullOrEmpty
            { ConvertTo-PdfFromLaTeX -InputPath $tempFile } | Should -Not -Throw
        }

        It 'ConvertTo-DocxFromLaTeX function exists and can be called' {
            $tempFile = Join-Path $script:TestTempRoot 'test.tex'
            Set-Content -Path $tempFile -Value '\documentclass{article}\begin{document}Test\end{document}' -NoNewline
            Get-Command ConvertTo-DocxFromLaTeX | Should -Not -BeNullOrEmpty
            { ConvertTo-DocxFromLaTeX -InputPath $tempFile } | Should -Not -Throw
        }

        It 'ConvertTo-RstFromLaTeX function exists and can be called' {
            $tempFile = Join-Path $script:TestTempRoot 'test.tex'
            Set-Content -Path $tempFile -Value '\documentclass{article}\begin{document}Test\end{document}' -NoNewline
            Get-Command ConvertTo-RstFromLaTeX | Should -Not -BeNullOrEmpty
            { ConvertTo-RstFromLaTeX -InputPath $tempFile } | Should -Not -Throw
        }

        It 'ConvertTo-RstFromMarkdown function exists and can be called' {
            $tempFile = Join-Path $script:TestTempRoot 'test.md'
            Set-Content -Path $tempFile -Value '# Test Markdown' -NoNewline
            Get-Command ConvertTo-RstFromMarkdown | Should -Not -BeNullOrEmpty
            { ConvertTo-RstFromMarkdown -InputPath $tempFile } | Should -Not -Throw
        }

        It 'ConvertTo-LaTeXFromHtml function exists and can be called' {
            $tempFile = Join-Path $script:TestTempRoot 'test.html'
            Set-Content -Path $tempFile -Value '<html><body>Test</body></html>' -NoNewline
            Get-Command ConvertTo-LaTeXFromHtml | Should -Not -BeNullOrEmpty
            { ConvertTo-LaTeXFromHtml -InputPath $tempFile } | Should -Not -Throw
        }

        It 'ConvertTo-LaTeXFromDocx function exists and can be called' {
            $tempFile = Join-Path $script:TestTempRoot 'test.docx'
            # Create a dummy file since we can't easily create a real DOCX
            Set-Content -Path $tempFile -Value 'dummy docx content' -NoNewline
            Get-Command ConvertTo-LaTeXFromDocx | Should -Not -BeNullOrEmpty
            { ConvertTo-LaTeXFromDocx -InputPath $tempFile } | Should -Not -Throw
        }

        It 'ConvertTo-LaTeXFromEpub function exists and can be called' {
            $command = Get-Command ConvertTo-LaTeXFromEpub -ErrorAction SilentlyContinue
            if (-not $command) {
                Set-ItResult -Skipped -Because 'ConvertTo-LaTeXFromEpub is not registered in the profile'
                return
            }

            $tempFile = Join-Path $script:TestTempRoot 'test.epub'
            Set-Content -Path $tempFile -Value 'dummy epub content' -NoNewline
            { ConvertTo-LaTeXFromEpub -InputPath $tempFile } | Should -Not -Throw
        }
    }

    Context 'File metadata helpers' {
        It 'file-hash calculates SHA256 correctly' {
            $tempFile = Join-Path $script:TestTempRoot 'test_hash.txt'
            Set-Content -Path $tempFile -Value 'test content' -NoNewline
            $hash = file-hash $tempFile
            $hash.Algorithm | Should -Be 'SHA256'
            $hash.Hash.Length | Should -Be 64
        }

        It 'filesize returns human-readable size' {
            $tempFile = Join-Path $script:TestTempRoot 'test_size.txt'
            Set-Content -Path $tempFile -Value ('x' * 1024) -NoNewline
            $result = filesize $tempFile
            $result | Should -Match '1\.00 KB'
        }
    }

    Context 'Error handling' {
        It 'file-hash handles non-existent files gracefully' {
            $missing = Join-Path $script:TestTempRoot 'non_existent.txt'
            {
                $originalWarningPreference = $WarningPreference
                                $WarningPreference = 'SilentlyContinue'
                file-hash -Path $missing | Out-Null
            }
            finally {
                $WarningPreference = $originalWarningPreference
            } | Should -Not -Throw
        }
    }
}
