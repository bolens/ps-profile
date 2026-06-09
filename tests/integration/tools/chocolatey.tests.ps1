<#
.SYNOPSIS
    Integration tests for Chocolatey tool fragment.

.DESCRIPTION
    Tests Chocolatey helper functions.
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

Describe 'Chocolatey Tools Integration Tests' {
    BeforeAll {
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

    Context 'Chocolatey helpers (chocolatey.ps1)' {
        BeforeAll {
            Set-TestCommandAvailabilityState -CommandName 'choco' -Available $true
            . (Join-Path $script:ProfileDir 'chocolatey.ps1')
        }

        BeforeEach {
            Clear-TestCommandInvocationCapture
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
            Setup-CapturingCommandMock -CommandName 'choco' -Output 'Package installed successfully'
            # Execute
            { Install-ChocoPackage -Packages git 4>&1 | Out-Null } | Should -Not -Throw

            # Verify
            Assert-TestCommandInvokedExactlyOnce
            Assert-TestCommandInvocationContains 'install'
            Assert-TestCommandInvocationContains 'git'
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
            Setup-CapturingCommandMock -CommandName 'choco' -Output 'Package removed successfully'
            # Execute
            { Remove-ChocoPackage -Packages git 4>&1 | Out-Null } | Should -Not -Throw

            # Verify
            Assert-TestCommandInvokedExactlyOnce
            Assert-TestCommandInvocationContains 'uninstall'
            Assert-TestCommandInvocationContains 'git'
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
            Setup-CapturingCommandMock -CommandName 'choco' -Output 'package1|1.0.0|1.2.0'
            # Execute
            { Test-ChocoOutdated -Verbose 4>&1 | Out-Null } | Should -Not -Throw

            # Verify
            Assert-TestCommandInvokedExactlyOnce
            Assert-TestCommandInvocationContains 'outdated'
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
            Setup-CapturingCommandMock -CommandName 'choco' -Output 'All packages upgraded successfully'
            # Execute
            { Update-ChocoPackages -Verbose 4>&1 | Out-Null } | Should -Not -Throw

            # Verify
            Assert-TestCommandInvokedExactlyOnce
            Assert-TestCommandInvocationContains 'upgrade'
            Assert-TestCommandInvocationContains 'all'
        }

        It 'Update-ChocoPackages calls choco upgrade for specific packages' {
            # Capture arguments using the direct pattern
            Setup-CapturingCommandMock -CommandName 'choco' -Output 'git upgraded successfully'
            # Execute
            { Update-ChocoPackages -Packages git -Verbose 4>&1 | Out-Null } | Should -Not -Throw

            # Verify
            Assert-TestCommandInvokedExactlyOnce
            Assert-TestCommandInvocationContains 'upgrade'
            Assert-TestCommandInvocationContains 'git'
            Get-TestCommandInvocationArgsFlat | Should -Not -Contain 'all'
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
            Setup-CapturingCommandMock -CommandName 'choco' -Output 'Chocolatey updated successfully'
            # Execute
            { Update-ChocoSelf -Verbose 4>&1 | Out-Null } | Should -Not -Throw

            # Verify
            Assert-TestCommandInvokedExactlyOnce
            Assert-TestCommandInvocationContains 'upgrade'
            Assert-TestCommandInvocationContains 'chocolatey'
            Assert-TestCommandInvocationContains '-y'
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
            Setup-CapturingCommandMock -CommandName 'choco' -Output 'Cache cleaned successfully'
            # Execute
            { Clear-ChocoCache -Verbose 4>&1 | Out-Null } | Should -Not -Throw

            # Verify
            Assert-TestCommandInvokedExactlyOnce
            Assert-TestCommandInvocationContains 'clean'
        }

        It 'Clear-ChocoCache with Yes passes -y flag' {
            Setup-CapturingCommandMock -CommandName 'choco' -Output 'Cache cleaned successfully'
            # Execute
            { Clear-ChocoCache -Yes -Verbose 4>&1 | Out-Null } | Should -Not -Throw

            # Verify
            Assert-TestCommandInvokedExactlyOnce
            Assert-TestCommandInvocationContains 'clean'
            Assert-TestCommandInvocationContains '-y'
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
            Setup-CapturingCommandMock -CommandName 'choco' -Output 'git|2.40.0'
            # Execute
            { Find-ChocoPackage -Query git -Verbose 4>&1 | Out-Null } | Should -Not -Throw

            # Verify
            Assert-TestCommandInvokedExactlyOnce
            Assert-TestCommandInvocationContains 'search'
            Assert-TestCommandInvocationContains 'git'
        }

        It 'Find-ChocoPackage with Exact passes --exact flag' {
            Setup-CapturingCommandMock -CommandName 'choco' -Output 'git|2.40.0'
            # Execute
            { Find-ChocoPackage -Query git -Exact -Verbose 4>&1 | Out-Null } | Should -Not -Throw

            # Verify
            Assert-TestCommandInvokedExactlyOnce
            Assert-TestCommandInvocationContains 'search'
            Assert-TestCommandInvocationContains '--exact'
            Assert-TestCommandInvocationContains 'git'
        }

        It 'Creates Get-ChocoPackage function' {
            Get-Command Get-ChocoPackage -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates cholist alias for Get-ChocoPackage' {
            Get-Alias cholist -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias cholist).ResolvedCommandName | Should -Be 'Get-ChocoPackage'
        }

        It 'Get-ChocoPackage calls choco list --local-only' {
            Setup-CapturingCommandMock -CommandName 'choco' -Output 'git|2.40.0'
            # Execute
            { Get-ChocoPackage -Verbose 4>&1 | Out-Null } | Should -Not -Throw

            # Verify
            Assert-TestCommandInvokedExactlyOnce
            Assert-TestCommandInvocationContains 'list'
            Assert-TestCommandInvocationContains '--local-only'
        }

        It 'Get-ChocoPackage with IncludePrograms calls choco list' {
            Setup-CapturingCommandMock -CommandName 'choco' -Output 'git|2.40.0'
            # Execute
            { Get-ChocoPackage -IncludePrograms -Verbose 4>&1 | Out-Null } | Should -Not -Throw

            # Verify
            Assert-TestCommandInvokedExactlyOnce
            Assert-TestCommandInvocationContains 'list'
            Get-TestCommandInvocationArgsFlat | Should -Not -Contain '--local-only'
        }

        It 'Creates Get-ChocoPackageInfo function' {
            Get-Command Get-ChocoPackageInfo -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates choinfo alias for Get-ChocoPackageInfo' {
            Get-Alias choinfo -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias choinfo).ResolvedCommandName | Should -Be 'Get-ChocoPackageInfo'
        }

        It 'Get-ChocoPackageInfo calls choco info' {
            Setup-CapturingCommandMock -CommandName 'choco' -Output @(
                'Chocolatey v2.0.0'
                'git 2.40.0'
            )
            # Execute
            { Get-ChocoPackageInfo -Packages git -Verbose 4>&1 | Out-Null } | Should -Not -Throw

            # Verify
            Assert-TestCommandInvokedExactlyOnce
            Assert-TestCommandInvocationContains 'info'
            Assert-TestCommandInvocationContains 'git'
        }

        It 'Get-ChocoPackageInfo with Source passes --source flag' {
            Setup-CapturingCommandMock -CommandName 'choco' -Output 'git 2.40.0'
            # Execute
            { Get-ChocoPackageInfo -Packages git -Source chocolatey -Verbose 4>&1 | Out-Null } | Should -Not -Throw

            # Verify
            Assert-TestCommandInvokedExactlyOnce
            Assert-TestCommandInvocationContains 'info'
            Assert-TestCommandInvocationContains '--source'
            Assert-TestCommandInvocationContains 'chocolatey'
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
            Setup-CapturingCommandMock -CommandName 'choco' -Output 'Packages exported successfully'
            $testPath = Get-TestArtifactPath -FileName 'test-packages.config'

            # Execute
            { Export-ChocoPackages -Path $testPath -Verbose 4>&1 | Out-Null } | Should -Not -Throw

            # Verify
            Assert-TestCommandInvokedExactlyOnce
            Assert-TestCommandInvocationContains 'export'
            Assert-TestCommandInvocationContains '-o'
            Assert-TestCommandInvocationContains $testPath
        }

        It 'Export-ChocoPackages with IncludeVersions passes --include-version-numbers flag' {
            Setup-CapturingCommandMock -CommandName 'choco' -Output 'Packages exported with versions'
            # Execute
            { Export-ChocoPackages -Path (Get-TestArtifactPath -FileName 'test-packages.config') -IncludeVersions -Verbose 4>&1 | Out-Null } | Should -Not -Throw

            # Verify
            Assert-TestCommandInvokedExactlyOnce
            Assert-TestCommandInvocationContains 'export'
            Assert-TestCommandInvocationContains '--include-version-numbers'
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
            if (-not $IsWindows) {
                Set-ItResult -Inconclusive -Because 'Chocolatey import invokes choco through Invoke-WithWideEvent; validated on Windows CI'
                return
            }

            $testDir = New-TestTempDirectory -Prefix 'ChocoImport'
            $testFile = Join-Path $testDir 'test-packages.config'
            '<?xml version="1.0"?><packages><package id="git" /></packages>' | Set-Content -Path $testFile
            Test-Path -LiteralPath $testFile | Should -Be $true

            Setup-CapturingCommandMock -CommandName 'choco' -Output 'Packages imported successfully'

            { Import-ChocoPackages -Path $testFile -Verbose 4>&1 | Out-Null } | Should -Not -Throw

            Assert-TestCommandInvokedExactlyOnce -ParameterFilter {
                $flatArgs = [System.Collections.Generic.List[object]]::new()
                foreach ($arg in $args) {
                    if ($arg -is [System.Array]) {
                        foreach ($nestedArg in $arg) {
                            $flatArgs.Add($nestedArg)
                        }
                    }
                    else {
                        $flatArgs.Add($arg)
                    }
                }
                ($flatArgs -contains 'install') -and ($flatArgs -contains $testFile)
            }
        }

        It 'Import-ChocoPackages with Yes passes -y flag' {
            if (-not $IsWindows) {
                Set-ItResult -Inconclusive -Because 'Chocolatey import invokes choco through Invoke-WithWideEvent; validated on Windows CI'
                return
            }

            $testDir = New-TestTempDirectory -Prefix 'ChocoImportYes'
            $testFile = Join-Path $testDir 'test-packages-yes.config'
            '<?xml version="1.0"?><packages><package id="git" /></packages>' | Set-Content -Path $testFile
            Test-Path -LiteralPath $testFile | Should -Be $true

            Setup-CapturingCommandMock -CommandName 'choco' -Output 'Packages imported successfully'

            { Import-ChocoPackages -Path $testFile -Yes -Verbose 4>&1 | Out-Null } | Should -Not -Throw

            Assert-TestCommandInvokedExactlyOnce -ParameterFilter {
                $flatArgs = [System.Collections.Generic.List[object]]::new()
                foreach ($arg in $args) {
                    if ($arg -is [System.Array]) {
                        foreach ($nestedArg in $arg) {
                            $flatArgs.Add($nestedArg)
                        }
                    }
                    else {
                        $flatArgs.Add($arg)
                    }
                }
                ($flatArgs -contains 'install') -and ($flatArgs -contains '-y')
            }
        }

    }

    Context 'Graceful degradation when choco is unavailable' {
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
            Remove-Item Function:choco -ErrorAction SilentlyContinue
            Remove-Item Function:global:choco -ErrorAction SilentlyContinue
            Set-TestCommandAvailabilityState -CommandName 'choco' -Available $false

            @(
                'Install-ChocoPackage', 'Remove-ChocoPackage', 'Update-ChocoPackages',
                'Test-ChocoOutdated', 'Update-ChocoSelf', 'Clear-ChocoCache',
                'Find-ChocoPackage', 'Get-ChocoPackage', 'Get-ChocoPackageInfo',
                'Export-ChocoPackages', 'Import-ChocoPackages'
            ) | ForEach-Object {
                Remove-Item "Function:$_" -ErrorAction SilentlyContinue
            }

            $output = & { . (Join-Path $script:ProfileDir 'chocolatey.ps1') } 2>&1 3>&1 | Out-String
            $script:MissingChocoOutput = $output
        }

        It 'Functions are not created when choco is unavailable' {
            Get-Command Install-ChocoPackage -ErrorAction SilentlyContinue | Should -BeNullOrEmpty
        }

        It 'Emits missing-tool warning when choco is unavailable' {
            if (Get-Command Test-ToolAvailableOnPlatform -ErrorAction SilentlyContinue) {
                if (-not (Test-ToolAvailableOnPlatform -Tool 'chocolatey')) {
                    Set-ItResult -Inconclusive -Because 'Chocolatey install hints are only emitted on Windows'
                    return
                }
            }

            Assert-TestMissingToolWarning -Output $script:MissingChocoOutput -Pattern 'choco not found'
            Assert-TestOutputContainsInstallCommand -Output $script:MissingChocoOutput -ToolName 'chocolatey'
        }
    }
}
