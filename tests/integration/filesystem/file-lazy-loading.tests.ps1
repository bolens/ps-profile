

Describe 'File Lazy Loading Integration Tests' {
    BeforeAll {
        try {
            $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
            $script:BootstrapPath = Get-TestPath -RelativePath 'profile.d\bootstrap.ps1' -StartPath $PSScriptRoot -EnsureExists
            if ($null -eq $script:BootstrapPath -or [string]::IsNullOrWhiteSpace($script:BootstrapPath)) {
                throw "Get-TestPath returned null or empty value for BootstrapPath"
            }
            if (-not (Test-Path -LiteralPath $script:BootstrapPath)) {
                throw "Bootstrap file not found at: $script:BootstrapPath"
            }
            . $script:BootstrapPath
        }
        catch {
            $errorDetails = @{
                Message  = $_.Exception.Message
                Type     = $_.Exception.GetType().FullName
                Location = $_.InvocationInfo.ScriptLineNumber
            }
            Write-Error "Failed to load bootstrap in BeforeAll: $($errorDetails | ConvertTo-Json -Compress)" -ErrorAction Stop
            throw
        }
    }

    Context 'Lazy loading patterns' {
        It 'Ensure-FileListing initializes on first use' {
            . (Join-Path $script:ProfileDir 'files.ps1')

            $before = Test-Path Function:\Get-ChildItemDetailed
            if (-not $before) {
                $testDir = Join-Path $TestDrive 'lazy_test'
                New-Item -ItemType Directory -Path $testDir -Force | Out-Null
                Push-Location $testDir
                try {
                    # Call ll alias which should trigger lazy loading
                    if (Get-Command ll -ErrorAction SilentlyContinue) {
                        ll | Out-Null
                        $after = Test-Path Function:\Get-ChildItemDetailed
                        $after | Should -Be $true
                    }
                    else {
                        # If ll doesn't exist, try calling Ensure-FileListing directly
                        if (Get-Command Ensure-FileListing -ErrorAction SilentlyContinue) {
                            Ensure-FileListing
                            $after = Test-Path Function:\Get-ChildItemDetailed
                            $after | Should -Be $true
                        }
                    }
                }
                finally {
                    Pop-Location
                }
            }
            else {
                Set-ItResult -Skipped -Because "Get-ChildItemDetailed already exists"
            }
        }

        It 'Ensure-FileNavigation initializes on first use' {
            . (Join-Path $script:ProfileDir 'files.ps1')

            $before = Test-Path Function:\..
            if (-not $before) {
                # Call .. function which should trigger lazy loading
                if (Get-Command '..' -CommandType Function -ErrorAction SilentlyContinue) {
                    ..
                    $after = Test-Path Function:\..
                    $after | Should -Be $true
                }
                else {
                    # If .. doesn't exist, try calling Ensure-FileNavigation directly
                    if (Get-Command Ensure-FileNavigation -ErrorAction SilentlyContinue) {
                        Ensure-FileNavigation
                        $after = Test-Path Function:\..
                        $after | Should -Be $true
                    }
                }
            }
            else {
                Set-ItResult -Skipped -Because ".. function already exists"
            }
        }
    }
}

