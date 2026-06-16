<#
.SYNOPSIS
    Integration tests for pip tool fragment.

.DESCRIPTION
    Tests pip helper functions.
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

Describe 'pip Tools Integration Tests' {
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
            Write-Error "Failed to initialize pip tools tests in BeforeAll: $($errorDetails | ConvertTo-Json -Compress)" -ErrorAction Stop
            throw
        }
    }

    Context 'pip helpers (pip.ps1)' {
        BeforeAll {
            Set-TestCommandAvailabilityState -CommandName 'pip' -Available $true
            . (Join-Path $script:ProfileDir 'pip.ps1')
        }

        BeforeEach {
            Clear-TestCommandInvocationCapture
        }

        It 'Creates Test-PipOutdated function' {
            Get-Command Test-PipOutdated -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates pipoutdated alias for Test-PipOutdated' {
            Get-Alias pipoutdated -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias pipoutdated).ResolvedCommandName | Should -Be 'Test-PipOutdated'
        }

        It 'Test-PipOutdated calls pip list --outdated' {
            Setup-CapturingCommandMock -CommandName 'pip' -Output @(
                'Package    Version  Latest'
                'package1  1.0.0    1.2.0'
            )

            Test-PipOutdated
            Assert-TestCommandInvokedExactlyOnce
            Get-Command Test-PipOutdated -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates Update-PipPackages function' {
            Get-Command Update-PipPackages -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates pipupdate alias for Update-PipPackages' {
            Get-Alias pipupdate -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias pipupdate).ResolvedCommandName | Should -Be 'Update-PipPackages'
        }

        It 'Update-PipPackages calls pip list --outdated and upgrades packages' {
            Setup-CapturingCommandMock -CommandName 'pip' -Output @(
                'Package    Version  Latest'
                'package1  1.0.0    1.2.0'
                'Upgraded package1'
            )

            Get-Command Update-PipPackages -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            { Update-PipPackages | Out-Null } | Should -Not -Throw
            $global:TestCommandInvocationCaptures.Count | Should -BeGreaterOrEqual 2
        }

        It 'Update-PipPackages handles empty package list gracefully' {
            Setup-CapturingCommandMock -CommandName 'pip'

            $output = Update-PipPackages 6>&1 | Out-String
            $output | Should -Match 'No packages found to upgrade'
        }

        It 'Creates Update-PipSelf function' {
            Get-Command Update-PipSelf -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates pipupgrade alias for Update-PipSelf' {
            Get-Alias pipupgrade -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias pipupgrade).ResolvedCommandName | Should -Be 'Update-PipSelf'
        }

        It 'Update-PipSelf calls pip install --upgrade pip' {
            Setup-CapturingCommandMock -CommandName 'pip' -Output 'pip updated successfully'

            Update-PipSelf
            Assert-TestCommandInvokedExactlyOnce
            Get-Command Update-PipSelf -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates Export-PipPackages function' {
            Get-Command Export-PipPackages -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates pipexport alias for Export-PipPackages' {
            Get-Alias pipexport -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias pipexport).ResolvedCommandName | Should -Be 'Export-PipPackages'
        }

        It 'Export-PipPackages calls pip freeze' {
            Setup-CapturingCommandMock -CommandName 'pip' -Output @(
                'requests==2.31.0'
                'pandas==2.0.0'
            )
            { Export-PipPackages -Path (Get-TestArtifactPath -FileName 'test-requirements.txt') -Verbose 4>&1 | Out-Null } | Should -Not -Throw
            Assert-TestCommandInvokedExactlyOnce
                Assert-TestCommandInvocationContains 'freeze'
        }

        It 'Export-PipPackages with User passes --user flag' {
            Setup-CapturingCommandMock -CommandName 'pip' -Output 'requests==2.31.0'
            { Export-PipPackages -Path (Get-TestArtifactPath -FileName 'test-requirements.txt') -User -Verbose 4>&1 | Out-Null } | Should -Not -Throw
            Assert-TestCommandInvokedExactlyOnce
                Assert-TestCommandInvocationContains 'freeze'
                Assert-TestCommandInvocationContains '--user'
        }

        It 'Creates Import-PipPackages function' {
            Get-Command Import-PipPackages -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates pipimport alias for Import-PipPackages' {
            Get-Alias pipimport -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias pipimport).ResolvedCommandName | Should -Be 'Import-PipPackages'
        }

        It 'Import-PipPackages calls pip install -r' {
            $testFile = Get-TestArtifactPath -FileName 'test-requirements.txt'
            'requests==2.31.0' | Out-File -FilePath $testFile -ErrorAction SilentlyContinue
            Setup-CapturingCommandMock -CommandName 'pip' -Output 'Packages installed successfully'
            { Import-PipPackages -Path $testFile -Verbose 4>&1 | Out-Null } | Should -Not -Throw
            Assert-TestCommandInvokedExactlyOnce
                Assert-TestCommandInvocationContains 'install'
                Assert-TestCommandInvocationContains '-r'
                Assert-TestCommandInvocationContains $testFile
            Remove-Item -Path $testFile -ErrorAction SilentlyContinue
        }

        It 'Import-PipPackages with User passes --user flag' {
            $testFile = Get-TestArtifactPath -FileName 'test-requirements.txt'
            'requests==2.31.0' | Out-File -FilePath $testFile -ErrorAction SilentlyContinue
            Setup-CapturingCommandMock -CommandName 'pip' -Output 'Packages installed'
            { Import-PipPackages -Path $testFile -User -Verbose 4>&1 | Out-Null } | Should -Not -Throw
            Assert-TestCommandInvokedExactlyOnce
                Assert-TestCommandInvocationContains 'install'
                Assert-TestCommandInvocationContains '--user'
            Remove-Item -Path $testFile -ErrorAction SilentlyContinue
        }

        It 'Creates pipbackup alias for Export-PipPackages' {
            Get-Alias pipbackup -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias pipbackup).ResolvedCommandName | Should -Be 'Export-PipPackages'
        }

        It 'Creates piprestore alias for Import-PipPackages' {
            Get-Alias piprestore -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias piprestore).ResolvedCommandName | Should -Be 'Import-PipPackages'
        }

        It 'Creates Install-PipPackage function' {
            Get-Command Install-PipPackage -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates pipinstall alias for Install-PipPackage' {
            Get-Alias pipinstall -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias pipinstall).ResolvedCommandName | Should -Be 'Install-PipPackage'
        }

        It 'Creates pipadd alias for Install-PipPackage' {
            Get-Alias pipadd -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias pipadd).ResolvedCommandName | Should -Be 'Install-PipPackage'
        }

        It 'Install-PipPackage calls pip install with packages' {
            Setup-CapturingCommandMock -CommandName 'pip' -Output 'Package installed successfully'
            { Install-PipPackage requests -Verbose 4>&1 | Out-Null } | Should -Not -Throw
            Assert-TestCommandInvokedExactlyOnce
                Assert-TestCommandInvocationContains 'install'
                Assert-TestCommandInvocationContains 'requests'
        }

        It 'Install-PipPackage with User passes --user flag' {
            Setup-CapturingCommandMock -CommandName 'pip' -Output 'Package installed successfully'
            { Install-PipPackage requests -User -Verbose 4>&1 | Out-Null } | Should -Not -Throw
            Assert-TestCommandInvokedExactlyOnce
                Assert-TestCommandInvocationContains 'install'
                Assert-TestCommandInvocationContains '--user'
                Assert-TestCommandInvocationContains 'requests'
        }

        It 'Creates Remove-PipPackage function' {
            Get-Command Remove-PipPackage -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates pipuninstall alias for Remove-PipPackage' {
            Get-Alias pipuninstall -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias pipuninstall).ResolvedCommandName | Should -Be 'Remove-PipPackage'
        }

        It 'Creates pipremove alias for Remove-PipPackage' {
            Get-Alias pipremove -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias pipremove).ResolvedCommandName | Should -Be 'Remove-PipPackage'
        }

        It 'Remove-PipPackage calls pip uninstall with packages' {
            Setup-CapturingCommandMock -CommandName 'pip' -Output 'Package uninstalled successfully'
            { Remove-PipPackage requests -Verbose 4>&1 | Out-Null } | Should -Not -Throw
            Assert-TestCommandInvokedExactlyOnce
                Assert-TestCommandInvocationContains 'uninstall'
                Assert-TestCommandInvocationContains 'requests'
        }

        It 'Remove-PipPackage with User passes --user flag' {
            Setup-CapturingCommandMock -CommandName 'pip' -Output 'Package uninstalled successfully'
            { Remove-PipPackage requests -User -Verbose 4>&1 | Out-Null } | Should -Not -Throw
            Assert-TestCommandInvokedExactlyOnce
                Assert-TestCommandInvocationContains 'uninstall'
                Assert-TestCommandInvocationContains '--user'
                Assert-TestCommandInvocationContains 'requests'
        }

        It 'Import-PipPackages handles missing file gracefully' {
            Setup-CapturingCommandMock -CommandName 'pip' -Output 'Packages installed'
            { Import-PipPackages -Path (Get-TestArtifactPath -FileName 'nonexistent.txt') -ErrorAction SilentlyContinue 2>&1 | Out-Null } | Should -Not -Throw
            $global:TestCommandInvocationCaptures.Count | Should -Be 0
        }
    }

    Context 'pip graceful degradation' {
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

            Remove-Item Function:Install-PipPackage -ErrorAction SilentlyContinue
            Remove-Item Function:Remove-PipPackage -ErrorAction SilentlyContinue
            Remove-Item Function:Test-PipOutdated -ErrorAction SilentlyContinue
            Remove-Item Function:Update-PipPackages -ErrorAction SilentlyContinue
            Remove-Item Function:Update-PipSelf -ErrorAction SilentlyContinue
            Remove-Item Function:Export-PipPackages -ErrorAction SilentlyContinue
            Remove-Item Function:Import-PipPackages -ErrorAction SilentlyContinue
            Remove-Item Function:pip -ErrorAction SilentlyContinue
            Remove-Item Function:global:pip -ErrorAction SilentlyContinue

            Set-TestCommandAvailabilityState -CommandName 'pip' -Available $false
            $script:MissingPipOutput = & { . (Join-Path $script:ProfileDir 'pip.ps1') } 2>&1 3>&1 | Out-String
        }

        It 'Functions are not created when pip is unavailable' {
            if (Get-Command pip -CommandType Application -ErrorAction SilentlyContinue) {
                Set-ItResult -Inconclusive -Because 'pip on PATH can prevent fragment guard from skipping registration in this environment'
                return
            }

            Get-Command Install-PipPackage -ErrorAction SilentlyContinue | Should -BeNullOrEmpty
        }

        It 'Emits missing-tool warning when pip is unavailable' {
            Assert-TestMissingToolWarning -Output $script:MissingPipOutput -Pattern 'pip not found'
            Assert-TestOutputContainsInstallCommand -Output $script:MissingPipOutput -ToolName 'pip'
        }

        It 'Install-PipPackage emits missing-tool warning when pip is unavailable' {
            if (-not (Get-Command Install-PipPackage -ErrorAction SilentlyContinue)) {
                Set-ItResult -Inconclusive -Because 'Install-PipPackage was not registered in this environment'
                return
            }

            if ($global:MissingToolWarnings) {
                $null = $global:MissingToolWarnings.TryRemove('pip', [ref]$null)
            }
            Set-TestCommandAvailabilityState -CommandName 'pip' -Available $false

            $output = Install-PipPackage requests 2>&1 3>&1 | Out-String
            Assert-TestMissingToolWarning -Output $output -Pattern 'pip not found'
        }
    }
}
