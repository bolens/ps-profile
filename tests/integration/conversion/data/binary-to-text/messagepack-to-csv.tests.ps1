

<#
.SYNOPSIS
    Integration tests for MessagePack to CSV conversion utilities.

.DESCRIPTION
    This test suite validates MessagePack to CSV conversion functions.

.NOTES
    Tests cover both successful conversions and error handling scenarios.
    Requires Node.js and @msgpack/msgpack package for conversions.
#>

Describe 'MessagePack to CSV Conversion Tests' {
    BeforeAll {
        $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
        Initialize-TestProfile -ProfileDir $script:ProfileDir -LoadBootstrap -LoadConversionModules 'Data' -LoadFilesFragment -EnsureFileConversion
    }

    Context 'MessagePack to CSV Conversions' {
        It 'ConvertFrom-MessagePackToCsv converts MessagePack to CSV' {
            Get-Command ConvertFrom-MessagePackToCsv -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            $node = Test-ToolAvailable -ToolName 'node' -InstallCommand 'scoop install nodejs' -Silent
            if (-not $node.Available) {
                $skipMessage = "Node.js not available"
                if ($node.InstallCommand) {
                    $skipMessage += ". Install with: $($node.InstallCommand)"
                }
                Set-ItResult -Skipped -Because $skipMessage
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
            if ($outputFile -and -not [string]::IsNullOrWhiteSpace($outputFile) -and (Test-Path -LiteralPath $outputFile)) {
                $csv = Get-Content -Path $outputFile -Raw
                $csv | Should -Not -BeNullOrEmpty
                $csv | Should -Match 'name|value'
            }
        }
    }
}

