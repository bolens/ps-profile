

Describe 'File Utility Functions Edge Cases' {
    BeforeAll {
        try {
            $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists

            # Some conversion initializers are optional for these edge case tests.
            # If YAML core initializer is missing, provide a no-op stub so that
            # Ensure-FileConversion-Data doesn't fail when exercising JSON/Base64.
            if (-not (Get-Command Initialize-FileConversion-CoreBasicYaml -ErrorAction SilentlyContinue)) {
                <#
                .SYNOPSIS
                    Performs operations related to Initialize-FileConversion-CoreBasicYaml.
                
                .DESCRIPTION
                    Performs operations related to Initialize-FileConversion-CoreBasicYaml.
                
                .OUTPUTS
                    object
                #>
                function Initialize-FileConversion-CoreBasicYaml { }
            }

            # Load bootstrap first
            $bootstrapPath = Join-Path $script:ProfileDir 'bootstrap.ps1'
            if (-not ($bootstrapPath -and -not [string]::IsNullOrWhiteSpace($bootstrapPath) -and (Test-Path -LiteralPath $bootstrapPath))) {
                throw "Bootstrap file not found at: $bootstrapPath"
            }
            . $bootstrapPath
        }
        catch {
            $errorDetails = @{
                Message  = $_.Exception.Message
                Type     = $_.Exception.GetType().FullName
                Location = $_.InvocationInfo.ScriptLineNumber
            }
            Write-Error "Failed to initialize test setup in BeforeAll: $($errorDetails | ConvertTo-Json -Compress)" -ErrorAction Stop
            throw
        }
        
        # Load files fragment (this loads all conversion modules)
        $filesPath = Join-Path $script:ProfileDir 'files.ps1'
        if ($null -eq $filesPath -or [string]::IsNullOrWhiteSpace($filesPath)) {
            throw "FilesPath is null or empty"
        }
        if (-not (Test-Path -LiteralPath $filesPath)) {
            throw "Files fragment not found at: $filesPath"
        }
        . $filesPath
            
        # Ensure file utility modules are loaded
        $filesModulesDir = Join-Path $script:ProfileDir 'files-modules'
        $inspectionDir = Join-Path $filesModulesDir 'inspection'
        $requiredModules = @('files-head-tail.ps1', 'files-hash.ps1', 'files-size.ps1', 'files-hexdump.ps1')
        foreach ($moduleFile in $requiredModules) {
            $modulePath = Join-Path $inspectionDir $moduleFile
            if ($modulePath -and (Test-Path -LiteralPath $modulePath)) {
                try {
                    . $modulePath
                }
                catch {
                    Write-Warning "Failed to load module ${moduleFile}: $_"
                }
            }
        }

        # Manually initialize only the conversion helpers needed for these edge-case tests
        # to avoid failures from unrelated/missing initializers in Ensure-FileConversion-Data.
        $script:FileConversionDataManuallyInitialized = $false
        $conversionDataDir = Join-Path $script:ProfileDir 'conversion-modules' 'data'
        if ($conversionDataDir -and -not [string]::IsNullOrWhiteSpace($conversionDataDir) -and (Test-Path -LiteralPath $conversionDataDir)) {
            # Load JSON and Base64 modules directly
            $jsonModulePath = Join-Path (Join-Path $conversionDataDir 'core') 'json.ps1'
            if ($jsonModulePath -and -not [string]::IsNullOrWhiteSpace($jsonModulePath) -and (Test-Path -LiteralPath $jsonModulePath)) {
                try {
                    . $jsonModulePath
                }
                catch {
                    Write-Warning "Failed to load JSON module: $_"
                }
            }
            $base64ModulePath = Join-Path (Join-Path $conversionDataDir 'base64') 'base64.ps1'
            if ($base64ModulePath -and -not [string]::IsNullOrWhiteSpace($base64ModulePath) -and (Test-Path -LiteralPath $base64ModulePath)) {
                try {
                    . $base64ModulePath
                }
                catch {
                    Write-Warning "Failed to load Base64 module: $_"
                }
            }

            # Call their initializers if available
            if (Get-Command Initialize-FileConversion-CoreBasicJson -ErrorAction SilentlyContinue) {
                try {
                    Initialize-FileConversion-CoreBasicJson
                    $script:FileConversionDataManuallyInitialized = $true
                }
                catch {
                    Write-Warning "Failed to initialize JSON conversion: $_"
                }
            }
            if (Get-Command Initialize-FileConversion-CoreBasicBase64 -ErrorAction SilentlyContinue) {
                try {
                    Initialize-FileConversion-CoreBasicBase64
                    $script:FileConversionDataManuallyInitialized = $true
                }
                catch {
                    Write-Warning "Failed to initialize Base64 conversion: $_"
                }
            }
        }

        # Mark data conversion as initialized so Format-Json / ConvertTo-Base64
        # don't attempt to call the bulk Ensure-FileConversion-Data initializer.
        if ($script:FileConversionDataManuallyInitialized) {
            $global:FileConversionDataInitialized = $true
        }

        # Try to ensure file utilities, but avoid calling Ensure-FileConversion-Data here,
        # since we've already initialized the specific helpers we care about.
        try {
            if (Get-Command Ensure-FileUtilities -ErrorAction SilentlyContinue) {
                Ensure-FileUtilities
            }
        }
        catch {
            # Ignore errors from missing conversion modules
            Write-Warning "Some file utilities may not be available: $_"
        }
            
        # Verify functions are available for the tests below
        $script:FormatJsonAvailable = (Get-Command Format-Json -ErrorAction SilentlyContinue) -ne $null
        $script:ConvertToBase64Available = (Get-Command ConvertTo-Base64 -ErrorAction SilentlyContinue) -ne $null
    }
    catch {
        $errorDetails = @{
            Message  = $_.Exception.Message
            Type     = $_.Exception.GetType().FullName
            Location = $_.InvocationInfo.ScriptLineNumber
        }
        Write-Error "Failed to complete test setup in BeforeAll: $($errorDetails | ConvertTo-Json -Compress)" -ErrorAction Stop
        throw
    }
}

Context 'Basic file utility edge cases' {
    It 'json-pretty handles invalid JSON gracefully' {
        if (-not $script:FormatJsonAvailable) {
            Skip -Message "Format-Json function not available (conversion modules may not be loaded)"
        }
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
        if (-not $script:ConvertToBase64Available) {
            Skip -Message "ConvertTo-Base64 function not available (conversion modules may not be loaded)"
        }
        $empty = ''
        $encoded = $empty | to-base64
        $decoded = $encoded | from-base64
        $decoded.TrimEnd("`r", "`n") | Should -Be $empty
    }

    It 'to-base64 handles unicode strings' {
        if (-not $script:ConvertToBase64Available) {
            Skip -Message "ConvertTo-Base64 function not available (conversion modules may not be loaded)"
        }
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


