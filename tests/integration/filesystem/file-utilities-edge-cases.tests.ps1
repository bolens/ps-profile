

Describe 'File Utility Functions Edge Cases' {
    BeforeAll {
        try {
            $testSupportPath = Get-TestSupportPath -StartPath $PSScriptRoot
            if (-not (Test-Path -LiteralPath $testSupportPath)) {
                throw "TestSupport file not found at: $testSupportPath"
            }
            . $testSupportPath

            $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists

            if (-not (Get-Command Initialize-FileConversion-CoreBasicYaml -ErrorAction SilentlyContinue)) {
                function Initialize-FileConversion-CoreBasicYaml { }
            }

            Initialize-TestProfile -ProfileDir $script:ProfileDir -LoadBootstrap -LoadFilesFragment

            $conversionDataDir = Join-Path $script:ProfileDir 'conversion-modules' 'data'
            $jsonModulePath = Join-Path $conversionDataDir 'core' 'json.ps1'
            if (Test-Path -LiteralPath $jsonModulePath) {
                $null = . $jsonModulePath
                if (Get-Command Initialize-FileConversion-CoreBasicJson -ErrorAction SilentlyContinue) {
                    Initialize-FileConversion-CoreBasicJson
                }
            }

            $base64ModulePath = Join-Path $conversionDataDir 'base64' 'base64.ps1'
            if (Test-Path -LiteralPath $base64ModulePath) {
                $null = . $base64ModulePath
                if (Get-Command Initialize-FileConversion-CoreBasicBase64 -ErrorAction SilentlyContinue) {
                    Initialize-FileConversion-CoreBasicBase64
                }
            }

            $global:FileConversionDataInitialized = $true

            $global:FileUtilitiesInitialized = $false
            if (Get-Command Ensure-FileUtilities -ErrorAction SilentlyContinue) {
                Ensure-FileUtilities
            }

            if (-not (Get-Command Get-FileHashValue -ErrorAction SilentlyContinue)) {
                $inspectionDir = Join-Path $script:ProfileDir 'files-modules' 'inspection'
                foreach ($moduleFile in @('files-head-tail.ps1', 'files-hash.ps1', 'files-size.ps1', 'files-hexdump.ps1')) {
                    $modulePath = Join-Path $inspectionDir $moduleFile
                    if (Test-Path -LiteralPath $modulePath) {
                        if (Get-Command Invoke-GlobalProfileScript -ErrorAction SilentlyContinue) {
                            Invoke-GlobalProfileScript -Path $modulePath
                        }
                        else {
                            $null = . $modulePath
                        }
                    }
                }

                foreach ($initializer in @(
                        'Initialize-FileUtilities-HeadTail'
                        'Initialize-FileUtilities-Hash'
                        'Initialize-FileUtilities-Size'
                        'Initialize-FileUtilities-HexDump'
                    )) {
                    if (Get-Command $initializer -ErrorAction SilentlyContinue) {
                        & $initializer
                    }
                }

                $global:FileUtilitiesInitialized = $true
            }

            $script:FormatJsonAvailable = $null -ne (Get-Command Format-Json -ErrorAction SilentlyContinue)
            $script:ConvertToBase64Available = $null -ne (Get-Command ConvertTo-Base64 -ErrorAction SilentlyContinue)
            $script:FileHashAvailable = $null -ne (Get-Command Get-FileHashValue -ErrorAction SilentlyContinue)
            $script:FileSizeAvailable = $null -ne (Get-Command Get-FileSize -ErrorAction SilentlyContinue)
        }
        catch {
            Write-Error "Failed to initialize test setup in BeforeAll: $($_.Exception.Message)" -ErrorAction Stop
            throw
        }
    }

    Context 'Basic file utility edge cases' {
        It 'json-pretty handles invalid JSON gracefully' {
            if (-not $script:FormatJsonAvailable) {
                Set-ItResult -Skipped -Because 'Format-Json is not available'
                return
            }
            $invalidJson = '{"invalid": json}'
            {
                try {
                    $originalWarningPreference = $WarningPreference
                    $WarningPreference = 'SilentlyContinue'
                    Format-Json -InputObject $invalidJson | Out-Null
                }
                finally {
                    $WarningPreference = $originalWarningPreference
                }
            } | Should -Not -Throw
        }

        It 'to-base64 handles empty strings' {
            if (-not $script:ConvertToBase64Available) {
                Set-ItResult -Skipped -Because 'ConvertTo-Base64 is not available'
                return
            }
            $empty = ''
            $encoded = ConvertTo-Base64 -InputObject $empty
            $decoded = ConvertFrom-Base64 -InputObject $encoded
            $decoded.TrimEnd("`r", "`n") | Should -Be $empty
        }

        It 'to-base64 handles unicode strings' {
            if (-not $script:ConvertToBase64Available) {
                Set-ItResult -Skipped -Because 'ConvertTo-Base64 is not available'
                return
            }
            $unicode = 'Hello 世界'
            $encoded = ConvertTo-Base64 -InputObject $unicode
            $decoded = ConvertFrom-Base64 -InputObject $encoded
            $decoded.TrimEnd("`r", "`n") | Should -Be $unicode
        }

        It 'file-hash handles non-existent files' {
            if (-not $script:FileHashAvailable) {
                Set-ItResult -Skipped -Because 'Get-FileHashValue is not available'
                return
            }
            $nonExistent = Join-Path $TestDrive 'non_existent.txt'
            {
                try {
                    $originalWarningPreference = $WarningPreference
                    $WarningPreference = 'SilentlyContinue'
                    Get-FileHashValue -Path $nonExistent | Out-Null
                }
                finally {
                    $WarningPreference = $originalWarningPreference
                }
            } | Should -Not -Throw
        }

        It 'filesize handles different file sizes' {
            if (-not $script:FileSizeAvailable) {
                Set-ItResult -Skipped -Because 'Get-FileSize is not available'
                return
            }
            $smallFile = Join-Path $TestDrive 'small.txt'
            Set-Content -Path $smallFile -Value 'x' -NoNewline
            $small = Get-FileSize -Path $smallFile
            $small | Should -Match '\d+.*B'

            $largeFile = Join-Path $TestDrive 'large.txt'
            $content = 'x' * 1048576
            Set-Content -Path $largeFile -Value $content -NoNewline
            $large = Get-FileSize -Path $largeFile
            $large | Should -Match '\d+.*MB'
        }
    }
}
