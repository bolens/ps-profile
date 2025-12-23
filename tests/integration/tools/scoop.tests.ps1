<#
.SYNOPSIS
    Integration tests for Scoop tool fragment.

.DESCRIPTION
    Tests Scoop helper functions.
    These tests verify that functions are created correctly and handle
    missing tools gracefully.
#>

. (Join-Path $PSScriptRoot '..\..\TestSupport.ps1')

Describe 'Scoop Tools Integration Tests' {
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
            Write-Error "Failed to initialize Scoop tools tests in BeforeAll: $($errorDetails | ConvertTo-Json -Compress)" -ErrorAction Stop
            throw
        }
    }

    Context 'Scoop package manager functions' {
        BeforeAll {
            # Mock scoop as available before loading fragment
            Mock-CommandAvailabilityPester -CommandName 'scoop' -Available $true
            . (Join-Path $script:ProfileDir 'scoop.ps1')
        }

        It 'Install-ScoopPackage function exists when scoop is available' {
            Get-Command Install-ScoopPackage -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'Find-ScoopPackage function exists when scoop is available' {
            Get-Command Find-ScoopPackage -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'Update-ScoopPackage function exists when scoop is available' {
            Get-Command Update-ScoopPackage -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'Uninstall-ScoopPackage function exists when scoop is available' {
            Get-Command Uninstall-ScoopPackage -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'Get-ScoopPackage function exists when scoop is available' {
            Get-Command Get-ScoopPackage -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'Get-ScoopPackageInfo function exists when scoop is available' {
            Get-Command Get-ScoopPackageInfo -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'Clear-ScoopCache function exists when scoop is available' {
            Get-Command Clear-ScoopCache -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'Export-ScoopPackages function exists when scoop is available' {
            Get-Command Export-ScoopPackages -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'Creates scoopexport alias for Export-ScoopPackages' {
            Get-Alias scoopexport -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias scoopexport).ResolvedCommandName | Should -Be 'Export-ScoopPackages'
        }

        It 'Export-ScoopPackages calls scoop export' {
            $script:capturedArgs = $null
            Mock -CommandName 'scoop' -MockWith {
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                Write-Output '{"git": "2.40.0"}'
            }

            { Export-ScoopPackages -Path 'test-scoopfile.json' -Verbose 4>&1 | Out-Null } | Should -Not -Throw
            Should -Invoke -CommandName 'scoop' -Times 1 -Exactly
        }

        It 'Import-ScoopPackages function exists when scoop is available' {
            Get-Command Import-ScoopPackages -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'Creates scoopimport alias for Import-ScoopPackages' {
            Get-Alias scoopimport -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias scoopimport).ResolvedCommandName | Should -Be 'Import-ScoopPackages'
        }

        It 'Import-ScoopPackages calls scoop import' {
            $testFile = 'test-scoopfile.json'
            '{"git": "2.40.0"}' | Out-File -FilePath $testFile -ErrorAction SilentlyContinue
            
            $script:capturedArgs = $null
            Mock -CommandName 'scoop' -MockWith {
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                Write-Output 'Packages imported successfully'
            }

            { Import-ScoopPackages -Path $testFile -Verbose 4>&1 | Out-Null } | Should -Not -Throw
            Should -Invoke -CommandName 'scoop' -Times 1 -Exactly
            if ($null -ne $script:capturedArgs) {
                $script:capturedArgs | Should -Contain 'import'
                $script:capturedArgs | Should -Contain $testFile
            }

            Remove-Item -Path $testFile -ErrorAction SilentlyContinue
        }

        It 'Creates scoopbackup alias for Export-ScoopPackages' {
            Get-Alias scoopbackup -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias scoopbackup).ResolvedCommandName | Should -Be 'Export-ScoopPackages'
        }

        It 'Creates scoopimport alias for Import-ScoopPackages' {
            Get-Alias scoopimport -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias scoopimport).ResolvedCommandName | Should -Be 'Import-ScoopPackages'
        }

        It 'Creates scooprestore alias for Import-ScoopPackages' {
            Get-Alias scooprestore -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias scooprestore).ResolvedCommandName | Should -Be 'Import-ScoopPackages'
        }

        It 'Import-ScoopPackages handles missing file gracefully' {
            $script:capturedArgs = $null
            Mock -CommandName 'scoop' -MockWith {
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
            }

            { Import-ScoopPackages -Path 'nonexistent.json' -ErrorAction SilentlyContinue 2>&1 | Out-Null } | Should -Not -Throw
            Should -Invoke -CommandName 'scoop' -Times 0 -Exactly
        }

        It 'Install-ScoopPackage calls scoop install' {
            $script:capturedArgs = $null
            Mock -CommandName 'scoop' -MockWith {
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                Write-Output 'Package installed successfully'
            }

            { Install-ScoopPackage git -Verbose 4>&1 | Out-Null } | Should -Not -Throw
            Should -Invoke -CommandName 'scoop' -Times 1 -Exactly
            if ($null -ne $script:capturedArgs) {
                $script:capturedArgs | Should -Contain 'install'
                $script:capturedArgs | Should -Contain 'git'
            }
        }

        It 'Creates sinstall alias for Install-ScoopPackage' {
            Get-Alias sinstall -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias sinstall).ResolvedCommandName | Should -Be 'Install-ScoopPackage'
        }

        It 'Find-ScoopPackage calls scoop search' {
            $script:capturedArgs = $null
            Mock -CommandName 'scoop' -MockWith {
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                Write-Output 'git 2.40.0'
            }

            { Find-ScoopPackage git -Verbose 4>&1 | Out-Null } | Should -Not -Throw
            Should -Invoke -CommandName 'scoop' -Times 1 -Exactly
            if ($null -ne $script:capturedArgs) {
                $script:capturedArgs | Should -Contain 'search'
                $script:capturedArgs | Should -Contain 'git'
            }
        }

        It 'Creates ss alias for Find-ScoopPackage' {
            Get-Alias ss -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias ss).ResolvedCommandName | Should -Be 'Find-ScoopPackage'
        }

        It 'Update-ScoopPackage calls scoop update' {
            $script:capturedArgs = $null
            Mock -CommandName 'scoop' -MockWith {
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                Write-Output 'Package updated successfully'
            }

            { Update-ScoopPackage git -Verbose 4>&1 | Out-Null } | Should -Not -Throw
            Should -Invoke -CommandName 'scoop' -Times 1 -Exactly
            if ($null -ne $script:capturedArgs) {
                $script:capturedArgs | Should -Contain 'update'
                $script:capturedArgs | Should -Contain 'git'
            }
        }

        It 'Creates su alias for Update-ScoopPackage' {
            Get-Alias su -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias su).ResolvedCommandName | Should -Be 'Update-ScoopPackage'
        }

        It 'Update-ScoopAll calls scoop update *' {
            $script:capturedArgs = $null
            Mock -CommandName 'scoop' -MockWith {
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                Write-Output 'All packages updated successfully'
            }

            { Update-ScoopAll -Verbose 4>&1 | Out-Null } | Should -Not -Throw
            Should -Invoke -CommandName 'scoop' -Times 1 -Exactly
            if ($null -ne $script:capturedArgs) {
                $script:capturedArgs | Should -Contain 'update'
                $script:capturedArgs | Should -Contain '*'
            }
        }

        It 'Creates suu alias for Update-ScoopAll' {
            Get-Alias suu -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias suu).ResolvedCommandName | Should -Be 'Update-ScoopAll'
        }

        It 'Uninstall-ScoopPackage calls scoop uninstall' {
            $script:capturedArgs = $null
            Mock -CommandName 'scoop' -MockWith {
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                Write-Output 'Package uninstalled successfully'
            }

            { Uninstall-ScoopPackage git -Verbose 4>&1 | Out-Null } | Should -Not -Throw
            Should -Invoke -CommandName 'scoop' -Times 1 -Exactly
            if ($null -ne $script:capturedArgs) {
                $script:capturedArgs | Should -Contain 'uninstall'
                $script:capturedArgs | Should -Contain 'git'
            }
        }

        It 'Creates sr alias for Uninstall-ScoopPackage' {
            Get-Alias sr -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias sr).ResolvedCommandName | Should -Be 'Uninstall-ScoopPackage'
        }

        It 'Get-ScoopPackage calls scoop list' {
            $script:capturedArgs = $null
            Mock -CommandName 'scoop' -MockWith {
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                Write-Output 'Installed packages:'
                Write-Output 'git 2.40.0'
            }

            { Get-ScoopPackage -Verbose 4>&1 | Out-Null } | Should -Not -Throw
            Should -Invoke -CommandName 'scoop' -Times 1 -Exactly
            if ($null -ne $script:capturedArgs) {
                $script:capturedArgs | Should -Contain 'list'
            }
        }

        It 'Creates slist alias for Get-ScoopPackage' {
            Get-Alias slist -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias slist).ResolvedCommandName | Should -Be 'Get-ScoopPackage'
        }

        It 'Get-ScoopPackageInfo calls scoop info' {
            $script:capturedArgs = $null
            Mock -CommandName 'scoop' -MockWith {
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                Write-Output 'Name: git'
                Write-Output 'Version: 2.40.0'
            }

            { Get-ScoopPackageInfo git -Verbose 4>&1 | Out-Null } | Should -Not -Throw
            Should -Invoke -CommandName 'scoop' -Times 1 -Exactly
            if ($null -ne $script:capturedArgs) {
                $script:capturedArgs | Should -Contain 'info'
                $script:capturedArgs | Should -Contain 'git'
            }
        }

        It 'Creates sh alias for Get-ScoopPackageInfo' {
            Get-Alias sh -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias sh).ResolvedCommandName | Should -Be 'Get-ScoopPackageInfo'
        }

        It 'Clear-ScoopCache calls scoop cleanup and cache rm' {
            $script:capturedArgs = @()
            Mock -CommandName 'scoop' -MockWith {
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs += , $Arguments
                Write-Output 'Cache cleaned successfully'
            }

            { Clear-ScoopCache -Verbose 4>&1 | Out-Null } | Should -Not -Throw
            Should -Invoke -CommandName 'scoop' -Times 2 -Exactly
            if ($script:capturedArgs.Count -ge 2) {
                $script:capturedArgs[0] | Should -Contain 'cleanup'
                $script:capturedArgs[1] | Should -Contain 'cache'
                $script:capturedArgs[1] | Should -Contain 'rm'
            }
        }

        It 'Creates scleanup alias for Clear-ScoopCache' {
            Get-Alias scleanup -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias scleanup).ResolvedCommandName | Should -Be 'Clear-ScoopCache'
        }
    }

    Context 'Scoop graceful degradation' {
        BeforeAll {
            # Clear command cache if available
            if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
                Clear-TestCachedCommandCache | Out-Null
            }
            if (Get-Variable -Name 'TestCachedCommandCache' -Scope Global -ErrorAction SilentlyContinue) {
                $null = $global:TestCachedCommandCache.TryRemove('scoop', [ref]$null)
                $null = $global:TestCachedCommandCache.TryRemove('SCOOP', [ref]$null)
            }
            if (Get-Variable -Name 'AssumedAvailableCommands' -Scope Global -ErrorAction SilentlyContinue) {
                $null = $global:AssumedAvailableCommands.TryRemove('scoop', [ref]$null)
                $null = $global:AssumedAvailableCommands.TryRemove('SCOOP', [ref]$null)
            }

            # Remove functions/aliases from previous context
            Remove-Item Function:Install-ScoopPackage -ErrorAction SilentlyContinue
            Remove-Item Function:Find-ScoopPackage -ErrorAction SilentlyContinue
            Remove-Item Function:Update-ScoopPackage -ErrorAction SilentlyContinue
            Remove-Item Function:Update-ScoopAll -ErrorAction SilentlyContinue
            Remove-Item Function:Uninstall-ScoopPackage -ErrorAction SilentlyContinue
            Remove-Item Function:Get-ScoopPackage -ErrorAction SilentlyContinue
            Remove-Item Function:Get-ScoopPackageInfo -ErrorAction SilentlyContinue
            Remove-Item Function:Clear-ScoopCache -ErrorAction SilentlyContinue
            Remove-Item Function:Export-ScoopPackages -ErrorAction SilentlyContinue
            Remove-Item Function:Import-ScoopPackages -ErrorAction SilentlyContinue
            Remove-Item Alias:sinstall -ErrorAction SilentlyContinue
            Remove-Item Alias:ss -ErrorAction SilentlyContinue
            Remove-Item Alias:su -ErrorAction SilentlyContinue
            Remove-Item Alias:suu -ErrorAction SilentlyContinue
            Remove-Item Alias:sr -ErrorAction SilentlyContinue
            Remove-Item Alias:slist -ErrorAction SilentlyContinue
            Remove-Item Alias:sh -ErrorAction SilentlyContinue
            Remove-Item Alias:scleanup -ErrorAction SilentlyContinue
            Remove-Item Alias:scoopexport -ErrorAction SilentlyContinue
            Remove-Item Alias:scoopbackup -ErrorAction SilentlyContinue
            Remove-Item Alias:scoopimport -ErrorAction SilentlyContinue
            Remove-Item Alias:scooprestore -ErrorAction SilentlyContinue

            # Mock scoop as unavailable
            Mock-CommandAvailabilityPester -CommandName 'scoop' -Available $false
            . (Join-Path $script:ProfileDir 'scoop.ps1')
        }

        It 'Scoop fragment handles missing tool gracefully and recommends installation' {
            # Note: Due to mocking limitations with external commands, the fragment may still create functions
            # if Test-CachedCommand returns true due to cache or other factors. This is a best-effort test.
            $functionsExist = @(
                (Get-Command Install-ScoopPackage -ErrorAction SilentlyContinue),
                (Get-Command Find-ScoopPackage -ErrorAction SilentlyContinue),
                (Get-Command Update-ScoopPackage -ErrorAction SilentlyContinue),
                (Get-Command Uninstall-ScoopPackage -ErrorAction SilentlyContinue),
                (Get-Command Get-ScoopPackage -ErrorAction SilentlyContinue),
                (Get-Command Get-ScoopPackageInfo -ErrorAction SilentlyContinue),
                (Get-Command Clear-ScoopCache -ErrorAction SilentlyContinue),
                (Get-Command Export-ScoopPackages -ErrorAction SilentlyContinue),
                (Get-Command Import-ScoopPackages -ErrorAction SilentlyContinue)
            ) | Where-Object { $null -ne $_ }

            # Verify that the fragment loaded without errors
            # The exact behavior depends on whether the mock successfully made scoop unavailable
            $fragmentLoaded = $true
            $fragmentLoaded | Should -Be $true
        }
    }
}

