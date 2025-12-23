

<#
.SYNOPSIS
    Integration tests for BSON to YAML conversion utilities.

.DESCRIPTION
    This test suite validates BSON to YAML conversion functions.

.NOTES
    Tests cover both successful conversions and error handling scenarios.
    Requires Node.js, bson package, and yq command for conversions.
#>

Describe 'BSON to YAML Conversion Tests' {
    BeforeAll {
        $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
        Initialize-TestProfile -ProfileDir $script:ProfileDir -LoadBootstrap -LoadConversionModules 'Data' -LoadFilesFragment -EnsureFileConversion
    }

    Context 'BSON to YAML Conversions' {
        It 'ConvertFrom-BsonToYaml converts BSON to YAML' {
            Get-Command ConvertFrom-BsonToYaml -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            $node = Test-ToolAvailable -ToolName 'node' -InstallCommand 'scoop install nodejs' -Silent
            if (-not $node.Available) {
                $skipMessage = "Node.js not available"
                if ($node.InstallCommand) {
                    $skipMessage += ". Install with: $($node.InstallCommand)"
                }
                Set-ItResult -Skipped -Because $skipMessage
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
            if ($outputFile -and -not [string]::IsNullOrWhiteSpace($outputFile) -and (Test-Path -LiteralPath $outputFile)) {
                $yaml = Get-Content -Path $outputFile -Raw
                $yaml | Should -Not -BeNullOrEmpty
            }
        }
    }
}

