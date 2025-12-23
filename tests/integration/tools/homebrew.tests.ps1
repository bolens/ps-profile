<#
.SYNOPSIS
    Integration tests for Homebrew tool fragment.

.DESCRIPTION
    Tests Homebrew helper functions.
    These tests verify that functions are created correctly and handle
    missing tools gracefully.
#>

Describe 'Homebrew Tools Integration Tests' {
    BeforeAll {
        try {
            $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
            if ($null -eq $script:ProfileDir -or [string]::IsNullOrWhiteSpace($script:ProfileDir)) {
                throw "Get-TestPath returned null or empty value for ProfileDir"
            }
            if (-not (Test-Path -LiteralPath $script:ProfileDir)) {
                throw "Profile directory not found at: $script:ProfileDir"
            }
            
            $bootstrapPath = Join-Path $script:ProfileDir 'bootstrap.ps1'
            if ($null -eq $bootstrapPath -or [string]::IsNullOrWhiteSpace($bootstrapPath)) {
                throw "BootstrapPath is null or empty"
            }
            if (-not (Test-Path -LiteralPath $bootstrapPath)) {
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
            Write-Error "Failed to initialize Homebrew tools tests in BeforeAll: $($errorDetails | ConvertTo-Json -Compress)" -ErrorAction Stop
            throw
        }
    }

    Context 'Homebrew helpers (homebrew.ps1)' {
        BeforeAll {
            # Mock brew as available so functions are created
            Mock-CommandAvailabilityPester -CommandName 'brew' -Available $true
            . (Join-Path $script:ProfileDir 'homebrew.ps1')
        }

        It 'Creates Install-BrewPackage function' {
            Get-Command Install-BrewPackage -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates brewinstall alias for Install-BrewPackage' {
            Get-Alias brewinstall -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias brewinstall).ResolvedCommandName | Should -Be 'Install-BrewPackage'
        }

        It 'Creates brewadd alias for Install-BrewPackage' {
            Get-Alias brewadd -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias brewadd).ResolvedCommandName | Should -Be 'Install-BrewPackage'
        }

        It 'Install-BrewPackage calls brew install' {
            # Capture arguments using Pattern 6
            $script:capturedArgs = $null
            Mock -CommandName 'brew' -MockWith {
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                Write-Output 'Package installed successfully'
            }

            # Execute
            { Install-BrewPackage -Packages git -Verbose 4>&1 | Out-Null } | Should -Not -Throw

            # Verify
            Should -Invoke -CommandName 'brew' -Times 1 -Exactly
            if ($null -eq $script:capturedArgs) {
                throw "Mock was called but capturedArgs is null."
            }
            $script:capturedArgs | Should -Contain 'install'
            $script:capturedArgs | Should -Contain 'git'
        }

        It 'Install-BrewPackage supports --cask flag' {
            # Capture arguments using Pattern 6
            $script:capturedArgs = $null
            Mock -CommandName 'brew' -MockWith {
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                Write-Output 'Cask installed successfully'
            }

            # Execute
            { Install-BrewPackage -Packages visual-studio-code -Cask -Verbose 4>&1 | Out-Null } | Should -Not -Throw

            # Verify
            Should -Invoke -CommandName 'brew' -Times 1 -Exactly
            if ($null -eq $script:capturedArgs) {
                throw "Mock was called but capturedArgs is null."
            }
            $script:capturedArgs | Should -Contain 'install'
            $script:capturedArgs | Should -Contain '--cask'
            $script:capturedArgs | Should -Contain 'visual-studio-code'
        }

        It 'Creates Remove-BrewPackage function' {
            Get-Command Remove-BrewPackage -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates brewuninstall alias for Remove-BrewPackage' {
            Get-Alias brewuninstall -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias brewuninstall).ResolvedCommandName | Should -Be 'Remove-BrewPackage'
        }

        It 'Creates brewremove alias for Remove-BrewPackage' {
            Get-Alias brewremove -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias brewremove).ResolvedCommandName | Should -Be 'Remove-BrewPackage'
        }

        It 'Remove-BrewPackage calls brew uninstall' {
            # Capture arguments using Pattern 6
            $script:capturedArgs = $null
            Mock -CommandName 'brew' -MockWith {
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                Write-Output 'Package removed successfully'
            }

            # Execute
            { Remove-BrewPackage -Packages git -Verbose 4>&1 | Out-Null } | Should -Not -Throw

            # Verify
            Should -Invoke -CommandName 'brew' -Times 1 -Exactly
            if ($null -eq $script:capturedArgs) {
                throw "Mock was called but capturedArgs is null."
            }
            $script:capturedArgs | Should -Contain 'uninstall'
            $script:capturedArgs | Should -Contain 'git'
        }

        It 'Creates Test-BrewOutdated function' {
            Get-Command Test-BrewOutdated -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates brewoutdated alias for Test-BrewOutdated' {
            Get-Alias brewoutdated -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias brewoutdated).ResolvedCommandName | Should -Be 'Test-BrewOutdated'
        }

        It 'Test-BrewOutdated calls brew outdated' {
            # Capture arguments using Pattern 6
            $script:capturedArgs = $null
            Mock -CommandName 'brew' -MockWith {
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                Write-Output 'package1 (1.0.0 < 1.2.0)'
            }

            # Execute
            { Test-BrewOutdated -Verbose 4>&1 | Out-Null } | Should -Not -Throw

            # Verify
            Should -Invoke -CommandName 'brew' -Times 1 -Exactly
            if ($null -eq $script:capturedArgs) {
                throw "Mock was called but capturedArgs is null."
            }
            $script:capturedArgs | Should -Contain 'outdated'
        }

        It 'Creates Update-BrewPackages function' {
            Get-Command Update-BrewPackages -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates brewupgrade alias for Update-BrewPackages' {
            Get-Alias brewupgrade -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias brewupgrade).ResolvedCommandName | Should -Be 'Update-BrewPackages'
        }

        It 'Update-BrewPackages calls brew upgrade for all packages' {
            # Capture arguments using Pattern 6
            $script:capturedArgs = $null
            Mock -CommandName 'brew' -MockWith {
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                Write-Output 'All packages upgraded successfully'
            }

            # Execute
            { Update-BrewPackages -Verbose 4>&1 | Out-Null } | Should -Not -Throw

            # Verify
            Should -Invoke -CommandName 'brew' -Times 1 -Exactly
            if ($null -eq $script:capturedArgs) {
                throw "Mock was called but capturedArgs is null."
            }
            $script:capturedArgs | Should -Contain 'upgrade'
            # When no packages specified, only 'upgrade' should be in arguments
            $script:capturedArgs.Count | Should -Be 1
        }

        It 'Update-BrewPackages calls brew upgrade for specific packages' {
            # Capture arguments using Pattern 6
            $script:capturedArgs = $null
            Mock -CommandName 'brew' -MockWith {
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                Write-Output 'git upgraded successfully'
            }

            # Execute
            { Update-BrewPackages -Packages git -Verbose 4>&1 | Out-Null } | Should -Not -Throw

            # Verify
            Should -Invoke -CommandName 'brew' -Times 1 -Exactly
            if ($null -eq $script:capturedArgs) {
                throw "Mock was called but capturedArgs is null."
            }
            $script:capturedArgs | Should -Contain 'upgrade'
            $script:capturedArgs | Should -Contain 'git'
        }

        It 'Creates Update-BrewSelf function' {
            Get-Command Update-BrewSelf -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates brewselfupdate alias for Update-BrewSelf' {
            Get-Alias brewselfupdate -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias brewselfupdate).ResolvedCommandName | Should -Be 'Update-BrewSelf'
        }

        It 'Update-BrewSelf calls brew update' {
            # Capture arguments using Pattern 6
            $script:capturedArgs = $null
            Mock -CommandName 'brew' -MockWith {
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                Write-Output 'Homebrew updated successfully'
            }

            # Execute
            { Update-BrewSelf -Verbose 4>&1 | Out-Null } | Should -Not -Throw

            # Verify
            Should -Invoke -CommandName 'brew' -Times 1 -Exactly
            if ($null -eq $script:capturedArgs) {
                throw "Mock was called but capturedArgs is null."
            }
            $script:capturedArgs | Should -Contain 'update'
        }

        It 'Creates Clear-BrewCache function' {
            Get-Command Clear-BrewCache -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates brewcleanup alias for Clear-BrewCache' {
            Get-Alias brewcleanup -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias brewcleanup).ResolvedCommandName | Should -Be 'Clear-BrewCache'
        }

        It 'Creates brewclean alias for Clear-BrewCache' {
            Get-Alias brewclean -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias brewclean).ResolvedCommandName | Should -Be 'Clear-BrewCache'
        }

        It 'Clear-BrewCache calls brew cleanup' {
            $script:capturedArgs = $null
            Mock -CommandName 'brew' -MockWith {
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                Write-Output 'Cleanup completed successfully'
            }

            # Execute
            { Clear-BrewCache -Verbose 4>&1 | Out-Null } | Should -Not -Throw

            # Verify
            Should -Invoke -CommandName 'brew' -Times 1 -Exactly
            if ($null -eq $script:capturedArgs) {
                throw "Mock was called but capturedArgs is null."
            }
            $script:capturedArgs | Should -Contain 'cleanup'
        }

        It 'Clear-BrewCache with Formula calls brew cleanup with formula' {
            $script:capturedArgs = $null
            Mock -CommandName 'brew' -MockWith {
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                Write-Output 'Formula cleaned successfully'
            }

            # Execute
            { Clear-BrewCache -Formula git -Verbose 4>&1 | Out-Null } | Should -Not -Throw

            # Verify
            Should -Invoke -CommandName 'brew' -Times 1 -Exactly
            if ($null -eq $script:capturedArgs) {
                throw "Mock was called but capturedArgs is null."
            }
            $script:capturedArgs | Should -Contain 'cleanup'
            $script:capturedArgs | Should -Contain 'git'
        }

        It 'Clear-BrewCache with Scrub passes -s flag' {
            $script:capturedArgs = $null
            Mock -CommandName 'brew' -MockWith {
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                Write-Output 'Cache scrubbed successfully'
            }

            # Execute
            { Clear-BrewCache -Scrub -Verbose 4>&1 | Out-Null } | Should -Not -Throw

            # Verify
            Should -Invoke -CommandName 'brew' -Times 1 -Exactly
            if ($null -eq $script:capturedArgs) {
                throw "Mock was called but capturedArgs is null."
            }
            $script:capturedArgs | Should -Contain 'cleanup'
            $script:capturedArgs | Should -Contain '-s'
        }

        It 'Clear-BrewCache with DryRun passes -n flag' {
            $script:capturedArgs = $null
            Mock -CommandName 'brew' -MockWith {
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                Write-Output 'Dry run completed'
            }

            # Execute
            { Clear-BrewCache -DryRun -Verbose 4>&1 | Out-Null } | Should -Not -Throw

            # Verify
            Should -Invoke -CommandName 'brew' -Times 1 -Exactly
            if ($null -eq $script:capturedArgs) {
                throw "Mock was called but capturedArgs is null."
            }
            $script:capturedArgs | Should -Contain 'cleanup'
            $script:capturedArgs | Should -Contain '-n'
        }

        It 'Clear-BrewCache with Prune passes --prune flag' {
            $script:capturedArgs = $null
            Mock -CommandName 'brew' -MockWith {
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                Write-Output 'Pruned cache successfully'
            }

            # Execute
            { Clear-BrewCache -Prune 30 -Verbose 4>&1 | Out-Null } | Should -Not -Throw

            # Verify
            Should -Invoke -CommandName 'brew' -Times 1 -Exactly
            if ($null -eq $script:capturedArgs) {
                throw "Mock was called but capturedArgs is null."
            }
            $script:capturedArgs | Should -Contain 'cleanup'
            $script:capturedArgs | Should -Contain '--prune=30'
        }

        It 'Creates Find-BrewPackage function' {
            Get-Command Find-BrewPackage -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates brewsearch alias for Find-BrewPackage' {
            Get-Alias brewsearch -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias brewsearch).ResolvedCommandName | Should -Be 'Find-BrewPackage'
        }

        It 'Creates brewfind alias for Find-BrewPackage' {
            Get-Alias brewfind -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias brewfind).ResolvedCommandName | Should -Be 'Find-BrewPackage'
        }

        It 'Find-BrewPackage calls brew search' {
            $script:capturedArgs = $null
            Mock -CommandName 'brew' -MockWith {
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                Write-Output 'git'
            }

            # Execute
            { Find-BrewPackage -Query git -Verbose 4>&1 | Out-Null } | Should -Not -Throw

            # Verify
            Should -Invoke -CommandName 'brew' -Times 1 -Exactly
            if ($null -eq $script:capturedArgs) {
                throw "Mock was called but capturedArgs is null."
            }
            $script:capturedArgs | Should -Contain 'search'
            $script:capturedArgs | Should -Contain 'git'
        }

        It 'Find-BrewPackage with Cask passes --cask flag' {
            $script:capturedArgs = $null
            Mock -CommandName 'brew' -MockWith {
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                Write-Output 'visual-studio-code'
            }

            # Execute
            { Find-BrewPackage -Query visual-studio-code -Cask -Verbose 4>&1 | Out-Null } | Should -Not -Throw

            # Verify
            Should -Invoke -CommandName 'brew' -Times 1 -Exactly
            if ($null -eq $script:capturedArgs) {
                throw "Mock was called but capturedArgs is null."
            }
            $script:capturedArgs | Should -Contain 'search'
            $script:capturedArgs | Should -Contain '--cask'
            $script:capturedArgs | Should -Contain 'visual-studio-code'
        }

        It 'Creates Get-BrewPackage function' {
            Get-Command Get-BrewPackage -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates brewlist alias for Get-BrewPackage' {
            Get-Alias brewlist -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias brewlist).ResolvedCommandName | Should -Be 'Get-BrewPackage'
        }

        It 'Get-BrewPackage calls brew list' {
            $script:capturedArgs = $null
            Mock -CommandName 'brew' -MockWith {
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                Write-Output 'git'
            }

            # Execute
            { Get-BrewPackage -Verbose 4>&1 | Out-Null } | Should -Not -Throw

            # Verify
            Should -Invoke -CommandName 'brew' -Times 1 -Exactly
            if ($null -eq $script:capturedArgs) {
                throw "Mock was called but capturedArgs is null."
            }
            $script:capturedArgs | Should -Contain 'list'
        }

        It 'Get-BrewPackage with Cask passes --cask flag' {
            $script:capturedArgs = $null
            Mock -CommandName 'brew' -MockWith {
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                Write-Output 'visual-studio-code'
            }

            # Execute
            { Get-BrewPackage -Cask -Verbose 4>&1 | Out-Null } | Should -Not -Throw

            # Verify
            Should -Invoke -CommandName 'brew' -Times 1 -Exactly
            if ($null -eq $script:capturedArgs) {
                throw "Mock was called but capturedArgs is null."
            }
            $script:capturedArgs | Should -Contain 'list'
            $script:capturedArgs | Should -Contain '--cask'
        }

        It 'Get-BrewPackage with Versions passes --versions flag' {
            $script:capturedArgs = $null
            Mock -CommandName 'brew' -MockWith {
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                Write-Output 'git 2.40.0'
            }

            # Execute
            { Get-BrewPackage -Versions -Verbose 4>&1 | Out-Null } | Should -Not -Throw

            # Verify
            Should -Invoke -CommandName 'brew' -Times 1 -Exactly
            if ($null -eq $script:capturedArgs) {
                throw "Mock was called but capturedArgs is null."
            }
            $script:capturedArgs | Should -Contain 'list'
            $script:capturedArgs | Should -Contain '--versions'
        }

        It 'Creates Get-BrewPackageInfo function' {
            Get-Command Get-BrewPackageInfo -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates brewinfo alias for Get-BrewPackageInfo' {
            Get-Alias brewinfo -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias brewinfo).ResolvedCommandName | Should -Be 'Get-BrewPackageInfo'
        }

        It 'Get-BrewPackageInfo calls brew info' {
            $script:capturedArgs = $null
            Mock -CommandName 'brew' -MockWith {
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                Write-Output 'git: stable 2.40.0'
            }

            # Execute
            { Get-BrewPackageInfo -Packages git -Verbose 4>&1 | Out-Null } | Should -Not -Throw

            # Verify
            Should -Invoke -CommandName 'brew' -Times 1 -Exactly
            if ($null -eq $script:capturedArgs) {
                throw "Mock was called but capturedArgs is null."
            }
            $script:capturedArgs | Should -Contain 'info'
            $script:capturedArgs | Should -Contain 'git'
        }

        It 'Get-BrewPackageInfo with Cask passes --cask flag' {
            $script:capturedArgs = $null
            Mock -CommandName 'brew' -MockWith {
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                Write-Output 'visual-studio-code: 1.80.0'
            }

            # Execute
            { Get-BrewPackageInfo -Packages visual-studio-code -Cask -Verbose 4>&1 | Out-Null } | Should -Not -Throw

            # Verify
            Should -Invoke -CommandName 'brew' -Times 1 -Exactly
            if ($null -eq $script:capturedArgs) {
                throw "Mock was called but capturedArgs is null."
            }
            $script:capturedArgs | Should -Contain 'info'
            $script:capturedArgs | Should -Contain '--cask'
            $script:capturedArgs | Should -Contain 'visual-studio-code'
        }

        It 'Creates Export-BrewPackages function' {
            Get-Command Export-BrewPackages -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates brewexport alias for Export-BrewPackages' {
            Get-Alias brewexport -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias brewexport).ResolvedCommandName | Should -Be 'Export-BrewPackages'
        }

        It 'Creates brewbackup alias for Export-BrewPackages' {
            Get-Alias brewbackup -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias brewbackup).ResolvedCommandName | Should -Be 'Export-BrewPackages'
        }

        It 'Export-BrewPackages calls brew bundle dump' {
            $script:capturedArgs = $null
            Mock -CommandName 'brew' -MockWith {
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                Write-Output 'Brewfile created successfully'
            }

            # Execute
            { Export-BrewPackages -Path 'test-Brewfile' -Verbose 4>&1 | Out-Null } | Should -Not -Throw

            # Verify
            Should -Invoke -CommandName 'brew' -Times 1 -Exactly
            if ($null -eq $script:capturedArgs) {
                throw "Mock was called but capturedArgs is null."
            }
            $script:capturedArgs | Should -Contain 'bundle'
            $script:capturedArgs | Should -Contain 'dump'
            $script:capturedArgs | Should -Contain '--file'
            $script:capturedArgs | Should -Contain 'test-Brewfile'
        }

        It 'Export-BrewPackages with Describe passes --describe flag' {
            $script:capturedArgs = $null
            Mock -CommandName 'brew' -MockWith {
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                Write-Output 'Brewfile created with descriptions'
            }

            # Execute
            { Export-BrewPackages -Path 'test-Brewfile' -Describe -Verbose 4>&1 | Out-Null } | Should -Not -Throw

            # Verify
            Should -Invoke -CommandName 'brew' -Times 1 -Exactly
            if ($null -eq $script:capturedArgs) {
                throw "Mock was called but capturedArgs is null."
            }
            $script:capturedArgs | Should -Contain 'bundle'
            $script:capturedArgs | Should -Contain 'dump'
            $script:capturedArgs | Should -Contain '--describe'
        }

        It 'Export-BrewPackages with Force passes --force flag' {
            $script:capturedArgs = $null
            Mock -CommandName 'brew' -MockWith {
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                Write-Output 'Brewfile overwritten'
            }

            # Execute
            { Export-BrewPackages -Path 'test-Brewfile' -Force -Verbose 4>&1 | Out-Null } | Should -Not -Throw

            # Verify
            Should -Invoke -CommandName 'brew' -Times 1 -Exactly
            if ($null -eq $script:capturedArgs) {
                throw "Mock was called but capturedArgs is null."
            }
            $script:capturedArgs | Should -Contain 'bundle'
            $script:capturedArgs | Should -Contain 'dump'
            $script:capturedArgs | Should -Contain '--force'
        }

        It 'Creates Import-BrewPackages function' {
            Get-Command Import-BrewPackages -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates brewimport alias for Import-BrewPackages' {
            Get-Alias brewimport -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias brewimport).ResolvedCommandName | Should -Be 'Import-BrewPackages'
        }

        It 'Creates brewrestore alias for Import-BrewPackages' {
            Get-Alias brewrestore -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias brewrestore).ResolvedCommandName | Should -Be 'Import-BrewPackages'
        }

        It 'Import-BrewPackages calls brew bundle' {
            $script:capturedArgs = $null
            $testFile = 'test-Brewfile'
            'brew "git"' | Out-File -FilePath $testFile -ErrorAction SilentlyContinue
            
            Mock -CommandName 'brew' -MockWith {
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                Write-Output 'Packages imported successfully'
            }

            # Execute
            { Import-BrewPackages -Path $testFile -Verbose 4>&1 | Out-Null } | Should -Not -Throw

            # Verify
            Should -Invoke -CommandName 'brew' -Times 1 -Exactly
            if ($null -eq $script:capturedArgs) {
                throw "Mock was called but capturedArgs is null."
            }
            $script:capturedArgs | Should -Contain 'bundle'
            $script:capturedArgs | Should -Contain '--file'
            $script:capturedArgs | Should -Contain $testFile

            # Cleanup
            Remove-Item -Path $testFile -ErrorAction SilentlyContinue
        }

        It 'Import-BrewPackages with NoLock passes --no-lock flag' {
            $script:capturedArgs = $null
            $testFile = 'test-Brewfile'
            'brew "git"' | Out-File -FilePath $testFile -ErrorAction SilentlyContinue
            
            Mock -CommandName 'brew' -MockWith {
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                Write-Output 'Packages imported'
            }

            # Execute
            { Import-BrewPackages -Path $testFile -NoLock -Verbose 4>&1 | Out-Null } | Should -Not -Throw

            # Verify
            Should -Invoke -CommandName 'brew' -Times 1 -Exactly
            if ($null -eq $script:capturedArgs) {
                throw "Mock was called but capturedArgs is null."
            }
            $script:capturedArgs | Should -Contain 'bundle'
            $script:capturedArgs | Should -Contain '--no-lock'

            # Cleanup
            Remove-Item -Path $testFile -ErrorAction SilentlyContinue
        }

        It 'Homebrew fragment handles missing tool gracefully' {
            BeforeAll {
                if ($global:MissingToolWarnings) {
                    $null = $global:MissingToolWarnings.TryRemove('brew', [ref]$null)
                }
                if ($null -ne $global:TestCachedCommandCache) {
                    $global:TestCachedCommandCache = @{}
                }
                if ($null -ne $global:AssumedAvailableCommands) {
                    $null = $global:AssumedAvailableCommands.TryRemove('brew', [ref]$null)
                    $null = $global:AssumedAvailableCommands.TryRemove('brew'.ToLowerInvariant(), [ref]$null)
                }
                
                # Clear any function mocks that might exist
                Remove-Item Function:brew -ErrorAction SilentlyContinue
                Remove-Item Function:global:brew -ErrorAction SilentlyContinue
                
                # Mock brew as unavailable BEFORE loading the fragment
                Mock-CommandAvailabilityPester -CommandName 'brew' -Available $false
                
                # Remove any existing Homebrew functions
                Remove-Item Function:Install-BrewPackage -ErrorAction SilentlyContinue
                Remove-Item Function:Remove-BrewPackage -ErrorAction SilentlyContinue
                Remove-Item Function:Update-BrewPackages -ErrorAction SilentlyContinue
                Remove-Item Function:Test-BrewOutdated -ErrorAction SilentlyContinue
                Remove-Item Function:Update-BrewSelf -ErrorAction SilentlyContinue
                Remove-Item Function:Clear-BrewCache -ErrorAction SilentlyContinue
                Remove-Item Function:Find-BrewPackage -ErrorAction SilentlyContinue
                Remove-Item Function:Get-BrewPackage -ErrorAction SilentlyContinue
                Remove-Item Function:Get-BrewPackageInfo -ErrorAction SilentlyContinue
                Remove-Item Function:Export-BrewPackages -ErrorAction SilentlyContinue
                Remove-Item Function:Import-BrewPackages -ErrorAction SilentlyContinue
                
                # Reload the fragment - functions should not be created since brew is unavailable
                . (Join-Path $script:ProfileDir 'homebrew.ps1')
            }

            It 'Functions are not created when brew is unavailable' {
                # Verify functions were not created
                Get-Command Install-BrewPackage -ErrorAction SilentlyContinue | Should -BeNullOrEmpty
            }
        }
    }
}
