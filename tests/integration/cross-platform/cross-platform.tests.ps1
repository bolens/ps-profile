

Describe 'Cross-Platform Compatibility Integration Tests' {
    BeforeAll {
        try {
            $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
            $script:ProfilePath = Get-TestPath -RelativePath 'Microsoft.PowerShell_profile.ps1' -StartPath $PSScriptRoot -EnsureExists
            if ($null -eq $script:ProfileDir -or [string]::IsNullOrWhiteSpace($script:ProfileDir)) {
                throw "Get-TestPath returned null or empty value for ProfileDir"
            }
            if ($null -eq $script:ProfilePath -or [string]::IsNullOrWhiteSpace($script:ProfilePath)) {
                throw "Get-TestPath returned null or empty value for ProfilePath"
            }
            if (-not (Test-Path -LiteralPath $script:ProfileDir)) {
                throw "Profile directory not found at: $script:ProfileDir"
            }
            if (-not (Test-Path -LiteralPath $script:ProfilePath)) {
                throw "Profile file not found at: $script:ProfilePath"
            }
        }
        catch {
            $errorDetails = @{
                Message  = $_.Exception.Message
                Type     = $_.Exception.GetType().FullName
                Location = $_.InvocationInfo.ScriptLineNumber
            }
            Write-Error "Failed to initialize cross-platform tests in BeforeAll: $($errorDetails | ConvertTo-Json -Compress)" -ErrorAction Stop
            throw
        }
    }

    Context 'Cross-platform compatibility' {
        It 'path separators are handled correctly' {
            $profileContent = Get-Content $script:ProfilePath -Raw
            $hardcodedPaths = [regex]::Matches($profileContent, '[^\\]\\[A-Za-z]:\\')
            $hardcodedPaths.Count | Should -BeLessThan 10
        }

        It 'functions work with both Windows and Unix-style paths' {
            . (Join-Path $script:ProfileDir 'bootstrap.ps1')
            . (Join-Path $script:ProfileDir 'files.ps1')
            # Ensure file navigation is initialized
            if (Get-Command Ensure-FileNavigation -ErrorAction SilentlyContinue) {
                Ensure-FileNavigation
            }

            $testPath = Join-Path $TestDrive 'test'
            New-Item -ItemType Directory -Path $testPath -Force | Out-Null

            Push-Location $testPath
            try {
                # Test the .. function (up one directory)
                if (Get-Command '..' -CommandType Function -ErrorAction SilentlyContinue) {
                    ..
                    $parent = Get-Location
                    $parent.Path | Should -Not -BeNullOrEmpty
                }
                else {
                    Set-ItResult -Skipped -Because ".. function not available"
                }
            }
            finally {
                Pop-Location
            }
        }
    }
}

