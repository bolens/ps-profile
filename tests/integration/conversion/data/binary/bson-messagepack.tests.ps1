

<#
.SYNOPSIS
    Integration tests for BSON and MessagePack binary format conversions.

.DESCRIPTION
    This test suite validates BSON ↔ MessagePack conversion functions.

.NOTES
    Tests cover both successful conversions and error handling scenarios.
    Requires Node.js and respective packages for conversions.
#>

Describe 'BSON and MessagePack Conversion Tests' {
    BeforeAll {
        $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
        Initialize-TestProfile -ProfileDir $script:ProfileDir -LoadBootstrap -LoadConversionModules 'Data' -LoadFilesFragment -EnsureFileConversion
    }

    Context 'BSON and MessagePack Conversions' {
        It 'ConvertTo-MessagePackFromBson converts BSON to MessagePack' {
            Get-Command ConvertTo-MessagePackFromBson -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            $node = Test-ToolAvailable -ToolName 'node' -InstallCommand 'scoop install nodejs' -Silent
            if (-not $node.Available) {
                $skipMessage = "Node.js not available"
                if ($node.InstallCommand) {
                    $skipMessage += ". Install with: $($node.InstallCommand)"
                }
                Set-ItResult -Skipped -Because $skipMessage
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
            if ($outputFile -and -not [string]::IsNullOrWhiteSpace($outputFile) -and (Test-Path -LiteralPath $outputFile)) {
                $msgpack = Get-Content -Path $outputFile -Raw -AsByteStream
                $msgpack | Should -Not -BeNullOrEmpty
            }
        }

        It 'ConvertTo-BsonFromMessagePack converts MessagePack to BSON' {
            Get-Command ConvertTo-BsonFromMessagePack -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            $node = Test-ToolAvailable -ToolName 'node' -InstallCommand 'scoop install nodejs' -Silent
            if (-not $node.Available) {
                $skipMessage = "Node.js not available"
                if ($node.InstallCommand) {
                    $skipMessage += ". Install with: $($node.InstallCommand)"
                }
                Set-ItResult -Skipped -Because $skipMessage
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
            if ($outputFile -and -not [string]::IsNullOrWhiteSpace($outputFile) -and (Test-Path -LiteralPath $outputFile)) {
                $bson = Get-Content -Path $outputFile -Raw -AsByteStream
                $bson | Should -Not -BeNullOrEmpty
            }
        }
    }
}

