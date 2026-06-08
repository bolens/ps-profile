<#
.SYNOPSIS
    Integration tests for uv tool fragment.

.DESCRIPTION
    Tests uv helper functions.
    These tests verify that functions are created correctly and handle
    missing tools gracefully.
#>

BeforeAll {
    . (Join-Path $PSScriptRoot '..\..\TestSupport.ps1')
}

Describe 'uv Tools Integration Tests' {
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
            Write-Error "Failed to initialize uv tools tests in BeforeAll: $($errorDetails | ConvertTo-Json -Compress)" -ErrorAction Stop
            throw
        }
    }

    Context 'uv helpers (uv.ps1)' {
        BeforeAll {
            # Set-TestCommandAvailabilityState handles Test-CachedCommand mocking internally
            Set-TestCommandAvailabilityState -CommandName 'uv' -Available $true
            . (Join-Path $script:ProfileDir 'uv.ps1')
        }

        BeforeEach {
            Clear-TestCommandInvocationCapture
        }

        It 'Creates Invoke-Pip function' {
            Get-Command Invoke-Pip -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates pip alias for Invoke-Pip' {
            $pipAlias = Get-Alias -Name 'pip' -ErrorAction SilentlyContinue
            if ($pipAlias) {
                $pipAlias.ResolvedCommandName | Should -Be 'Invoke-Pip'
                return
            }

            Get-Command -Name 'Invoke-Pip' -Scope Global -ErrorAction SilentlyContinue |
                Should -Not -BeNullOrEmpty
        }

        It 'Invoke-Pip calls uv pip with arguments' {
            Setup-CapturingCommandMock -CommandName 'uv' -Output 'Package installed successfully'
            { Invoke-Pip install requests -Verbose 4>&1 | Out-Null } | Should -Not -Throw
            Assert-TestCommandInvokedExactlyOnce
                Assert-TestCommandInvocationContains 'pip'
                Assert-TestCommandInvocationContains 'install'
                Assert-TestCommandInvocationContains 'requests'
        }

        It 'Creates Invoke-UVRun function' {
            Get-Command Invoke-UVRun -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates uvrun alias for Invoke-UVRun' {
            Get-Alias uvrun -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias uvrun).ResolvedCommandName | Should -Be 'Invoke-UVRun'
        }

        It 'Invoke-UVRun calls uv run with command and args' {
            Setup-CapturingCommandMock -CommandName 'uv' -Output 'Command executed successfully'
            { Invoke-UVRun -Command 'python' -Args @('--version') -Verbose 4>&1 | Out-Null } | Should -Not -Throw
            Assert-TestCommandInvokedExactlyOnce
                Assert-TestCommandInvocationContains 'run'
                Assert-TestCommandInvocationContains 'python'
        }

        It 'Creates Install-UVTool function' {
            Get-Command Install-UVTool -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates uvtool alias for Install-UVTool' {
            Get-Alias uvtool -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias uvtool).ResolvedCommandName | Should -Be 'Install-UVTool'
        }

        It 'Install-UVTool calls uv tool install with package' {
            Setup-CapturingCommandMock -CommandName 'uv' -Output 'Tool installed successfully'
            { Install-UVTool -Package 'black' -Verbose 4>&1 | Out-Null } | Should -Not -Throw
            Assert-TestCommandInvokedExactlyOnce
                Assert-TestCommandInvocationContains 'tool'
                Assert-TestCommandInvocationContains 'install'
                Assert-TestCommandInvocationContains 'black'
        }

        It 'Creates New-UVVenv function' {
            Get-Command New-UVVenv -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates uvvenv alias for New-UVVenv' {
            Get-Alias uvvenv -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias uvvenv).ResolvedCommandName | Should -Be 'New-UVVenv'
        }

        It 'New-UVVenv calls uv venv with path' {
            Setup-CapturingCommandMock -CommandName 'uv' -Output 'Virtual environment created successfully'
            { New-UVVenv -Path '.venv' -Verbose 4>&1 | Out-Null } | Should -Not -Throw
            Assert-TestCommandInvokedExactlyOnce
                Assert-TestCommandInvocationContains 'venv'
                Assert-TestCommandInvocationContains '.venv'
        }

        It 'New-UVVenv uses default path when not specified' {
            Setup-CapturingCommandMock -CommandName 'uv' -Output 'Virtual environment created successfully'
            { New-UVVenv -Verbose 4>&1 | Out-Null } | Should -Not -Throw
            Assert-TestCommandInvokedExactlyOnce
                Assert-TestCommandInvocationContains 'venv'
                Assert-TestCommandInvocationContains '.venv'
        }

        It 'Creates Update-UVOutdatedPackages function' {
            Get-Command Update-UVOutdatedPackages -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates uvupgrade alias for Update-UVOutdatedPackages' {
            Get-Alias uvupgrade -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias uvupgrade).ResolvedCommandName | Should -Be 'Update-UVOutdatedPackages'
        }

        It 'Update-UVOutdatedPackages calls uv pip list --outdated and upgrades packages' {
            Setup-CapturingCommandMock -CommandName 'uv' -Output @(
                'Package    Version  Latest'
                'package1   1.0.0    1.1.0'
                'Upgraded package1'
            )

            Get-Command Update-UVOutdatedPackages -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            { Update-UVOutdatedPackages | Out-Null } | Should -Not -Throw
            $global:TestCommandInvocationCaptures.Count | Should -BeGreaterOrEqual 2
        }

        It 'Update-UVOutdatedPackages handles empty package list gracefully' {
            Setup-CapturingCommandMock -CommandName 'uv'

            $output = Update-UVOutdatedPackages 6>&1 | Out-String
            $output | Should -Match 'No packages found to upgrade'
        }

        It 'Creates Update-UVTools function' {
            Get-Command Update-UVTools -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates uvtoolupgrade alias for Update-UVTools' {
            Get-Alias uvtoolupgrade -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias uvtoolupgrade).ResolvedCommandName | Should -Be 'Update-UVTools'
        }

        It 'Update-UVTools calls uv tool upgrade --all' {
            Setup-CapturingCommandMock -CommandName 'uv' -Output 'All tools upgraded successfully'

            { Update-UVTools -Verbose 4>&1 | Out-Null } | Should -Not -Throw
            Assert-TestCommandInvokedExactlyOnce
            Assert-TestCommandInvocationContains 'tool'
            Assert-TestCommandInvocationContains 'upgrade'
            Assert-TestCommandInvocationContains '--all'
        }

        It 'Creates Invoke-UVTool function' {
            Get-Command Invoke-UVTool -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates uvx alias for Invoke-UVTool' {
            $uvxAlias = Get-Alias -Name 'uvx' -ErrorAction SilentlyContinue
            if ($uvxAlias) {
                $uvxAlias.ResolvedCommandName | Should -Be 'Invoke-UVTool'
                return
            }

            Get-Command -Name 'Invoke-UVTool' -Scope Global -ErrorAction SilentlyContinue |
                Should -Not -BeNullOrEmpty
        }

        It 'Invoke-UVTool calls uv tool run with arguments' {
            Setup-CapturingCommandMock -CommandName 'uv' -Output 'Tool executed successfully'
            { Invoke-UVTool black --version -Verbose 4>&1 | Out-Null } | Should -Not -Throw
            Assert-TestCommandInvokedExactlyOnce
                Assert-TestCommandInvocationContains 'tool'
                Assert-TestCommandInvocationContains 'run'
                Assert-TestCommandInvocationContains 'black'
        }

        It 'Creates Add-UVDependency function' {
            Get-Command Add-UVDependency -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates uva alias for Add-UVDependency' {
            Get-Alias uva -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias uva).ResolvedCommandName | Should -Be 'Add-UVDependency'
        }

        It 'Add-UVDependency calls uv add with arguments' {
            Setup-CapturingCommandMock -CommandName 'uv' -Output 'Dependency added successfully'
            { Add-UVDependency requests -Verbose 4>&1 | Out-Null } | Should -Not -Throw
            Assert-TestCommandInvokedExactlyOnce
                Assert-TestCommandInvocationContains 'add'
                Assert-TestCommandInvocationContains 'requests'
        }

        It 'Creates Sync-UVDependencies function' {
            Get-Command Sync-UVDependencies -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates uvs alias for Sync-UVDependencies' {
            Get-Alias uvs -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias uvs).ResolvedCommandName | Should -Be 'Sync-UVDependencies'
        }

        It 'Sync-UVDependencies calls uv sync with arguments' {
            Setup-CapturingCommandMock -CommandName 'uv' -Output 'Dependencies synced successfully'
            { Sync-UVDependencies -Verbose 4>&1 | Out-Null } | Should -Not -Throw
            Assert-TestCommandInvokedExactlyOnce
                Assert-TestCommandInvocationContains 'sync'
        }
    }

    Context 'Graceful degradation' {
        BeforeEach {
            if ($global:MissingToolWarnings) {
                $null = $global:MissingToolWarnings.TryRemove('uv', [ref]$null)
            }
            if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
                Clear-TestCachedCommandCache | Out-Null
            }
            @(
                'Invoke-Pip', 'Invoke-UVRun', 'Install-UVTool', 'New-UVVenv',
                'Update-UVOutdatedPackages', 'Update-UVTools', 'Invoke-UVTool',
                'Add-UVDependency', 'Sync-UVDependencies'
            ) | ForEach-Object {
                Remove-Item "Function:$_" -ErrorAction SilentlyContinue
            }
            @(
                'pip', 'uvrun', 'uvtool', 'uvvenv', 'uvupgrade', 'uvtoolupgrade',
                'uvx', 'uva', 'uvs'
            ) | ForEach-Object {
                Remove-Item "Alias:$_" -ErrorAction SilentlyContinue
            }
        }

        It 'uv fragment handles missing tool gracefully and recommends installation' {
            Set-TestCommandAvailabilityState -CommandName 'uv' -Available $false
            $output = & { . (Join-Path $script:ProfileDir 'uv.ps1') } 2>&1 3>&1 | Out-String
            Assert-TestMissingToolWarning -Output $output -Pattern 'uv not found'
            Assert-TestOutputContainsInstallCommand -Output $output -ToolName 'uv'
            Get-Command Invoke-Pip -CommandType Function -ErrorAction SilentlyContinue | Should -BeNullOrEmpty
        }
    }
}
