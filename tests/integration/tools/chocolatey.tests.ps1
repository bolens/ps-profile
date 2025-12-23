<#
.SYNOPSIS
    Integration tests for Chocolatey tool fragment.

.DESCRIPTION
    Tests Chocolatey helper functions.
    These tests verify that functions are created correctly and handle
    missing tools gracefully.
#>

Describe 'Chocolatey Tools Integration Tests' {
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
            Write-Error "Failed to initialize Chocolatey tools tests in BeforeAll: $($errorDetails | ConvertTo-Json -Compress)" -ErrorAction Stop
            throw
        }
    }

    Context 'Chocolatey helpers (chocolatey.ps1)' {
        BeforeAll {
            # Mock choco as available so functions are created
            Mock-CommandAvailabilityPester -CommandName 'choco' -Available $true
            . (Join-Path $script:ProfileDir 'chocolatey.ps1')
        }

        It 'Creates Install-ChocoPackage function' {
            Get-Command Install-ChocoPackage -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates choinstall alias for Install-ChocoPackage' {
            Get-Alias choinstall -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias choinstall).ResolvedCommandName | Should -Be 'Install-ChocoPackage'
        }

        It 'Creates choadd alias for Install-ChocoPackage' {
            Get-Alias choadd -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias choadd).ResolvedCommandName | Should -Be 'Install-ChocoPackage'
        }

        It 'Install-ChocoPackage calls choco install' {
            # Capture arguments
            $script:capturedArgs = $null
            Mock -CommandName 'choco' -MockWith {
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                Write-Output 'Package installed successfully'
            }

            # Execute
            { Install-ChocoPackage -Packages git 4>&1 | Out-Null } | Should -Not -Throw

            # Verify
            Should -Invoke -CommandName 'choco' -Times 1 -Exactly
            if ($null -eq $script:capturedArgs) {
                throw "Mock was called but capturedArgs is null."
            }
            $script:capturedArgs | Should -Contain 'install'
            $script:capturedArgs | Should -Contain 'git'
        }

        It 'Creates Remove-ChocoPackage function' {
            Get-Command Remove-ChocoPackage -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates chouninstall alias for Remove-ChocoPackage' {
            Get-Alias chouninstall -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias chouninstall).ResolvedCommandName | Should -Be 'Remove-ChocoPackage'
        }

        It 'Creates choremove alias for Remove-ChocoPackage' {
            Get-Alias choremove -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias choremove).ResolvedCommandName | Should -Be 'Remove-ChocoPackage'
        }

        It 'Remove-ChocoPackage calls choco uninstall' {
            # Capture arguments using the direct pattern
            $script:capturedArgs = $null
            Mock -CommandName 'choco' -MockWith {
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                Write-Output 'Package removed successfully'
            }

            # Execute
            { Remove-ChocoPackage -Packages git 4>&1 | Out-Null } | Should -Not -Throw

            # Verify
            Should -Invoke -CommandName 'choco' -Times 1 -Exactly
            if ($null -eq $script:capturedArgs) {
                throw "Mock was called but capturedArgs is null."
            }
            $script:capturedArgs | Should -Contain 'uninstall'
            $script:capturedArgs | Should -Contain 'git'
        }

        It 'Creates Test-ChocoOutdated function' {
            Get-Command Test-ChocoOutdated -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates chooutdated alias for Test-ChocoOutdated' {
            Get-Alias chooutdated -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias chooutdated).ResolvedCommandName | Should -Be 'Test-ChocoOutdated'
        }

        It 'Test-ChocoOutdated calls choco outdated' {
            # Capture arguments using the direct pattern
            $script:capturedArgs = $null
            Mock -CommandName 'choco' -MockWith {
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                Write-Output 'package1|1.0.0|1.2.0'
            }

            # Execute
            { Test-ChocoOutdated -Verbose 4>&1 | Out-Null } | Should -Not -Throw

            # Verify
            Should -Invoke -CommandName 'choco' -Times 1 -Exactly
            if ($null -eq $script:capturedArgs) {
                throw "Mock was called but capturedArgs is null."
            }
            $script:capturedArgs | Should -Contain 'outdated'
        }

        It 'Creates Update-ChocoPackages function' {
            Get-Command Update-ChocoPackages -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates choupgrade alias for Update-ChocoPackages' {
            Get-Alias choupgrade -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias choupgrade).ResolvedCommandName | Should -Be 'Update-ChocoPackages'
        }

        It 'Update-ChocoPackages calls choco upgrade all for all packages' {
            # Capture arguments using the direct pattern
            $script:capturedArgs = $null
            Mock -CommandName 'choco' -MockWith {
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                Write-Output 'All packages upgraded successfully'
            }

            # Execute
            { Update-ChocoPackages -Verbose 4>&1 | Out-Null } | Should -Not -Throw

            # Verify
            Should -Invoke -CommandName 'choco' -Times 1 -Exactly
            if ($null -eq $script:capturedArgs) {
                throw "Mock was called but capturedArgs is null."
            }
            $script:capturedArgs | Should -Contain 'upgrade'
            $script:capturedArgs | Should -Contain 'all'
        }

        It 'Update-ChocoPackages calls choco upgrade for specific packages' {
            # Capture arguments using the direct pattern
            $script:capturedArgs = $null
            Mock -CommandName 'choco' -MockWith {
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                Write-Output 'git upgraded successfully'
            }

            # Execute
            { Update-ChocoPackages -Packages git -Verbose 4>&1 | Out-Null } | Should -Not -Throw

            # Verify
            Should -Invoke -CommandName 'choco' -Times 1 -Exactly
            if ($null -eq $script:capturedArgs) {
                throw "Mock was called but capturedArgs is null."
            }
            $script:capturedArgs | Should -Contain 'upgrade'
            $script:capturedArgs | Should -Contain 'git'
            $script:capturedArgs | Should -Not -Contain 'all'
        }

        It 'Creates Update-ChocoSelf function' {
            Get-Command Update-ChocoSelf -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates choselfupdate alias for Update-ChocoSelf' {
            Get-Alias choselfupdate -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias choselfupdate).ResolvedCommandName | Should -Be 'Update-ChocoSelf'
        }

        It 'Update-ChocoSelf calls choco upgrade chocolatey -y' {
            # Capture arguments using the direct pattern
            $script:capturedArgs = $null
            Mock -CommandName 'choco' -MockWith {
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                Write-Output 'Chocolatey updated successfully'
            }

            # Execute
            { Update-ChocoSelf -Verbose 4>&1 | Out-Null } | Should -Not -Throw

            # Verify
            Should -Invoke -CommandName 'choco' -Times 1 -Exactly
            if ($null -eq $script:capturedArgs) {
                throw "Mock was called but capturedArgs is null."
            }
            $script:capturedArgs | Should -Contain 'upgrade'
            $script:capturedArgs | Should -Contain 'chocolatey'
            $script:capturedArgs | Should -Contain '-y'
        }

        It 'Creates Clear-ChocoCache function' {
            Get-Command Clear-ChocoCache -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates chocleanup alias for Clear-ChocoCache' {
            Get-Alias chocleanup -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias chocleanup).ResolvedCommandName | Should -Be 'Clear-ChocoCache'
        }

        It 'Creates choclean alias for Clear-ChocoCache' {
            Get-Alias choclean -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias choclean).ResolvedCommandName | Should -Be 'Clear-ChocoCache'
        }

        It 'Clear-ChocoCache calls choco clean' {
            $script:capturedArgs = $null
            Mock -CommandName 'choco' -MockWith {
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                Write-Output 'Cache cleaned successfully'
            }

            # Execute
            { Clear-ChocoCache -Verbose 4>&1 | Out-Null } | Should -Not -Throw

            # Verify
            Should -Invoke -CommandName 'choco' -Times 1 -Exactly
            if ($null -eq $script:capturedArgs) {
                throw "Mock was called but capturedArgs is null."
            }
            $script:capturedArgs | Should -Contain 'clean'
        }

        It 'Clear-ChocoCache with Yes passes -y flag' {
            $script:capturedArgs = $null
            Mock -CommandName 'choco' -MockWith {
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                Write-Output 'Cache cleaned successfully'
            }

            # Execute
            { Clear-ChocoCache -Yes -Verbose 4>&1 | Out-Null } | Should -Not -Throw

            # Verify
            Should -Invoke -CommandName 'choco' -Times 1 -Exactly
            if ($null -eq $script:capturedArgs) {
                throw "Mock was called but capturedArgs is null."
            }
            $script:capturedArgs | Should -Contain 'clean'
            $script:capturedArgs | Should -Contain '-y'
        }

        It 'Creates Find-ChocoPackage function' {
            Get-Command Find-ChocoPackage -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates chosearch alias for Find-ChocoPackage' {
            Get-Alias chosearch -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias chosearch).ResolvedCommandName | Should -Be 'Find-ChocoPackage'
        }

        It 'Creates chofind alias for Find-ChocoPackage' {
            Get-Alias chofind -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias chofind).ResolvedCommandName | Should -Be 'Find-ChocoPackage'
        }

        It 'Find-ChocoPackage calls choco search' {
            $script:capturedArgs = $null
            Mock -CommandName 'choco' -MockWith {
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                Write-Output 'git|2.40.0'
            }

            # Execute
            { Find-ChocoPackage -Query git -Verbose 4>&1 | Out-Null } | Should -Not -Throw

            # Verify
            Should -Invoke -CommandName 'choco' -Times 1 -Exactly
            if ($null -eq $script:capturedArgs) {
                throw "Mock was called but capturedArgs is null."
            }
            $script:capturedArgs | Should -Contain 'search'
            $script:capturedArgs | Should -Contain 'git'
        }

        It 'Find-ChocoPackage with Exact passes --exact flag' {
            $script:capturedArgs = $null
            Mock -CommandName 'choco' -MockWith {
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                Write-Output 'git|2.40.0'
            }

            # Execute
            { Find-ChocoPackage -Query git -Exact -Verbose 4>&1 | Out-Null } | Should -Not -Throw

            # Verify
            Should -Invoke -CommandName 'choco' -Times 1 -Exactly
            if ($null -eq $script:capturedArgs) {
                throw "Mock was called but capturedArgs is null."
            }
            $script:capturedArgs | Should -Contain 'search'
            $script:capturedArgs | Should -Contain '--exact'
            $script:capturedArgs | Should -Contain 'git'
        }

        It 'Creates Get-ChocoPackage function' {
            Get-Command Get-ChocoPackage -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates cholist alias for Get-ChocoPackage' {
            Get-Alias cholist -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias cholist).ResolvedCommandName | Should -Be 'Get-ChocoPackage'
        }

        It 'Get-ChocoPackage calls choco list --local-only' {
            $script:capturedArgs = $null
            Mock -CommandName 'choco' -MockWith {
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                Write-Output 'git|2.40.0'
            }

            # Execute
            { Get-ChocoPackage -Verbose 4>&1 | Out-Null } | Should -Not -Throw

            # Verify
            Should -Invoke -CommandName 'choco' -Times 1 -Exactly
            if ($null -eq $script:capturedArgs) {
                throw "Mock was called but capturedArgs is null."
            }
            $script:capturedArgs | Should -Contain 'list'
            $script:capturedArgs | Should -Contain '--local-only'
        }

        It 'Get-ChocoPackage with IncludePrograms calls choco list' {
            $script:capturedArgs = $null
            Mock -CommandName 'choco' -MockWith {
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                Write-Output 'git|2.40.0'
            }

            # Execute
            { Get-ChocoPackage -IncludePrograms -Verbose 4>&1 | Out-Null } | Should -Not -Throw

            # Verify
            Should -Invoke -CommandName 'choco' -Times 1 -Exactly
            if ($null -eq $script:capturedArgs) {
                throw "Mock was called but capturedArgs is null."
            }
            $script:capturedArgs | Should -Contain 'list'
            $script:capturedArgs | Should -Not -Contain '--local-only'
        }

        It 'Creates Get-ChocoPackageInfo function' {
            Get-Command Get-ChocoPackageInfo -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates choinfo alias for Get-ChocoPackageInfo' {
            Get-Alias choinfo -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias choinfo).ResolvedCommandName | Should -Be 'Get-ChocoPackageInfo'
        }

        It 'Get-ChocoPackageInfo calls choco info' {
            $script:capturedArgs = $null
            Mock -CommandName 'choco' -MockWith {
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                Write-Output 'Chocolatey v2.0.0'
                Write-Output 'git 2.40.0'
            }

            # Execute
            { Get-ChocoPackageInfo -Packages git -Verbose 4>&1 | Out-Null } | Should -Not -Throw

            # Verify
            Should -Invoke -CommandName 'choco' -Times 1 -Exactly
            if ($null -eq $script:capturedArgs) {
                throw "Mock was called but capturedArgs is null."
            }
            $script:capturedArgs | Should -Contain 'info'
            $script:capturedArgs | Should -Contain 'git'
        }

        It 'Get-ChocoPackageInfo with Source passes --source flag' {
            $script:capturedArgs = $null
            Mock -CommandName 'choco' -MockWith {
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                Write-Output 'git 2.40.0'
            }

            # Execute
            { Get-ChocoPackageInfo -Packages git -Source chocolatey -Verbose 4>&1 | Out-Null } | Should -Not -Throw

            # Verify
            Should -Invoke -CommandName 'choco' -Times 1 -Exactly
            if ($null -eq $script:capturedArgs) {
                throw "Mock was called but capturedArgs is null."
            }
            $script:capturedArgs | Should -Contain 'info'
            $script:capturedArgs | Should -Contain '--source'
            $script:capturedArgs | Should -Contain 'chocolatey'
        }

        It 'Creates Export-ChocoPackages function' {
            Get-Command Export-ChocoPackages -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates choexport alias for Export-ChocoPackages' {
            Get-Alias choexport -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias choexport).ResolvedCommandName | Should -Be 'Export-ChocoPackages'
        }

        It 'Creates chobackup alias for Export-ChocoPackages' {
            Get-Alias chobackup -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias chobackup).ResolvedCommandName | Should -Be 'Export-ChocoPackages'
        }

        It 'Export-ChocoPackages calls choco export' {
            $script:capturedArgs = $null
            Mock -CommandName 'choco' -MockWith {
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                Write-Output 'Packages exported successfully'
            }

            # Execute
            { Export-ChocoPackages -Path 'test-packages.config' -Verbose 4>&1 | Out-Null } | Should -Not -Throw

            # Verify
            Should -Invoke -CommandName 'choco' -Times 1 -Exactly
            if ($null -eq $script:capturedArgs) {
                throw "Mock was called but capturedArgs is null."
            }
            $script:capturedArgs | Should -Contain 'export'
            $script:capturedArgs | Should -Contain '-o'
            $script:capturedArgs | Should -Contain 'test-packages.config'
        }

        It 'Export-ChocoPackages with IncludeVersions passes --include-version-numbers flag' {
            $script:capturedArgs = $null
            Mock -CommandName 'choco' -MockWith {
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                Write-Output 'Packages exported with versions'
            }

            # Execute
            { Export-ChocoPackages -Path 'test-packages.config' -IncludeVersions -Verbose 4>&1 | Out-Null } | Should -Not -Throw

            # Verify
            Should -Invoke -CommandName 'choco' -Times 1 -Exactly
            if ($null -eq $script:capturedArgs) {
                throw "Mock was called but capturedArgs is null."
            }
            $script:capturedArgs | Should -Contain 'export'
            $script:capturedArgs | Should -Contain '--include-version-numbers'
        }

        It 'Creates Import-ChocoPackages function' {
            Get-Command Import-ChocoPackages -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates choimport alias for Import-ChocoPackages' {
            Get-Alias choimport -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias choimport).ResolvedCommandName | Should -Be 'Import-ChocoPackages'
        }

        It 'Creates chorestore alias for Import-ChocoPackages' {
            Get-Alias chorestore -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias chorestore).ResolvedCommandName | Should -Be 'Import-ChocoPackages'
        }

        It 'Import-ChocoPackages calls choco install with packages.config' {
            $script:capturedArgs = $null
            $testFile = 'test-packages.config'
            # Create a mock file
            '<?xml version="1.0"?><packages><package id="git" /></packages>' | Out-File -FilePath $testFile -ErrorAction SilentlyContinue
            
            Mock -CommandName 'choco' -MockWith {
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                Write-Output 'Packages imported successfully'
            }

            # Execute
            { Import-ChocoPackages -Path $testFile -Verbose 4>&1 | Out-Null } | Should -Not -Throw

            # Verify
            Should -Invoke -CommandName 'choco' -Times 1 -Exactly
            if ($null -eq $script:capturedArgs) {
                throw "Mock was called but capturedArgs is null."
            }
            $script:capturedArgs | Should -Contain 'install'
            $script:capturedArgs | Should -Contain $testFile

            # Cleanup
            Remove-Item -Path $testFile -ErrorAction SilentlyContinue
        }

        It 'Import-ChocoPackages with Yes passes -y flag' {
            $script:capturedArgs = $null
            $testFile = 'test-packages.config'
            '<?xml version="1.0"?><packages><package id="git" /></packages>' | Out-File -FilePath $testFile -ErrorAction SilentlyContinue
            
            Mock -CommandName 'choco' -MockWith {
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                Write-Output 'Packages imported successfully'
            }

            # Execute
            { Import-ChocoPackages -Path $testFile -Yes -Verbose 4>&1 | Out-Null } | Should -Not -Throw

            # Verify
            Should -Invoke -CommandName 'choco' -Times 1 -Exactly
            if ($null -eq $script:capturedArgs) {
                throw "Mock was called but capturedArgs is null."
            }
            $script:capturedArgs | Should -Contain 'install'
            $script:capturedArgs | Should -Contain '-y'

            # Cleanup
            Remove-Item -Path $testFile -ErrorAction SilentlyContinue
        }

        It 'Chocolatey fragment handles missing tool gracefully' {
            BeforeAll {
                # Clear caches and warnings
                if ($global:MissingToolWarnings) {
                    $null = $global:MissingToolWarnings.TryRemove('choco', [ref]$null)
                }
                if ($null -ne $global:TestCachedCommandCache) {
                    $global:TestCachedCommandCache = @{}
                }
                if ($null -ne $global:AssumedAvailableCommands) {
                    $null = $global:AssumedAvailableCommands.TryRemove('choco', [ref]$null)
                    $null = $global:AssumedAvailableCommands.TryRemove('choco'.ToLowerInvariant(), [ref]$null)
                }
            
                # Clear any function mocks that might exist
                Remove-Item Function:choco -ErrorAction SilentlyContinue
                Remove-Item Function:global:choco -ErrorAction SilentlyContinue
            
                # Mock choco as unavailable BEFORE loading the fragment
                Mock-CommandAvailabilityPester -CommandName 'choco' -Available $false
            
                # Remove any existing Chocolatey functions
                Remove-Item Function:Install-ChocoPackage -ErrorAction SilentlyContinue
                Remove-Item Function:Remove-ChocoPackage -ErrorAction SilentlyContinue
                Remove-Item Function:Update-ChocoPackages -ErrorAction SilentlyContinue
                Remove-Item Function:Test-ChocoOutdated -ErrorAction SilentlyContinue
                Remove-Item Function:Update-ChocoSelf -ErrorAction SilentlyContinue
                Remove-Item Function:Clear-ChocoCache -ErrorAction SilentlyContinue
                Remove-Item Function:Find-ChocoPackage -ErrorAction SilentlyContinue
                Remove-Item Function:Get-ChocoPackage -ErrorAction SilentlyContinue
                Remove-Item Function:Get-ChocoPackageInfo -ErrorAction SilentlyContinue
                Remove-Item Function:Export-ChocoPackages -ErrorAction SilentlyContinue
                Remove-Item Function:Import-ChocoPackages -ErrorAction SilentlyContinue
                
                # Reload the fragment - functions should not be created since choco is unavailable
                . (Join-Path $script:ProfileDir 'chocolatey.ps1')
            }

            It 'Functions are not created when choco is unavailable' {
                # Verify functions were not created
                Get-Command Install-ChocoPackage -ErrorAction SilentlyContinue | Should -BeNullOrEmpty
            }
        }
    }
}
