

<#
.SYNOPSIS
    Integration tests for invalid input handling.

.DESCRIPTION
    This test suite validates handling of invalid input formats
    across conversion functions.

.NOTES
    Tests ensure graceful handling of invalid input data.
#>

Describe 'Invalid Input Handling Tests' {
    BeforeAll {
        $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
        Initialize-TestProfile -ProfileDir $script:ProfileDir -LoadBootstrap -LoadConversionModules 'Data' -LoadFilesFragment -EnsureFileConversion
    }

    Context 'Invalid input handling' {
        It 'ConvertFrom-TomlToJson handles invalid TOML gracefully' {
            Get-Command ConvertFrom-TomlToJson -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            # Skip if yq not available
            if (-not (Get-Command yq -ErrorAction SilentlyContinue)) {
                Set-ItResult -Skipped -Because "yq command not available"
                return
            }
            $invalidToml = "invalid = toml content [unclosed"
            $tempFile = Join-Path $TestDrive 'invalid.toml'
            Set-Content -Path $tempFile -Value $invalidToml
            { ConvertFrom-TomlToJson -InputPath $tempFile 2>$null } | Should -Not -Throw
        }

        It 'ConvertTo-SuperJsonFromJson handles invalid JSON gracefully' {
            Get-Command ConvertTo-SuperJsonFromJson -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            # Skip if node not available
            $node = Test-ToolAvailable -ToolName 'node' -InstallCommand 'scoop install nodejs' -Silent
            if (-not $node.Available) {
                $skipMessage = "Node.js not available"
                if ($node.InstallCommand) {
                    $skipMessage += ". Install with: $($node.InstallCommand)"
                }
                Set-ItResult -Skipped -Because $skipMessage
                return
            }
            $invalidJson = '{"invalid": json'
            $tempFile = Join-Path $TestDrive 'invalid.json'
            Set-Content -Path $tempFile -Value $invalidJson
            { ConvertTo-SuperJsonFromJson -InputPath $tempFile 2>$null } | Should -Not -Throw
        }

        It 'ConvertFrom-SuperJsonToJson handles invalid SuperJSON gracefully' {
            Get-Command ConvertFrom-SuperJsonToJson -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            # Skip if node not available
            $node = Test-ToolAvailable -ToolName 'node' -InstallCommand 'scoop install nodejs' -Silent
            if (-not $node.Available) {
                $skipMessage = "Node.js not available"
                if ($node.InstallCommand) {
                    $skipMessage += ". Install with: $($node.InstallCommand)"
                }
                Set-ItResult -Skipped -Because $skipMessage
                return
            }
            $invalidSuperJson = '{"json": "invalid", "meta": {invalid}}'
            $tempFile = Join-Path $TestDrive 'invalid.superjson'
            Set-Content -Path $tempFile -Value $invalidSuperJson
            { ConvertFrom-SuperJsonToJson -InputPath $tempFile 2>$null } | Should -Not -Throw
        }
    }
}

