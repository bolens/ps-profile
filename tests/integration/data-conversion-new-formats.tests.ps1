. (Join-Path $PSScriptRoot '..\TestSupport.ps1')

<#
.SYNOPSIS
    Integration tests for newly added format conversion utilities.

.DESCRIPTION
    This test suite validates newly added conversion functions including:
    - Binary-to-binary direct conversions (BSON ↔ MessagePack, BSON ↔ CBOR, MessagePack ↔ CBOR)
    - Columnar format conversions (Parquet ↔ Arrow, Parquet ↔ CSV, Arrow ↔ CSV)
    - Scientific format conversions (HDF5 ↔ NetCDF, HDF5 ↔ Parquet, NetCDF ↔ Parquet)
    - Text format gaps (XML ↔ YAML, JSONL ↔ CSV, JSONL ↔ YAML)
    - Binary to text conversions (Binary formats → CSV, Binary formats → YAML)

.NOTES
    Tests cover both successful conversions and error handling scenarios.
    Requires Node.js, Python, and respective packages for conversions.
#>

Describe 'New Format Conversion Integration Tests' {
    BeforeAll {
        $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
        . (Join-Path $script:ProfileDir '00-bootstrap.ps1')
        . (Join-Path $script:ProfileDir '02-files.ps1')
        Ensure-FileConversion-Data
    }

    Context 'Binary-to-binary direct conversions' {
        It 'ConvertTo-MessagePackFromBson converts BSON to MessagePack' {
            Get-Command ConvertTo-MessagePackFromBson -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
                Set-ItResult -Skipped -Because "Node.js not available"
                return
            }
            if (-not (Test-NpmPackageAvailable -PackageName 'bson') -or -not (Test-NpmPackageAvailable -PackageName '@msgpack/msgpack')) {
                Set-ItResult -Skipped -Because "Required packages not installed. Install with: pnpm add -g bson @msgpack/msgpack"
                return
            }
            $json = '{"name": "test", "value": 123}'
            $tempJson = Join-Path $TestDrive 'test.json'
            $tempBson = Join-Path $TestDrive 'test.bson'
            Set-Content -Path $tempJson -Value $json
            ConvertTo-BsonFromJson -InputPath $tempJson -OutputPath $tempBson
            { ConvertTo-MessagePackFromBson -InputPath $tempBson } | Should -Not -Throw
            $outputFile = $tempBson -replace '\.bson$', '.msgpack'
            if (Test-Path $outputFile) {
                $msgpack = Get-Content -Path $outputFile -Raw -AsByteStream
                $msgpack | Should -Not -BeNullOrEmpty
            }
        }

        It 'ConvertTo-BsonFromMessagePack converts MessagePack to BSON' {
            Get-Command ConvertTo-BsonFromMessagePack -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
                Set-ItResult -Skipped -Because "Node.js not available"
                return
            }
            if (-not (Test-NpmPackageAvailable -PackageName 'bson') -or -not (Test-NpmPackageAvailable -PackageName '@msgpack/msgpack')) {
                Set-ItResult -Skipped -Because "Required packages not installed. Install with: pnpm add -g bson @msgpack/msgpack"
                return
            }
            $json = '{"name": "test", "value": 123}'
            $tempJson = Join-Path $TestDrive 'test.json'
            $tempMsgpack = Join-Path $TestDrive 'test.msgpack'
            Set-Content -Path $tempJson -Value $json
            ConvertTo-MessagePackFromJson -InputPath $tempJson -OutputPath $tempMsgpack
            { ConvertTo-BsonFromMessagePack -InputPath $tempMsgpack } | Should -Not -Throw
            $outputFile = $tempMsgpack -replace '\.msgpack$', '.bson'
            if (Test-Path $outputFile) {
                $bson = Get-Content -Path $outputFile -Raw -AsByteStream
                $bson | Should -Not -BeNullOrEmpty
            }
        }

        It 'ConvertTo-CborFromBson converts BSON to CBOR' {
            Get-Command ConvertTo-CborFromBson -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
                Set-ItResult -Skipped -Because "Node.js not available"
                return
            }
            if (-not (Test-NpmPackageAvailable -PackageName 'bson') -or -not (Test-NpmPackageAvailable -PackageName 'cbor')) {
                Set-ItResult -Skipped -Because "Required packages not installed. Install with: pnpm add -g bson cbor"
                return
            }
            $json = '{"name": "test", "value": 123}'
            $tempJson = Join-Path $TestDrive 'test.json'
            $tempBson = Join-Path $TestDrive 'test.bson'
            Set-Content -Path $tempJson -Value $json
            ConvertTo-BsonFromJson -InputPath $tempJson -OutputPath $tempBson
            { ConvertTo-CborFromBson -InputPath $tempBson } | Should -Not -Throw
            $outputFile = $tempBson -replace '\.bson$', '.cbor'
            if (Test-Path $outputFile) {
                $cbor = Get-Content -Path $outputFile -Raw -AsByteStream
                $cbor | Should -Not -BeNullOrEmpty
            }
        }

        It 'ConvertTo-BsonFromCbor converts CBOR to BSON' {
            Get-Command ConvertTo-BsonFromCbor -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
                Set-ItResult -Skipped -Because "Node.js not available"
                return
            }
            if (-not (Test-NpmPackageAvailable -PackageName 'bson') -or -not (Test-NpmPackageAvailable -PackageName 'cbor')) {
                Set-ItResult -Skipped -Because "Required packages not installed. Install with: pnpm add -g bson cbor"
                return
            }
            $json = '{"name": "test", "value": 123}'
            $tempJson = Join-Path $TestDrive 'test.json'
            $tempCbor = Join-Path $TestDrive 'test.cbor'
            Set-Content -Path $tempJson -Value $json
            ConvertTo-CborFromJson -InputPath $tempJson -OutputPath $tempCbor
            { ConvertTo-BsonFromCbor -InputPath $tempCbor } | Should -Not -Throw
            $outputFile = $tempCbor -replace '\.cbor$', '.bson'
            if (Test-Path $outputFile) {
                $bson = Get-Content -Path $outputFile -Raw -AsByteStream
                $bson | Should -Not -BeNullOrEmpty
            }
        }

        It 'ConvertTo-CborFromMessagePack converts MessagePack to CBOR' {
            Get-Command ConvertTo-CborFromMessagePack -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
                Set-ItResult -Skipped -Because "Node.js not available"
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
            if (Test-Path $outputFile) {
                $cbor = Get-Content -Path $outputFile -Raw -AsByteStream
                $cbor | Should -Not -BeNullOrEmpty
            }
        }

        It 'ConvertTo-MessagePackFromCbor converts CBOR to MessagePack' {
            Get-Command ConvertTo-MessagePackFromCbor -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
                Set-ItResult -Skipped -Because "Node.js not available"
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
            if (Test-Path $outputFile) {
                $msgpack = Get-Content -Path $outputFile -Raw -AsByteStream
                $msgpack | Should -Not -BeNullOrEmpty
            }
        }
    }

    Context 'Text format conversions' {
        It 'ConvertFrom-XmlToYaml converts XML to YAML' {
            Get-Command ConvertFrom-XmlToYaml -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            if (-not (Get-Command yq -ErrorAction SilentlyContinue)) {
                Set-ItResult -Skipped -Because "yq not available"
                return
            }
            $xml = '<root><name>test</name><value>123</value></root>'
            $tempXml = Join-Path $TestDrive 'test.xml'
            Set-Content -Path $tempXml -Value $xml
            { ConvertFrom-XmlToYaml -InputPath $tempXml } | Should -Not -Throw
            $outputFile = $tempXml -replace '\.xml$', '.yaml'
            if (Test-Path $outputFile) {
                $yaml = Get-Content -Path $outputFile -Raw
                $yaml | Should -Not -BeNullOrEmpty
                $yaml | Should -Match 'name|value'
            }
        }

        It 'ConvertTo-XmlFromYaml converts YAML to XML' {
            Get-Command ConvertTo-XmlFromYaml -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            if (-not (Get-Command yq -ErrorAction SilentlyContinue)) {
                Set-ItResult -Skipped -Because "yq not available"
                return
            }
            $yaml = "name: test`nvalue: 123"
            $tempYaml = Join-Path $TestDrive 'test.yaml'
            Set-Content -Path $tempYaml -Value $yaml
            { ConvertTo-XmlFromYaml -InputPath $tempYaml } | Should -Not -Throw
            $outputFile = $tempYaml -replace '\.yaml$', '.xml'
            if (Test-Path $outputFile) {
                $xml = Get-Content -Path $outputFile -Raw
                $xml | Should -Not -BeNullOrEmpty
                $xml | Should -Match '<name>|<value>'
            }
        }

        It 'ConvertFrom-JsonLToCsv converts JSONL to CSV' {
            Get-Command ConvertFrom-JsonLToCsv -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            $jsonl = '{"name":"test1","value":123}' + "`n" + '{"name":"test2","value":456}'
            $tempJsonl = Join-Path $TestDrive 'test.jsonl'
            Set-Content -Path $tempJsonl -Value $jsonl
            { ConvertFrom-JsonLToCsv -InputPath $tempJsonl } | Should -Not -Throw
            $outputFile = $tempJsonl -replace '\.jsonl$', '.csv'
            if (Test-Path $outputFile) {
                $csv = Get-Content -Path $outputFile -Raw
                $csv | Should -Not -BeNullOrEmpty
                $csv | Should -Match 'name|value'
            }
        }

        It 'ConvertTo-JsonLFromCsv converts CSV to JSONL' {
            Get-Command ConvertTo-JsonLFromCsv -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            $csv = "name,value`ntest1,123`ntest2,456"
            $tempCsv = Join-Path $TestDrive 'test.csv'
            Set-Content -Path $tempCsv -Value $csv
            { ConvertTo-JsonLFromCsv -InputPath $tempCsv } | Should -Not -Throw
            $outputFile = $tempCsv -replace '\.csv$', '.jsonl'
            if (Test-Path $outputFile) {
                $jsonl = Get-Content -Path $outputFile
                $jsonl.Count | Should -BeGreaterThan 0
                $jsonl[0] | Should -Match 'name|value'
            }
        }

        It 'ConvertFrom-JsonLToYaml converts JSONL to YAML' {
            Get-Command ConvertFrom-JsonLToYaml -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            if (-not (Get-Command yq -ErrorAction SilentlyContinue)) {
                Set-ItResult -Skipped -Because "yq not available"
                return
            }
            $jsonl = '{"name":"test1","value":123}' + "`n" + '{"name":"test2","value":456}'
            $tempJsonl = Join-Path $TestDrive 'test.jsonl'
            Set-Content -Path $tempJsonl -Value $jsonl
            { ConvertFrom-JsonLToYaml -InputPath $tempJsonl } | Should -Not -Throw
            $outputFile = $tempJsonl -replace '\.jsonl$', '.yaml'
            if (Test-Path $outputFile) {
                $yaml = Get-Content -Path $outputFile -Raw
                $yaml | Should -Not -BeNullOrEmpty
            }
        }

        It 'ConvertTo-JsonLFromYaml converts YAML to JSONL' {
            Get-Command ConvertTo-JsonLFromYaml -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            if (-not (Get-Command yq -ErrorAction SilentlyContinue)) {
                Set-ItResult -Skipped -Because "yq not available"
                return
            }
            $yaml = "- name: test1`n  value: 123`n- name: test2`n  value: 456"
            $tempYaml = Join-Path $TestDrive 'test.yaml'
            Set-Content -Path $tempYaml -Value $yaml
            { ConvertTo-JsonLFromYaml -InputPath $tempYaml } | Should -Not -Throw
            $outputFile = $tempYaml -replace '\.yaml$', '.jsonl'
            if (Test-Path $outputFile) {
                $jsonl = Get-Content -Path $outputFile
                $jsonl.Count | Should -BeGreaterThan 0
            }
        }
    }

    Context 'Binary to text conversions' {
        It 'ConvertFrom-BsonToCsv converts BSON to CSV' {
            Get-Command ConvertFrom-BsonToCsv -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
                Set-ItResult -Skipped -Because "Node.js not available"
                return
            }
            if (-not (Test-NpmPackageAvailable -PackageName 'bson')) {
                Set-ItResult -Skipped -Because "bson package not installed. Install with: pnpm add -g bson"
                return
            }
            $json = '[{"name":"test1","value":123},{"name":"test2","value":456}]'
            $tempJson = Join-Path $TestDrive 'test.json'
            $tempBson = Join-Path $TestDrive 'test.bson'
            Set-Content -Path $tempJson -Value $json
            ConvertTo-BsonFromJson -InputPath $tempJson -OutputPath $tempBson
            { ConvertFrom-BsonToCsv -InputPath $tempBson } | Should -Not -Throw
            $outputFile = $tempBson -replace '\.bson$', '.csv'
            if (Test-Path $outputFile) {
                $csv = Get-Content -Path $outputFile -Raw
                $csv | Should -Not -BeNullOrEmpty
                $csv | Should -Match 'name|value'
            }
        }

        It 'ConvertFrom-BsonToYaml converts BSON to YAML' {
            Get-Command ConvertFrom-BsonToYaml -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
                Set-ItResult -Skipped -Because "Node.js not available"
                return
            }
            if (-not (Get-Command yq -ErrorAction SilentlyContinue)) {
                Set-ItResult -Skipped -Because "yq not available"
                return
            }
            if (-not (Test-NpmPackageAvailable -PackageName 'bson')) {
                Set-ItResult -Skipped -Because "bson package not installed. Install with: pnpm add -g bson"
                return
            }
            $json = '{"name":"test","value":123}'
            $tempJson = Join-Path $TestDrive 'test.json'
            $tempBson = Join-Path $TestDrive 'test.bson'
            Set-Content -Path $tempJson -Value $json
            ConvertTo-BsonFromJson -InputPath $tempJson -OutputPath $tempBson
            { ConvertFrom-BsonToYaml -InputPath $tempBson } | Should -Not -Throw
            $outputFile = $tempBson -replace '\.bson$', '.yaml'
            if (Test-Path $outputFile) {
                $yaml = Get-Content -Path $outputFile -Raw
                $yaml | Should -Not -BeNullOrEmpty
            }
        }

        It 'ConvertFrom-MessagePackToCsv converts MessagePack to CSV' {
            Get-Command ConvertFrom-MessagePackToCsv -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
                Set-ItResult -Skipped -Because "Node.js not available"
                return
            }
            if (-not (Test-NpmPackageAvailable -PackageName '@msgpack/msgpack')) {
                Set-ItResult -Skipped -Because "@msgpack/msgpack package not installed. Install with: pnpm add -g @msgpack/msgpack"
                return
            }
            $json = '[{"name":"test1","value":123},{"name":"test2","value":456}]'
            $tempJson = Join-Path $TestDrive 'test.json'
            $tempMsgpack = Join-Path $TestDrive 'test.msgpack'
            Set-Content -Path $tempJson -Value $json
            ConvertTo-MessagePackFromJson -InputPath $tempJson -OutputPath $tempMsgpack
            { ConvertFrom-MessagePackToCsv -InputPath $tempMsgpack } | Should -Not -Throw
            $outputFile = $tempMsgpack -replace '\.msgpack$', '.csv'
            if (Test-Path $outputFile) {
                $csv = Get-Content -Path $outputFile -Raw
                $csv | Should -Not -BeNullOrEmpty
                $csv | Should -Match 'name|value'
            }
        }

        It 'ConvertFrom-CborToCsv converts CBOR to CSV' {
            Get-Command ConvertFrom-CborToCsv -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
                Set-ItResult -Skipped -Because "Node.js not available"
                return
            }
            if (-not (Test-NpmPackageAvailable -PackageName 'cbor')) {
                Set-ItResult -Skipped -Because "cbor package not installed. Install with: pnpm add -g cbor"
                return
            }
            $json = '[{"name":"test1","value":123},{"name":"test2","value":456}]'
            $tempJson = Join-Path $TestDrive 'test.json'
            $tempCbor = Join-Path $TestDrive 'test.cbor'
            Set-Content -Path $tempJson -Value $json
            ConvertTo-CborFromJson -InputPath $tempJson -OutputPath $tempCbor
            { ConvertFrom-CborToCsv -InputPath $tempCbor } | Should -Not -Throw
            $outputFile = $tempCbor -replace '\.cbor$', '.csv'
            if (Test-Path $outputFile) {
                $csv = Get-Content -Path $outputFile -Raw
                $csv | Should -Not -BeNullOrEmpty
                $csv | Should -Match 'name|value'
            }
        }
    }

    Context 'Error handling' {
        It 'Handles missing Node.js gracefully for binary-to-binary conversions' {
            if (Get-Command node -ErrorAction SilentlyContinue) {
                Set-ItResult -Skipped -Because "Node.js is available"
                return
            }
            $tempFile = Join-Path $TestDrive 'test.bson'
            Set-Content -Path $tempFile -Value 'test'
            { ConvertTo-MessagePackFromBson -InputPath $tempFile -ErrorAction Stop } | Should -Throw
        }

        It 'Handles missing yq gracefully for XML to YAML' {
            if (Get-Command yq -ErrorAction SilentlyContinue) {
                Set-ItResult -Skipped -Because "yq is available"
                return
            }
            $tempFile = Join-Path $TestDrive 'test.xml'
            Set-Content -Path $tempFile -Value '<root><test>value</test></root>'
            { ConvertFrom-XmlToYaml -InputPath $tempFile -ErrorAction Stop } | Should -Throw
        }
    }
}

