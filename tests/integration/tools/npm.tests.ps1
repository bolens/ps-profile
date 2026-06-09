<#
.SYNOPSIS
    Integration tests for npm tool fragment.

.DESCRIPTION
    Tests npm helper functions.
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

Describe 'npm Tools Integration Tests' {
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
        Write-Error "Failed to initialize npm tools tests in BeforeAll: $($errorDetails | ConvertTo-Json -Compress)" -ErrorAction Stop
        throw
    }

    Context 'npm helpers (npm.ps1)' {
        BeforeAll {
            Set-TestCommandAvailabilityState -CommandName 'npm' -Available $true
            . (Join-Path $script:ProfileDir 'npm.ps1')
        }

        BeforeEach {
            Clear-TestCommandInvocationCapture
        }

        It 'Creates Test-NpmOutdated function' {
            Get-Command Test-NpmOutdated -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates npmoutdated alias for Test-NpmOutdated' {
            Get-Alias npmoutdated -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias npmoutdated).ResolvedCommandName | Should -Be 'Test-NpmOutdated'
        }

        It 'Test-NpmOutdated calls npm outdated' {
            Setup-CapturingCommandMock -CommandName 'npm' -Output @(
                'Package    Current  Wanted  Latest'
                'package1  1.0.0    1.1.0   1.2.0'
            )

            Test-NpmOutdated
            Assert-TestCommandInvokedExactlyOnce
            Get-Command Test-NpmOutdated -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates Update-NpmPackages function' {
            Get-Command Update-NpmPackages -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates npmupdate alias for Update-NpmPackages' {
            Get-Alias npmupdate -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias npmupdate).ResolvedCommandName | Should -Be 'Update-NpmPackages'
        }

        It 'Update-NpmPackages calls npm update' {
            Setup-CapturingCommandMock -CommandName 'npm' -Output 'Packages updated successfully'

            Update-NpmPackages
            Assert-TestCommandInvokedExactlyOnce
            Get-Command Update-NpmPackages -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates Update-NpmSelf function' {
            Get-Command Update-NpmSelf -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates npmupgrade alias for Update-NpmSelf' {
            Get-Alias npmupgrade -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias npmupgrade).ResolvedCommandName | Should -Be 'Update-NpmSelf'
        }

        It 'Update-NpmSelf calls npm install -g npm@latest' {
            Setup-CapturingCommandMock -CommandName 'npm' -Output 'npm updated successfully'

            Update-NpmSelf
            Assert-TestCommandInvokedExactlyOnce
            Get-Command Update-NpmSelf -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates Export-NpmGlobalPackages function' {
            Get-Command Export-NpmGlobalPackages -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates npmexport alias for Export-NpmGlobalPackages' {
            Get-Alias npmexport -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias npmexport).ResolvedCommandName | Should -Be 'Export-NpmGlobalPackages'
        }

        It 'Export-NpmGlobalPackages calls npm list -g --depth=0 --json' {
            $mockJson = @{
                dependencies = @{
                    'typescript' = @{ version = '5.0.0' }
                    'nodemon'    = @{ version = '2.0.0' }
                }
            } | ConvertTo-Json -Depth 10

            Setup-CapturingCommandMock -CommandName 'npm'

            { Export-NpmGlobalPackages -Path (Get-TestArtifactPath -FileName 'test-npm-global.json') -Verbose 4>&1 | Out-Null } | Should -Not -Throw
            Assert-TestCommandInvokedExactlyOnce
        }

        It 'Creates Import-NpmGlobalPackages function' {
            Get-Command Import-NpmGlobalPackages -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates npmimport alias for Import-NpmGlobalPackages' {
            Get-Alias npmimport -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias npmimport).ResolvedCommandName | Should -Be 'Import-NpmGlobalPackages'
        }

        It 'Import-NpmGlobalPackages calls npm install -g for each package' {
            $testFile = Get-TestArtifactPath -FileName 'test-npm-global.json'
            '{"dependencies": {"typescript": "5.0.0", "nodemon": "2.0.0"}}' | Out-File -FilePath $testFile -ErrorAction SilentlyContinue
            
            Setup-CapturingCommandMock -CommandName 'npm' -Output 'Package installed successfully'
            { Import-NpmGlobalPackages -Path $testFile -Verbose 4>&1 | Out-Null } | Should -Not -Throw
            $global:TestCommandInvocationCaptures.Count | Should -Be 2

            Remove-Item -Path $testFile -ErrorAction SilentlyContinue
        }

        It 'Creates npmbackup alias for Export-NpmGlobalPackages' {
            Get-Alias npmbackup -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias npmbackup).ResolvedCommandName | Should -Be 'Export-NpmGlobalPackages'
        }

        It 'Creates npmrestore alias for Import-NpmGlobalPackages' {
            Get-Alias npmrestore -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias npmrestore).ResolvedCommandName | Should -Be 'Import-NpmGlobalPackages'
        }

        It 'Creates Install-NpmPackage function' {
            Get-Command Install-NpmPackage -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates npminstall alias for Install-NpmPackage' {
            Get-Alias npminstall -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias npminstall).ResolvedCommandName | Should -Be 'Install-NpmPackage'
        }

        It 'Creates npmadd alias for Install-NpmPackage' {
            Get-Alias npmadd -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias npmadd).ResolvedCommandName | Should -Be 'Install-NpmPackage'
        }

        It 'Install-NpmPackage calls npm install with packages' {
            Setup-CapturingCommandMock -CommandName 'npm' -Output 'Package installed successfully'
            { Install-NpmPackage express -Verbose 4>&1 | Out-Null } | Should -Not -Throw
            Assert-TestCommandInvokedExactlyOnce
                Assert-TestCommandInvocationContains 'install'
                Assert-TestCommandInvocationContains 'express'
        }

        It 'Install-NpmPackage with Dev passes --save-dev flag' {
            Setup-CapturingCommandMock -CommandName 'npm' -Output 'Package installed successfully'
            { Install-NpmPackage typescript -Dev -Verbose 4>&1 | Out-Null } | Should -Not -Throw
            Assert-TestCommandInvokedExactlyOnce
                Assert-TestCommandInvocationContains 'install'
                Assert-TestCommandInvocationContains '--save-dev'
                Assert-TestCommandInvocationContains 'typescript'
        }

        It 'Install-NpmPackage with Global passes --global flag' {
            Setup-CapturingCommandMock -CommandName 'npm' -Output 'Package installed successfully'
            { Install-NpmPackage nodemon -Global -Verbose 4>&1 | Out-Null } | Should -Not -Throw
            Assert-TestCommandInvokedExactlyOnce
                Assert-TestCommandInvocationContains 'install'
                Assert-TestCommandInvocationContains '--global'
                Assert-TestCommandInvocationContains 'nodemon'
        }

        It 'Install-NpmPackage with Prod passes --save-prod flag' {
            Setup-CapturingCommandMock -CommandName 'npm' -Output 'Package installed successfully'
            { Install-NpmPackage express -Prod -Verbose 4>&1 | Out-Null } | Should -Not -Throw
            Assert-TestCommandInvokedExactlyOnce
                Assert-TestCommandInvocationContains 'install'
                Assert-TestCommandInvocationContains '--save-prod'
                Assert-TestCommandInvocationContains 'express'
        }

        It 'Creates Remove-NpmPackage function' {
            Get-Command Remove-NpmPackage -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates npmuninstall alias for Remove-NpmPackage' {
            Get-Alias npmuninstall -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias npmuninstall).ResolvedCommandName | Should -Be 'Remove-NpmPackage'
        }

        It 'Creates npmremove alias for Remove-NpmPackage' {
            Get-Alias npmremove -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias npmremove).ResolvedCommandName | Should -Be 'Remove-NpmPackage'
        }

        It 'Remove-NpmPackage calls npm uninstall with packages' {
            Setup-CapturingCommandMock -CommandName 'npm' -Output 'Package uninstalled successfully'
            { Remove-NpmPackage express -Verbose 4>&1 | Out-Null } | Should -Not -Throw
            Assert-TestCommandInvokedExactlyOnce
                Assert-TestCommandInvocationContains 'uninstall'
                Assert-TestCommandInvocationContains 'express'
        }

        It 'Remove-NpmPackage with Dev passes --save-dev flag' {
            Setup-CapturingCommandMock -CommandName 'npm' -Output 'Package uninstalled successfully'
            { Remove-NpmPackage typescript -Dev -Verbose 4>&1 | Out-Null } | Should -Not -Throw
            Assert-TestCommandInvokedExactlyOnce
                Assert-TestCommandInvocationContains 'uninstall'
                Assert-TestCommandInvocationContains '--save-dev'
                Assert-TestCommandInvocationContains 'typescript'
        }

        It 'Remove-NpmPackage with Global passes --global flag' {
            Setup-CapturingCommandMock -CommandName 'npm' -Output 'Package uninstalled successfully'
            { Remove-NpmPackage nodemon -Global -Verbose 4>&1 | Out-Null } | Should -Not -Throw
            Assert-TestCommandInvokedExactlyOnce
                Assert-TestCommandInvocationContains 'uninstall'
                Assert-TestCommandInvocationContains '--global'
                Assert-TestCommandInvocationContains 'nodemon'
        }

        It 'Remove-NpmPackage with Prod passes --save-prod flag' {
            Setup-CapturingCommandMock -CommandName 'npm' -Output 'Package uninstalled successfully'
            { Remove-NpmPackage express -Prod -Verbose 4>&1 | Out-Null } | Should -Not -Throw
            Assert-TestCommandInvokedExactlyOnce
                Assert-TestCommandInvocationContains 'uninstall'
                Assert-TestCommandInvocationContains '--save-prod'
                Assert-TestCommandInvocationContains 'express'
        }

        It 'Export-NpmGlobalPackages handles no dependencies gracefully' {
            $mockJson = @{} | ConvertTo-Json -Depth 10

            Setup-CapturingCommandMock -CommandName 'npm'

            { Export-NpmGlobalPackages -Path (Get-TestArtifactPath -FileName 'test-npm-global-empty.json') -Verbose 4>&1 | Out-Null } | Should -Not -Throw
            Assert-TestCommandInvokedExactlyOnce
        }

        It 'Import-NpmGlobalPackages handles missing file gracefully' {
            Setup-CapturingCommandMock -CommandName 'npm' -Output 'Package installed successfully'
            { Import-NpmGlobalPackages -Path (Get-TestArtifactPath -FileName 'nonexistent.json') -ErrorAction SilentlyContinue 2>&1 | Out-Null } | Should -Not -Throw
            $global:TestCommandInvocationCaptures.Count | Should -Be 0
        }
    }

    Context 'npm graceful degradation' {
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
            if (Get-Variable -Name 'TestCachedCommandCache' -Scope Global -ErrorAction SilentlyContinue) {
                $null = $global:TestCachedCommandCache.TryRemove('npm', [ref]$null)
                $null = $global:TestCachedCommandCache.TryRemove('NPM', [ref]$null)
            }
            if (Get-Variable -Name 'AssumedAvailableCommands' -Scope Global -ErrorAction SilentlyContinue) {
                $global:AssumedAvailableCommands = $global:AssumedAvailableCommands | Where-Object { $_ -ne 'npm' -and $_ -ne 'NPM' }
            }

            # Remove functions/aliases from previous context
            Remove-Item Function:Install-NpmPackage -ErrorAction SilentlyContinue
            Remove-Item Function:Remove-NpmPackage -ErrorAction SilentlyContinue
            Remove-Item Function:Test-NpmOutdated -ErrorAction SilentlyContinue
            Remove-Item Function:Update-NpmPackages -ErrorAction SilentlyContinue
            Remove-Item Function:Update-NpmSelf -ErrorAction SilentlyContinue
            Remove-Item Function:Export-NpmGlobalPackages -ErrorAction SilentlyContinue
            Remove-Item Function:Import-NpmGlobalPackages -ErrorAction SilentlyContinue
            Remove-Item Alias:npminstall -ErrorAction SilentlyContinue
            Remove-Item Alias:npmadd -ErrorAction SilentlyContinue
            Remove-Item Alias:npmuninstall -ErrorAction SilentlyContinue
            Remove-Item Alias:npmremove -ErrorAction SilentlyContinue
            Remove-Item Alias:npmoutdated -ErrorAction SilentlyContinue
            Remove-Item Alias:npmupdate -ErrorAction SilentlyContinue
            Remove-Item Alias:npmupgrade -ErrorAction SilentlyContinue
            Remove-Item Alias:npmexport -ErrorAction SilentlyContinue
            Remove-Item Alias:npmbackup -ErrorAction SilentlyContinue
            Remove-Item Alias:npmimport -ErrorAction SilentlyContinue
            Remove-Item Alias:npmrestore -ErrorAction SilentlyContinue

            Remove-Item Function:npm -ErrorAction SilentlyContinue
            Remove-Item Function:global:npm -ErrorAction SilentlyContinue
            Set-TestCommandAvailabilityState -CommandName 'npm' -Available $false

            $script:MissingNpmOutput = & { . (Join-Path $script:ProfileDir 'npm.ps1') } 2>&1 3>&1 | Out-String
        }

        It 'Functions are not created when npm is unavailable' {
            Get-Command Install-NpmPackage -ErrorAction SilentlyContinue | Should -BeNullOrEmpty
        }

        It 'Emits missing-tool warning when npm is unavailable' {
            Assert-TestMissingToolWarning -Output $script:MissingNpmOutput -Pattern 'npm not found'
            Assert-TestOutputContainsInstallCommand -Output $script:MissingNpmOutput -ToolName 'npm'
        }
    }
}
