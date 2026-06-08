<#
.SYNOPSIS
    Integration tests for winget tool fragment.

.DESCRIPTION
    Tests winget helper functions.
    These tests verify that functions are created correctly and handle
    missing tools gracefully.
#>

BeforeAll {
    $current = Get-Item $PSScriptRoot
    while ($null -ne $current) {
        $testSupportPath = Join-Path $current.FullName 'TestSupport.ps1'
        if (Test-Path -LiteralPath $testSupportPath) {
            . $testSupportPath
            break
        }
        if ($current.Name -eq 'tests' -or $current.Parent -eq $null) { break }
        $current = $current.Parent
    }
}

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
            Set-TestCommandAvailabilityState -CommandName 'winget' -Available $true
            . (Join-Path $script:ProfileDir 'winget.ps1')
        }

        BeforeEach {
            Clear-TestCommandInvocationCapture
        }

        It 'Creates Test-WingetOutdated function' {
            Get-Command Test-WingetOutdated -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates winget-outdated alias for Test-WingetOutdated' {
            Get-Alias winget-outdated -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias winget-outdated).ResolvedCommandName | Should -Be 'Test-WingetOutdated'
        }

        It 'Test-WingetOutdated calls winget upgrade' {
            Setup-CapturingCommandMock -CommandName 'winget' -Output @(
                'Name    Id    Version    Available'
                'App1    app1  1.0.0      1.2.0'
            )

            Test-WingetOutdated
            Assert-TestCommandInvokedExactlyOnce
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
            Setup-CapturingCommandMock -CommandName 'winget' -Output 'All packages updated successfully'
            # Execute
            { Update-WingetPackages -Verbose 4>&1 | Out-Null } | Should -Not -Throw

            # Verify
            Assert-TestCommandInvokedExactlyOnce
            Assert-TestCommandInvocationContains 'upgrade'
            Assert-TestCommandInvocationContains '--all'
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
            Setup-CapturingCommandMock -CommandName 'winget' -Output 'Cache cleaned successfully'
            # Execute
            { Clear-WingetCache -Verbose 4>&1 | Out-Null } | Should -Not -Throw

            # Verify
            Assert-TestCommandInvokedExactlyOnce
            Assert-TestCommandInvocationContains 'cache'
            Assert-TestCommandInvocationContains 'clean'
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
            Setup-CapturingCommandMock -CommandName 'winget' -Output 'Package installed successfully'
            # Execute
            { Install-WingetPackage -Packages Git.Git -Verbose 4>&1 | Out-Null } | Should -Not -Throw

            # Verify
            Assert-TestCommandInvokedExactlyOnce
            Assert-TestCommandInvocationContains 'install'
            Assert-TestCommandInvocationContains 'Git.Git'
            Assert-TestCommandInvocationContains '--accept-package-agreements'
            Assert-TestCommandInvocationContains '--accept-source-agreements'
        }

        It 'Install-WingetPackage with Version passes --version flag' {
            Setup-CapturingCommandMock -CommandName 'winget' -Output 'Package installed successfully'
            # Execute
            { Install-WingetPackage -Packages Git.Git -Version 2.40.0 -Verbose 4>&1 | Out-Null } | Should -Not -Throw

            # Verify
            Assert-TestCommandInvokedExactlyOnce
            Assert-TestCommandInvocationContains 'install'
            Assert-TestCommandInvocationContains '--version'
            Assert-TestCommandInvocationContains '2.40.0'
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
            Setup-CapturingCommandMock -CommandName 'winget' -Output 'Package removed successfully'
            # Execute
            { Remove-WingetPackage -Packages Git.Git -Verbose 4>&1 | Out-Null } | Should -Not -Throw

            # Verify
            Assert-TestCommandInvokedExactlyOnce
            Assert-TestCommandInvocationContains 'uninstall'
            Assert-TestCommandInvocationContains 'Git.Git'
            Assert-TestCommandInvocationContains '--accept-source-agreements'
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
            Setup-CapturingCommandMock -CommandName 'winget' -Output @(
                'Name    Id    Version'
                'Git     Git.Git    2.40.0'
            )
            # Execute
            { Find-WingetPackage -Query git -Verbose 4>&1 | Out-Null } | Should -Not -Throw

            # Verify
            Assert-TestCommandInvokedExactlyOnce
            Assert-TestCommandInvocationContains 'search'
            Assert-TestCommandInvocationContains 'git'
        }

        It 'Find-WingetPackage with Exact passes --exact flag' {
            Setup-CapturingCommandMock -CommandName 'winget' -Output @(
                'Name    Id    Version'
                'Git     Git.Git    2.40.0'
            )
            # Execute
            { Find-WingetPackage -Query Git.Git -Exact -Verbose 4>&1 | Out-Null } | Should -Not -Throw

            # Verify
            Assert-TestCommandInvokedExactlyOnce
            Assert-TestCommandInvocationContains 'search'
            Assert-TestCommandInvocationContains '--exact'
            Assert-TestCommandInvocationContains 'Git.Git'
        }

        It 'Creates Get-WingetPackage function' {
            Get-Command Get-WingetPackage -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates winget-list alias for Get-WingetPackage' {
            Get-Alias winget-list -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias winget-list).ResolvedCommandName | Should -Be 'Get-WingetPackage'
        }

        It 'Get-WingetPackage calls winget list' {
            Setup-CapturingCommandMock -CommandName 'winget' -Output @(
                'Name    Id    Version'
                'Git     Git.Git    2.40.0'
            )
            # Execute
            { Get-WingetPackage -Verbose 4>&1 | Out-Null } | Should -Not -Throw

            # Verify
            Assert-TestCommandInvokedExactlyOnce
            Assert-TestCommandInvocationContains 'list'
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
            Setup-CapturingCommandMock -CommandName 'winget' -Output @(
                'Found Git [Git.Git]'
                'Version: 2.40.0'
            )
            # Execute
            { Get-WingetPackageInfo -Packages Git.Git -Verbose 4>&1 | Out-Null } | Should -Not -Throw

            # Verify
            Assert-TestCommandInvokedExactlyOnce
            Assert-TestCommandInvocationContains 'show'
            Assert-TestCommandInvocationContains 'Git.Git'
        }

        It 'Get-WingetPackageInfo with Version passes --version flag' {
            Setup-CapturingCommandMock -CommandName 'winget' -Output @(
                'Found Git [Git.Git]'
                'Version: 2.40.0'
            )
            # Execute
            { Get-WingetPackageInfo -Packages Git.Git -Version 2.40.0 -Verbose 4>&1 | Out-Null } | Should -Not -Throw

            # Verify
            Assert-TestCommandInvokedExactlyOnce
            Assert-TestCommandInvocationContains 'show'
            Assert-TestCommandInvocationContains '--version'
            Assert-TestCommandInvocationContains '2.40.0'
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
            Setup-CapturingCommandMock -CommandName 'winget' -Output 'Packages exported successfully'
            $testPath = Get-TestArtifactPath -FileName 'test-winget-packages.json'

            # Execute
            { Export-WingetPackages -Path $testPath -Verbose 4>&1 | Out-Null } | Should -Not -Throw

            # Verify
            Assert-TestCommandInvokedExactlyOnce
            Assert-TestCommandInvocationContains 'export'
            Assert-TestCommandInvocationContains '-o'
            Assert-TestCommandInvocationContains $testPath
        }

        It 'Export-WingetPackages with Source passes --source flag' {
            Setup-CapturingCommandMock -CommandName 'winget' -Output 'Packages exported from source'
            # Execute
            { Export-WingetPackages -Path (Get-TestArtifactPath -FileName 'test-winget-packages.json') -Source winget -Verbose 4>&1 | Out-Null } | Should -Not -Throw

            # Verify
            Assert-TestCommandInvokedExactlyOnce
            Assert-TestCommandInvocationContains 'export'
            Assert-TestCommandInvocationContains '--source'
            Assert-TestCommandInvocationContains 'winget'
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
            $testFile = Get-TestArtifactPath -FileName 'test-winget-packages.json'
            '{"Sources":[],"Packages":[{"PackageIdentifier":"Git.Git","Version":"2.40.0"}]}' | Out-File -FilePath $testFile -ErrorAction SilentlyContinue

            if (Get-Command Invoke-WithWideEvent -ErrorAction SilentlyContinue) {
                Set-Item -Path 'Function:\global:Invoke-WithWideEvent' -Value {
                    param(
                        [Parameter(Mandatory)]
                        [string]$OperationName,
                        [Parameter(Mandatory)]
                        [scriptblock]$ScriptBlock,
                        [hashtable]$Context = @{},
                        [string]$Level = 'INFO',
                        [switch]$AlwaysKeep
                    )
                    & $ScriptBlock
                } -Force
            }

            Setup-CapturingCommandMock -CommandName 'winget' -Output 'Packages imported successfully'

            { Import-WingetPackages -Path $testFile -Verbose 4>&1 | Out-Null } | Should -Not -Throw

            $capturedArgs = Get-TestCommandInvocationArgsFlat
            $capturedArgs | Should -Not -BeNullOrEmpty
            $capturedArgs | Should -Contain 'import'
            $capturedArgs | Should -Contain '-i'
            $capturedArgs | Should -Contain $testFile
            $capturedArgs | Should -Contain '--accept-package-agreements'
            $capturedArgs | Should -Contain '--accept-source-agreements'
        }

        It 'Import-WingetPackages with IgnoreUnavailable passes --ignore-unavailable flag' {
            $testFile = Get-TestArtifactPath -FileName 'test-winget-packages-ignore.json'
            '{"Sources":[],"Packages":[{"PackageIdentifier":"Git.Git"}]}' | Out-File -FilePath $testFile -ErrorAction SilentlyContinue

            if (Get-Command Invoke-WithWideEvent -ErrorAction SilentlyContinue) {
                Set-Item -Path 'Function:\global:Invoke-WithWideEvent' -Value {
                    param(
                        [Parameter(Mandatory)]
                        [string]$OperationName,
                        [Parameter(Mandatory)]
                        [scriptblock]$ScriptBlock,
                        [hashtable]$Context = @{},
                        [string]$Level = 'INFO',
                        [switch]$AlwaysKeep
                    )
                    & $ScriptBlock
                } -Force
            }

            Setup-CapturingCommandMock -CommandName 'winget' -Output 'Packages imported'

            { Import-WingetPackages -Path $testFile -IgnoreUnavailable -Verbose 4>&1 | Out-Null } | Should -Not -Throw

            $capturedArgs = Get-TestCommandInvocationArgsFlat
            $capturedArgs | Should -Not -BeNullOrEmpty
            $capturedArgs | Should -Contain 'import'
            $capturedArgs | Should -Contain '--ignore-unavailable'
        }

        It 'Import-WingetPackages with IgnoreVersions passes --ignore-versions flag' {
            $testFile = Get-TestArtifactPath -FileName 'test-winget-packages-versions.json'
            '{"Sources":[],"Packages":[{"PackageIdentifier":"Git.Git"}]}' | Out-File -FilePath $testFile -ErrorAction SilentlyContinue

            if (Get-Command Invoke-WithWideEvent -ErrorAction SilentlyContinue) {
                Set-Item -Path 'Function:\global:Invoke-WithWideEvent' -Value {
                    param(
                        [Parameter(Mandatory)]
                        [string]$OperationName,
                        [Parameter(Mandatory)]
                        [scriptblock]$ScriptBlock,
                        [hashtable]$Context = @{},
                        [string]$Level = 'INFO',
                        [switch]$AlwaysKeep
                    )
                    & $ScriptBlock
                } -Force
            }

            Setup-CapturingCommandMock -CommandName 'winget' -Output 'Packages imported'

            { Import-WingetPackages -Path $testFile -IgnoreVersions -Verbose 4>&1 | Out-Null } | Should -Not -Throw

            $capturedArgs = Get-TestCommandInvocationArgsFlat
            $capturedArgs | Should -Not -BeNullOrEmpty
            $capturedArgs | Should -Contain 'import'
            $capturedArgs | Should -Contain '--ignore-versions'
        }
    }

    Context 'Graceful degradation when winget is unavailable' {
        BeforeAll {
            if ($global:CollectedMissingToolWarnings) {
                $global:CollectedMissingToolWarnings.Clear()
            }
            if ($global:MissingToolWarnings) {
                $global:MissingToolWarnings.Clear()
            }
            if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
                Clear-TestCachedCommandCache | Out-Null
            }

            @(
                'Install-WingetPackage', 'Remove-WingetPackage', 'Update-WingetPackages',
                'Test-WingetOutdated', 'Update-WingetSelf', 'Export-WingetPackages',
                'Import-WingetPackages'
            ) | ForEach-Object {
                Remove-Item "Function:$_" -ErrorAction SilentlyContinue
            }

            Remove-Item Function:winget -ErrorAction SilentlyContinue
            Remove-Item Function:global:winget -ErrorAction SilentlyContinue
            Set-TestCommandAvailabilityState -CommandName 'winget' -Available $false

            $script:MissingWingetOutput = & { . (Join-Path $script:ProfileDir 'winget.ps1') } 2>&1 3>&1 | Out-String
        }

        It 'Functions are not created when winget is unavailable' {
            Get-Command Install-WingetPackage -ErrorAction SilentlyContinue | Should -BeNullOrEmpty
        }

        It 'Emits missing-tool warning when winget is unavailable' {
            if (Get-Command Test-ToolAvailableOnPlatform -ErrorAction SilentlyContinue) {
                if (-not (Test-ToolAvailableOnPlatform -Tool 'winget')) {
                    Set-ItResult -Inconclusive -Because 'winget install hints are only emitted on Windows'
                    return
                }
            }

            Assert-TestMissingToolWarning -Output $script:MissingWingetOutput -Pattern 'winget not found'
            Assert-TestOutputContainsInstallCommand -Output $script:MissingWingetOutput -ToolName 'winget'
        }
    }
}
