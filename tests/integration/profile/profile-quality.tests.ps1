

Describe 'Profile Quality Integration Tests' {
    BeforeAll {
        try {
            $script:ProfilePath = Get-TestPath -RelativePath 'Microsoft.PowerShell_profile.ps1' -StartPath $PSScriptRoot -EnsureExists
            $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
            if ($null -eq $script:ProfilePath -or [string]::IsNullOrWhiteSpace($script:ProfilePath)) {
                throw "Get-TestPath returned null or empty value for ProfilePath"
            }
            if ($null -eq $script:ProfileDir -or [string]::IsNullOrWhiteSpace($script:ProfileDir)) {
                throw "Get-TestPath returned null or empty value for ProfileDir"
            }
            if (-not (Test-Path -LiteralPath $script:ProfilePath)) {
                throw "Profile file not found at: $script:ProfilePath"
            }
            if (-not (Test-Path -LiteralPath $script:ProfileDir)) {
                throw "Profile directory not found at: $script:ProfileDir"
            }
        }
        catch {
            $errorDetails = @{
                Message  = $_.Exception.Message
                Type     = $_.Exception.GetType().FullName
                Location = $_.InvocationInfo.ScriptLineNumber
            }
            Write-Error "Failed to initialize profile quality tests in BeforeAll: $($errorDetails | ConvertTo-Json -Compress)" -ErrorAction Stop
            throw
        }
    }

    Context 'Cross-platform compatibility' {
        It 'uses compatible path separators' {
            $profileContent = Get-Content $script:ProfilePath -Raw -ErrorAction Stop
            $hardcodedBackslashes = $profileContent | Select-String -Pattern '\\(?!\\)' -AllMatches
            $hardcodedBackslashes.Matches.Count | Should -BeLessThan 20
        }

        It 'handles missing commands gracefully' {
            { . $script:ProfilePath } | Should -Not -Throw
        }
    }

    Context 'Cross-platform PATH manipulation' {
        It 'Add-Path uses platform-appropriate separator' {
            . (Join-Path $script:ProfileDir 'utilities.ps1')

            $testPath = Join-Path $TestDrive 'test-path'
            New-Item -ItemType Directory -Path $testPath -Force | Out-Null

            $originalPath = $env:PATH
            try {
                Add-Path -Path $testPath
                $env:PATH | Should -Match ([regex]::Escape($testPath))
            }
            finally {
                $env:PATH = $originalPath
            }
        }

        It 'Remove-Path uses platform-appropriate separator' {
            . (Join-Path $script:ProfileDir 'utilities.ps1')

            $testPath = Join-Path $TestDrive 'test-remove-path'
            New-Item -ItemType Directory -Path $testPath -Force | Out-Null

            $originalPath = $env:PATH
            try {
                $pathSeparator = [System.IO.Path]::PathSeparator
                $env:PATH = "$testPath$pathSeparator$env:PATH"

                Remove-Path -Path $testPath
                $env:PATH | Should -Not -Match ([regex]::Escape($testPath))
            }
            finally {
                $env:PATH = $originalPath
            }
        }
    }

    Context 'Scoop detection' {
        It 'handles missing Scoop gracefully' {
            $testScript = @"
`$env:SCOOP = `$null
. '$($script:ProfilePath -replace "'", "''")'
Write-Output 'SCOOP_HANDLED'
"@
            $result = Invoke-TestPwshScript -ScriptContent $testScript
            $result | Should -Match 'SCOOP_HANDLED'
        }
    }
}

