<#
.SYNOPSIS
    Integration tests for winget tool fragment.

.DESCRIPTION
    Tests winget helper functions.
    These tests verify that functions are created correctly and handle
    missing tools gracefully.
#>

Describe 'winget Tools Integration Tests' {
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
            Write-Error "Failed to initialize winget tools tests in BeforeAll: $($errorDetails | ConvertTo-Json -Compress)" -ErrorAction Stop
            throw
        }
    }

    Context 'winget helpers (winget.ps1)' {
        BeforeAll {
            # Mock winget as available so functions are created
            Mock-CommandAvailabilityPester -CommandName 'winget' -Available $true
            . (Join-Path $script:ProfileDir 'winget.ps1')
        }

        It 'Creates Test-WingetOutdated function' {
            Get-Command Test-WingetOutdated -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates winget-outdated alias for Test-WingetOutdated' {
            Get-Alias winget-outdated -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias winget-outdated).ResolvedCommandName | Should -Be 'Test-WingetOutdated'
        }

        It 'Test-WingetOutdated calls winget upgrade' {
            Mock -CommandName winget -MockWith {
                param([string[]]$ArgumentList)
                $args = $ArgumentList
                if ($args -contains 'upgrade' -and $args.Count -eq 1) {
                    Write-Output 'Name    Id    Version    Available'
                    Write-Output 'App1    app1  1.0.0      1.2.0'
                }
            }

            { Test-WingetOutdated -Verbose 4>&1 | Out-Null } | Should -Not -Throw
            Get-Command Test-WingetOutdated -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates Update-WingetPackages function' {
            Get-Command Update-WingetPackages -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates winget-update alias for Update-WingetPackages' {
            Get-Alias winget-update -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias winget-update).ResolvedCommandName | Should -Be 'Update-WingetPackages'
        }

        It 'Update-WingetPackages calls winget upgrade --all' {
            $script:capturedArgs = $null
            Mock -CommandName winget -MockWith {
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                Write-Output 'All packages updated successfully'
            }

            # Execute
            { Update-WingetPackages -Verbose 4>&1 | Out-Null } | Should -Not -Throw

            # Verify
            Should -Invoke -CommandName 'winget' -Times 1 -Exactly
            if ($null -eq $script:capturedArgs) {
                throw "Mock was called but capturedArgs is null."
            }
            $script:capturedArgs | Should -Contain 'upgrade'
            $script:capturedArgs | Should -Contain '--all'
            Get-Command Update-WingetPackages -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates Clear-WingetCache function' {
            Get-Command Clear-WingetCache -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates winget-cleanup alias for Clear-WingetCache' {
            Get-Alias winget-cleanup -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias winget-cleanup).ResolvedCommandName | Should -Be 'Clear-WingetCache'
        }

        It 'Creates winget-clean alias for Clear-WingetCache' {
            Get-Alias winget-clean -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias winget-clean).ResolvedCommandName | Should -Be 'Clear-WingetCache'
        }

        It 'Clear-WingetCache calls winget cache clean' {
            $script:capturedArgs = $null
            Mock -CommandName winget -MockWith {
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                Write-Output 'Cache cleaned successfully'
            }

            # Execute
            { Clear-WingetCache -Verbose 4>&1 | Out-Null } | Should -Not -Throw

            # Verify
            Should -Invoke -CommandName 'winget' -Times 1 -Exactly
            if ($null -eq $script:capturedArgs) {
                throw "Mock was called but capturedArgs is null."
            }
            $script:capturedArgs | Should -Contain 'cache'
            $script:capturedArgs | Should -Contain 'clean'
        }

        It 'Creates Install-WingetPackage function' {
            Get-Command Install-WingetPackage -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates winget-install alias for Install-WingetPackage' {
            Get-Alias winget-install -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias winget-install).ResolvedCommandName | Should -Be 'Install-WingetPackage'
        }

        It 'Creates winget-add alias for Install-WingetPackage' {
            Get-Alias winget-add -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias winget-add).ResolvedCommandName | Should -Be 'Install-WingetPackage'
        }

        It 'Install-WingetPackage calls winget install' {
            $script:capturedArgs = $null
            Mock -CommandName winget -MockWith {
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                Write-Output 'Package installed successfully'
            }

            # Execute
            { Install-WingetPackage -Packages Git.Git -Verbose 4>&1 | Out-Null } | Should -Not -Throw

            # Verify
            Should -Invoke -CommandName 'winget' -Times 1 -Exactly
            if ($null -eq $script:capturedArgs) {
                throw "Mock was called but capturedArgs is null."
            }
            $script:capturedArgs | Should -Contain 'install'
            $script:capturedArgs | Should -Contain 'Git.Git'
            $script:capturedArgs | Should -Contain '--accept-package-agreements'
            $script:capturedArgs | Should -Contain '--accept-source-agreements'
        }

        It 'Install-WingetPackage with Version passes --version flag' {
            $script:capturedArgs = $null
            Mock -CommandName winget -MockWith {
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                Write-Output 'Package installed successfully'
            }

            # Execute
            { Install-WingetPackage -Packages Git.Git -Version 2.40.0 -Verbose 4>&1 | Out-Null } | Should -Not -Throw

            # Verify
            Should -Invoke -CommandName 'winget' -Times 1 -Exactly
            if ($null -eq $script:capturedArgs) {
                throw "Mock was called but capturedArgs is null."
            }
            $script:capturedArgs | Should -Contain 'install'
            $script:capturedArgs | Should -Contain '--version'
            $script:capturedArgs | Should -Contain '2.40.0'
        }

        It 'Creates Remove-WingetPackage function' {
            Get-Command Remove-WingetPackage -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates winget-uninstall alias for Remove-WingetPackage' {
            Get-Alias winget-uninstall -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias winget-uninstall).ResolvedCommandName | Should -Be 'Remove-WingetPackage'
        }

        It 'Creates winget-remove alias for Remove-WingetPackage' {
            Get-Alias winget-remove -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias winget-remove).ResolvedCommandName | Should -Be 'Remove-WingetPackage'
        }

        It 'Remove-WingetPackage calls winget uninstall' {
            $script:capturedArgs = $null
            Mock -CommandName winget -MockWith {
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                Write-Output 'Package removed successfully'
            }

            # Execute
            { Remove-WingetPackage -Packages Git.Git -Verbose 4>&1 | Out-Null } | Should -Not -Throw

            # Verify
            Should -Invoke -CommandName 'winget' -Times 1 -Exactly
            if ($null -eq $script:capturedArgs) {
                throw "Mock was called but capturedArgs is null."
            }
            $script:capturedArgs | Should -Contain 'uninstall'
            $script:capturedArgs | Should -Contain 'Git.Git'
            $script:capturedArgs | Should -Contain '--accept-source-agreements'
        }

        It 'Creates Find-WingetPackage function' {
            Get-Command Find-WingetPackage -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates winget-search alias for Find-WingetPackage' {
            Get-Alias winget-search -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias winget-search).ResolvedCommandName | Should -Be 'Find-WingetPackage'
        }

        It 'Creates winget-find alias for Find-WingetPackage' {
            Get-Alias winget-find -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias winget-find).ResolvedCommandName | Should -Be 'Find-WingetPackage'
        }

        It 'Find-WingetPackage calls winget search' {
            $script:capturedArgs = $null
            Mock -CommandName winget -MockWith {
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                Write-Output 'Name    Id    Version'
                Write-Output 'Git     Git.Git    2.40.0'
            }

            # Execute
            { Find-WingetPackage -Query git -Verbose 4>&1 | Out-Null } | Should -Not -Throw

            # Verify
            Should -Invoke -CommandName 'winget' -Times 1 -Exactly
            if ($null -eq $script:capturedArgs) {
                throw "Mock was called but capturedArgs is null."
            }
            $script:capturedArgs | Should -Contain 'search'
            $script:capturedArgs | Should -Contain 'git'
        }

        It 'Find-WingetPackage with Exact passes --exact flag' {
            $script:capturedArgs = $null
            Mock -CommandName winget -MockWith {
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                Write-Output 'Name    Id    Version'
                Write-Output 'Git     Git.Git    2.40.0'
            }

            # Execute
            { Find-WingetPackage -Query Git.Git -Exact -Verbose 4>&1 | Out-Null } | Should -Not -Throw

            # Verify
            Should -Invoke -CommandName 'winget' -Times 1 -Exactly
            if ($null -eq $script:capturedArgs) {
                throw "Mock was called but capturedArgs is null."
            }
            $script:capturedArgs | Should -Contain 'search'
            $script:capturedArgs | Should -Contain '--exact'
            $script:capturedArgs | Should -Contain 'Git.Git'
        }

        It 'Creates Get-WingetPackage function' {
            Get-Command Get-WingetPackage -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates winget-list alias for Get-WingetPackage' {
            Get-Alias winget-list -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias winget-list).ResolvedCommandName | Should -Be 'Get-WingetPackage'
        }

        It 'Get-WingetPackage calls winget list' {
            $script:capturedArgs = $null
            Mock -CommandName winget -MockWith {
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                Write-Output 'Name    Id    Version'
                Write-Output 'Git     Git.Git    2.40.0'
            }

            # Execute
            { Get-WingetPackage -Verbose 4>&1 | Out-Null } | Should -Not -Throw

            # Verify
            Should -Invoke -CommandName 'winget' -Times 1 -Exactly
            if ($null -eq $script:capturedArgs) {
                throw "Mock was called but capturedArgs is null."
            }
            $script:capturedArgs | Should -Contain 'list'
        }

        It 'Creates Get-WingetPackageInfo function' {
            Get-Command Get-WingetPackageInfo -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates winget-show alias for Get-WingetPackageInfo' {
            Get-Alias winget-show -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias winget-show).ResolvedCommandName | Should -Be 'Get-WingetPackageInfo'
        }

        It 'Creates winget-info alias for Get-WingetPackageInfo' {
            Get-Alias winget-info -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias winget-info).ResolvedCommandName | Should -Be 'Get-WingetPackageInfo'
        }

        It 'Get-WingetPackageInfo calls winget show' {
            $script:capturedArgs = $null
            Mock -CommandName winget -MockWith {
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                Write-Output 'Found Git [Git.Git]'
                Write-Output 'Version: 2.40.0'
            }

            # Execute
            { Get-WingetPackageInfo -Packages Git.Git -Verbose 4>&1 | Out-Null } | Should -Not -Throw

            # Verify
            Should -Invoke -CommandName 'winget' -Times 1 -Exactly
            if ($null -eq $script:capturedArgs) {
                throw "Mock was called but capturedArgs is null."
            }
            $script:capturedArgs | Should -Contain 'show'
            $script:capturedArgs | Should -Contain 'Git.Git'
        }

        It 'Get-WingetPackageInfo with Version passes --version flag' {
            $script:capturedArgs = $null
            Mock -CommandName winget -MockWith {
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                Write-Output 'Found Git [Git.Git]'
                Write-Output 'Version: 2.40.0'
            }

            # Execute
            { Get-WingetPackageInfo -Packages Git.Git -Version 2.40.0 -Verbose 4>&1 | Out-Null } | Should -Not -Throw

            # Verify
            Should -Invoke -CommandName 'winget' -Times 1 -Exactly
            if ($null -eq $script:capturedArgs) {
                throw "Mock was called but capturedArgs is null."
            }
            $script:capturedArgs | Should -Contain 'show'
            $script:capturedArgs | Should -Contain '--version'
            $script:capturedArgs | Should -Contain '2.40.0'
        }

        It 'Creates Export-WingetPackages function' {
            Get-Command Export-WingetPackages -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates winget-export alias for Export-WingetPackages' {
            Get-Alias winget-export -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias winget-export).ResolvedCommandName | Should -Be 'Export-WingetPackages'
        }

        It 'Creates winget-backup alias for Export-WingetPackages' {
            Get-Alias winget-backup -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias winget-backup).ResolvedCommandName | Should -Be 'Export-WingetPackages'
        }

        It 'Export-WingetPackages calls winget export' {
            $script:capturedArgs = $null
            Mock -CommandName winget -MockWith {
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                Write-Output 'Packages exported successfully'
            }

            # Execute
            { Export-WingetPackages -Path 'test-winget-packages.json' -Verbose 4>&1 | Out-Null } | Should -Not -Throw

            # Verify
            Should -Invoke -CommandName 'winget' -Times 1 -Exactly
            if ($null -eq $script:capturedArgs) {
                throw "Mock was called but capturedArgs is null."
            }
            $script:capturedArgs | Should -Contain 'export'
            $script:capturedArgs | Should -Contain '-o'
            $script:capturedArgs | Should -Contain 'test-winget-packages.json'
        }

        It 'Export-WingetPackages with Source passes --source flag' {
            $script:capturedArgs = $null
            Mock -CommandName winget -MockWith {
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                Write-Output 'Packages exported from source'
            }

            # Execute
            { Export-WingetPackages -Path 'test-winget-packages.json' -Source winget -Verbose 4>&1 | Out-Null } | Should -Not -Throw

            # Verify
            Should -Invoke -CommandName 'winget' -Times 1 -Exactly
            if ($null -eq $script:capturedArgs) {
                throw "Mock was called but capturedArgs is null."
            }
            $script:capturedArgs | Should -Contain 'export'
            $script:capturedArgs | Should -Contain '--source'
            $script:capturedArgs | Should -Contain 'winget'
        }

        It 'Creates Import-WingetPackages function' {
            Get-Command Import-WingetPackages -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates winget-import alias for Import-WingetPackages' {
            Get-Alias winget-import -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias winget-import).ResolvedCommandName | Should -Be 'Import-WingetPackages'
        }

        It 'Creates winget-restore alias for Import-WingetPackages' {
            Get-Alias winget-restore -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias winget-restore).ResolvedCommandName | Should -Be 'Import-WingetPackages'
        }

        It 'Import-WingetPackages calls winget import' {
            $script:capturedArgs = $null
            $testFile = 'test-winget-packages.json'
            '{"Sources":[],"Packages":[{"PackageIdentifier":"Git.Git","Version":"2.40.0"}]}' | Out-File -FilePath $testFile -ErrorAction SilentlyContinue
            
            Mock -CommandName winget -MockWith {
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                Write-Output 'Packages imported successfully'
            }

            # Execute
            { Import-WingetPackages -Path $testFile -Verbose 4>&1 | Out-Null } | Should -Not -Throw

            # Verify
            Should -Invoke -CommandName 'winget' -Times 1 -Exactly
            if ($null -eq $script:capturedArgs) {
                throw "Mock was called but capturedArgs is null."
            }
            $script:capturedArgs | Should -Contain 'import'
            $script:capturedArgs | Should -Contain '-i'
            $script:capturedArgs | Should -Contain $testFile
            $script:capturedArgs | Should -Contain '--accept-package-agreements'
            $script:capturedArgs | Should -Contain '--accept-source-agreements'

            # Cleanup
            Remove-Item -Path $testFile -ErrorAction SilentlyContinue
        }

        It 'Import-WingetPackages with IgnoreUnavailable passes --ignore-unavailable flag' {
            $script:capturedArgs = $null
            $testFile = 'test-winget-packages.json'
            '{"Sources":[],"Packages":[{"PackageIdentifier":"Git.Git"}]}' | Out-File -FilePath $testFile -ErrorAction SilentlyContinue
            
            Mock -CommandName winget -MockWith {
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                Write-Output 'Packages imported'
            }

            # Execute
            { Import-WingetPackages -Path $testFile -IgnoreUnavailable -Verbose 4>&1 | Out-Null } | Should -Not -Throw

            # Verify
            Should -Invoke -CommandName 'winget' -Times 1 -Exactly
            if ($null -eq $script:capturedArgs) {
                throw "Mock was called but capturedArgs is null."
            }
            $script:capturedArgs | Should -Contain 'import'
            $script:capturedArgs | Should -Contain '--ignore-unavailable'

            # Cleanup
            Remove-Item -Path $testFile -ErrorAction SilentlyContinue
        }

        It 'Import-WingetPackages with IgnoreVersions passes --ignore-versions flag' {
            $script:capturedArgs = $null
            $testFile = 'test-winget-packages.json'
            '{"Sources":[],"Packages":[{"PackageIdentifier":"Git.Git"}]}' | Out-File -FilePath $testFile -ErrorAction SilentlyContinue
            
            Mock -CommandName winget -MockWith {
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                Write-Output 'Packages imported'
            }

            # Execute
            { Import-WingetPackages -Path $testFile -IgnoreVersions -Verbose 4>&1 | Out-Null } | Should -Not -Throw

            # Verify
            Should -Invoke -CommandName 'winget' -Times 1 -Exactly
            if ($null -eq $script:capturedArgs) {
                throw "Mock was called but capturedArgs is null."
            }
            $script:capturedArgs | Should -Contain 'import'
            $script:capturedArgs | Should -Contain '--ignore-versions'

            # Cleanup
            Remove-Item -Path $testFile -ErrorAction SilentlyContinue
        }
    }
}
