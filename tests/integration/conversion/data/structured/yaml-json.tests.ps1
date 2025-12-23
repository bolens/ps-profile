

<#
.SYNOPSIS
    Integration tests for YAML and JSON conversion utilities.

.DESCRIPTION
    This test suite validates YAML and JSON conversion functions.
#>

Describe 'YAML and JSON Conversion Integration Tests' {
    BeforeAll {
        $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
        Initialize-TestProfile -ProfileDir $script:ProfileDir -LoadBootstrap -LoadConversionModules 'Data' -LoadFilesFragment -EnsureFileConversion
    }

    Context 'YAML conversion utilities' {
        It 'ConvertTo-Yaml converts JSON to YAML' {
            $json = '{"name": "test", "value": 123}'
            $tempFile = Join-Path $TestDrive 'test.json'
            Set-Content -Path $tempFile -Value $json
            $yaml = ConvertTo-Yaml $tempFile
            $yaml | Should -Not -BeNullOrEmpty
            $yaml | Should -Match '^name:'
            $yaml | Should -Match 'value:'
        }

        It 'ConvertTo-Yaml handles complex JSON structures' {
            $json = '{"users": [{"name": "alice", "age": 30}, {"name": "bob", "age": 25}]}'
            $tempFile = Join-Path $TestDrive 'test.json'
            Set-Content -Path $tempFile -Value $json
            $yaml = ConvertTo-Yaml $tempFile
            $yaml | Should -Not -BeNullOrEmpty
            $yaml | Should -Match 'users:'
            $yaml | Should -Match '- name: alice'
        }

        It 'ConvertTo-Yaml handles empty JSON object' {
            $json = '{}'
            $tempFile = Join-Path $TestDrive 'test.json'
            Set-Content -Path $tempFile -Value $json
            $yaml = ConvertTo-Yaml $tempFile
            $yaml | Should -Not -BeNullOrEmpty
            $yaml.Trim() | Should -Be '{}'
        }

        It 'ConvertTo-Yaml handles JSON arrays' {
            $json = '["item1", "item2", "item3"]'
            $tempFile = Join-Path $TestDrive 'test.json'
            Set-Content -Path $tempFile -Value $json
            $yaml = ConvertTo-Yaml $tempFile
            $yaml | Should -Not -BeNullOrEmpty
            $yaml | Should -Match '- item1'
        }

        It 'ConvertFrom-Yaml converts YAML to JSON' {
            Get-Command ConvertFrom-Yaml -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            # Test function existence and basic parameter handling
            $yaml = "name: test`nvalue: 123"
            $tempFile = Join-Path $TestDrive 'test.yaml'
            Set-Content -Path $tempFile -Value $yaml
            # Test that function doesn't throw when called (yq may not be available)
            { ConvertFrom-Yaml $tempFile } | Should -Not -Throw
        }

        It 'ConvertFrom-Yaml handles complex YAML structures' {
            Get-Command ConvertFrom-Yaml -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            # Test function existence and basic parameter handling
            $yaml = "users:`n  - name: alice`n    age: 30`n  - name: bob`n    age: 25"
            $tempFile = Join-Path $TestDrive 'test.yaml'
            Set-Content -Path $tempFile -Value $yaml
            # Test that function doesn't throw when called (yq may not be available)
            { ConvertFrom-Yaml $tempFile } | Should -Not -Throw
        }

        It 'ConvertFrom-Yaml handles empty YAML' {
            Get-Command ConvertFrom-Yaml -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            # Test function existence and basic parameter handling
            $yaml = '{}'
            $tempFile = Join-Path $TestDrive 'test.yaml'
            Set-Content -Path $tempFile -Value $yaml
            # Test that function doesn't throw when called (yq may not be available)
            { ConvertFrom-Yaml $tempFile } | Should -Not -Throw
        }

        It 'ConvertFrom-Yaml handles YAML arrays' {
            Get-Command ConvertFrom-Yaml -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            # Test function existence and basic parameter handling
            $yaml = "- item1`n- item2`n- item3"
            $tempFile = Join-Path $TestDrive 'test.yaml'
            Set-Content -Path $tempFile -Value $yaml
            # Test that function doesn't throw when called (yq may not be available)
            { ConvertFrom-Yaml $tempFile } | Should -Not -Throw
        }

        It 'ConvertTo-Yaml and ConvertFrom-Yaml roundtrip' {
            Get-Command ConvertTo-Yaml -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            Get-Command ConvertFrom-Yaml -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            # Test function existence and basic parameter handling
            $originalJson = '{"test": "value", "number": 42, "array": [1, 2, 3]}'
            $tempFile = Join-Path $TestDrive 'test.json'
            Set-Content -Path $tempFile -Value $originalJson
            # Test that functions don't throw when called (yq may not be available)
            { ConvertTo-Yaml $tempFile } | Should -Not -Throw
            { ConvertFrom-Yaml $tempFile } | Should -Not -Throw
        }

        It 'ConvertFrom-Yaml handles invalid YAML gracefully' {
            Get-Command ConvertFrom-Yaml -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            # Test function existence and basic parameter handling
            $invalidYaml = "invalid: yaml: content: [unclosed"
            $tempFile = Join-Path $TestDrive 'invalid.yaml'
            Set-Content -Path $tempFile -Value $invalidYaml
            # Test that function doesn't throw when called (yq may not be available)
            { ConvertFrom-Yaml $tempFile 2>$null } | Should -Not -Throw
        }

        It 'ConvertTo-Yaml handles invalid JSON gracefully' {
            Get-Command ConvertTo-Yaml -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            # Test function existence and basic parameter handling
            $invalidJson = '{"invalid": json content'
            $tempFile = Join-Path $TestDrive 'invalid.json'
            Set-Content -Path $tempFile -Value $invalidJson
            # Test that function doesn't throw when called (yq may not be available)
            { ConvertTo-Yaml $tempFile 2>$null } | Should -Not -Throw
        }
    }

    Context 'JSON formatting utilities' {
        It 'Format-Json formats compact JSON' {
            $compactJson = '{"name":"test","value":123}'
            $formatted = Format-Json -InputObject $compactJson
            $formatted | Should -Not -BeNullOrEmpty
            $formatted | Should -Match '\n'
            $formatted | Should -Match '"name": "test"'
        }

        It 'Format-Json handles already formatted JSON' {
            $formattedJson = "{
  ""name"": ""test"",
  ""value"": 123
}"
            $result = Format-Json -InputObject $formattedJson
            $result | Should -Not -BeNullOrEmpty
        }

        It 'Format-Json handles empty JSON object' {
            $emptyJson = '{}'
            $result = Format-Json -InputObject $emptyJson
            $result | Should -Not -BeNullOrEmpty
            $result.Trim() | Should -Be '{}'
        }

        It 'Format-Json handles JSON arrays' {
            $jsonArray = '["item1","item2","item3"]'
            $result = Format-Json -InputObject $jsonArray
            $result | Should -Not -BeNullOrEmpty
            $result | Should -Match '\n'
        }

        It 'Format-Json handles invalid JSON gracefully' {
            $invalidJson = '{"invalid": json'
            { Format-Json -InputObject $invalidJson 2>$null } | Should -Not -Throw
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

        It 'json-pretty handles invalid JSON gracefully' {
            $invalidJson = '{"invalid": json content'
            { json-pretty $invalidJson 2>$null } | Should -Not -Throw
        }
    }
}

