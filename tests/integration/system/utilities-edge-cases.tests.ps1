

Describe 'System Utility Functions Edge Cases' {
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
            Write-Error "Failed to initialize system utilities edge cases tests in BeforeAll: $($errorDetails | ConvertTo-Json -Compress)" -ErrorAction Stop
            throw
        }
    }

    Context 'System utility functions edge cases' {
        BeforeAll {
            . (Join-Path $script:ProfileDir 'bootstrap.ps1')
            . (Join-Path $script:ProfileDir 'system.ps1')
        }

        It 'which handles non-existent commands' {
            $nonExistent = "NonExistentCommand_$(Get-Random)"
            $result = which $nonExistent
            ($result -eq $null -or $result.Count -eq 0) | Should -Be $true
        }

        It 'pgrep handles pattern not found' {
            $tempFile = Join-Path $TestDrive 'test_no_match.txt'
            Set-Content -Path $tempFile -Value 'no match here'
            $result = pgrep 'nonexistentpattern' $tempFile
            ($result -eq $null -or $result.Count -eq 0) | Should -Be $true
        }

        It 'touch updates existing file timestamp' {
            $tempFile = Join-Path $TestDrive 'test_touch_existing.txt'
            Set-Content -Path $tempFile -Value 'content'
            $before = (Get-Item $tempFile).LastWriteTime
            Start-Sleep -Milliseconds 1100
            touch $tempFile
            $after = (Get-Item $tempFile).LastWriteTime
            $after | Should -BeGreaterOrEqual $before
        }

        It 'search handles empty directories' {
            $emptyDir = Join-Path $TestDrive 'empty_search'
            New-Item -ItemType Directory -Path $emptyDir -Force | Out-Null

            Push-Location $emptyDir
            try {
                $result = search '*.txt'
                ($result -eq $null -or $result.Count -eq 0) | Should -Be $true
            }
            finally {
                Pop-Location
            }
        }
    }
}

