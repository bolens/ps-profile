

Describe 'File Navigation Functions Integration Tests' {
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

    Context 'File navigation functions' {
        BeforeAll {
            . (Join-Path $script:ProfileDir 'bootstrap.ps1')
            . (Join-Path $script:ProfileDir 'files.ps1')
            # Ensure file navigation module is loaded
            $filesModulesDir = Join-Path $script:ProfileDir 'files-modules'
            $navigationDir = Join-Path $filesModulesDir 'navigation'
            $navigationModule = Join-Path $navigationDir 'files-navigation.ps1'
            if ($navigationModule -and -not [string]::IsNullOrWhiteSpace($navigationModule) -and (Test-Path -LiteralPath $navigationModule)) {
                . $navigationModule
            }
            Ensure-FileNavigation
        }

        It '.. function navigates up one directory' {
            $testDir = $null
            $originalLocation = Get-Location
            
            try {
                $testDir = Join-Path $TestDrive 'level1\level2'
                New-Item -ItemType Directory -Path $testDir -Force | Out-Null

                Push-Location $testDir
                try {
                    $before = Get-Location
                    if (-not (Get-Command '..' -CommandType Function -ErrorAction SilentlyContinue)) {
                        Set-ItResult -Skipped -Because ".. function not available"
                        return
                    }
                    
                    ..
                    $after = Get-Location
                    $after.Path | Should -Match ([regex]::Escape((Split-Path $before.Path))) -Because ".. should navigate up one directory"
                }
                catch {
                    $errorDetails = @{
                        Message  = $_.Exception.Message
                        TestDir  = $testDir
                        Category = $_.CategoryInfo.Category
                    }
                    Write-Error ".. function navigation test failed: $($errorDetails | ConvertTo-Json -Compress)" -ErrorAction Continue
                    throw
                }
                finally {
                    Pop-Location
                }
            }
            catch {
                Set-Location $originalLocation -ErrorAction SilentlyContinue
                throw
            }
        }

        It '... function navigates up two directories' {
            $testDir = Join-Path $TestDrive 'level1\level2\level3'
            New-Item -ItemType Directory -Path $testDir -Force | Out-Null

            Push-Location $testDir
            try {
                $before = Get-Location
                ...
                $after = Get-Location
                $beforeParent = Split-Path (Split-Path $before.Path)
                $after.Path | Should -Match ([regex]::Escape($beforeParent))
            }
            finally {
                Pop-Location
            }
        }

        It '.... function navigates up three directories' {
            $testDir = Join-Path $TestDrive 'level1\level2\level3\level4'
            New-Item -ItemType Directory -Path $testDir -Force | Out-Null

            Push-Location $testDir
            try {
                $before = Get-Location
                ....
                $after = Get-Location
                $beforeParent = Split-Path (Split-Path (Split-Path $before.Path))
                $after.Path | Should -Match ([regex]::Escape($beforeParent))
            }
            finally {
                Pop-Location
            }
        }

        It '~ function navigates to home directory' {
            $originalLocation = Get-Location
            try {
                ~
                $homeLocation = Get-Location
                $homeLocation.Path | Should -Match ([regex]::Escape($env:USERPROFILE))
            }
            finally {
                Set-Location $originalLocation
            }
        }

        It 'desktop alias navigates to Desktop' {
            if (Test-Path "$env:USERPROFILE\Desktop") {
                $originalLocation = Get-Location
                try {
                    desktop
                    $desktop = Get-Location
                    $desktop.Path | Should -Match ([regex]::Escape("$env:USERPROFILE\Desktop"))
                }
                finally {
                    Set-Location $originalLocation
                }
            }
        }

        It 'downloads alias navigates to Downloads' {
            if (Test-Path "$env:USERPROFILE\Downloads") {
                $originalLocation = Get-Location
                try {
                    downloads
                    $downloads = Get-Location
                    $downloads.Path | Should -Match ([regex]::Escape("$env:USERPROFILE\Downloads"))
                }
                finally {
                    Set-Location $originalLocation
                }
            }
        }

        It 'docs alias navigates to Documents' {
            if (Test-Path "$env:USERPROFILE\Documents") {
                $originalLocation = Get-Location
                try {
                    docs
                    $docs = Get-Location
                    $docs.Path | Should -Match ([regex]::Escape("$env:USERPROFILE\Documents"))
                }
                finally {
                    Set-Location $originalLocation
                }
            }
        }
    }
}

