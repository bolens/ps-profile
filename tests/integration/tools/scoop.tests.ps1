<#
.SYNOPSIS
    Integration tests for Scoop tool fragment.

.DESCRIPTION
    Tests Scoop helper functions.
    These tests verify that functions are created correctly and handle
    missing tools gracefully.
#>

BeforeAll {
    . (Join-Path $PSScriptRoot '..\..\TestSupport.ps1')
}

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
            if ($global:CollectedMissingToolWarnings) {
                $global:CollectedMissingToolWarnings.Clear()
            }
            if ($global:MissingToolWarnings) {
                $global:MissingToolWarnings.Clear()
            }
            if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
                Clear-TestCachedCommandCache | Out-Null
            }
            Set-TestCommandAvailabilityState -CommandName 'scoop' -Available $true
            . (Join-Path $script:ProfileDir 'scoop.ps1')
        }

        BeforeEach {
            Clear-TestCommandInvocationCapture
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
            Setup-CapturingCommandMock -CommandName 'scoop' -Output '{"git": "2.40.0"}'
            { Export-ScoopPackages -Path (Get-TestArtifactPath -FileName 'test-scoopfile.json') -Verbose 4>&1 | Out-Null } | Should -Not -Throw
            Assert-TestCommandInvokedExactlyOnce
        }

        It 'Import-ScoopPackages function exists when scoop is available' {
            Get-Command Import-ScoopPackages -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'Creates scoopimport alias for Import-ScoopPackages' {
            Get-Alias scoopimport -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias scoopimport).ResolvedCommandName | Should -Be 'Import-ScoopPackages'
        }

        It 'Import-ScoopPackages calls scoop import' {
            $testFile = Get-TestArtifactPath -FileName 'test-scoopfile.json'
            '{"git": "2.40.0"}' | Out-File -FilePath $testFile -ErrorAction SilentlyContinue
            Setup-CapturingCommandMock -CommandName 'scoop' -Output 'Packages imported successfully'
            { Import-ScoopPackages -Path $testFile -Verbose 4>&1 | Out-Null } | Should -Not -Throw
            Assert-TestCommandInvokedExactlyOnce
                Assert-TestCommandInvocationContains 'import'
                Assert-TestCommandInvocationContains $testFile
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
            Setup-CapturingCommandMock -CommandName 'scoop'

            { Import-ScoopPackages -Path (Get-TestArtifactPath -FileName 'nonexistent.json') -ErrorAction SilentlyContinue 2>&1 | Out-Null } | Should -Not -Throw
            $global:TestCommandInvocationCaptures.Count | Should -Be 0
        }

        It 'Install-ScoopPackage calls scoop install' {
            Setup-CapturingCommandMock -CommandName 'scoop' -Output 'Package installed successfully'
            { Install-ScoopPackage git -Verbose 4>&1 | Out-Null } | Should -Not -Throw
            Assert-TestCommandInvokedExactlyOnce
                Assert-TestCommandInvocationContains 'install'
                Assert-TestCommandInvocationContains 'git'
        }

        It 'Creates sinstall alias for Install-ScoopPackage' {
            Get-Alias sinstall -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias sinstall).ResolvedCommandName | Should -Be 'Install-ScoopPackage'
        }

        It 'Find-ScoopPackage calls scoop search' {
            Setup-CapturingCommandMock -CommandName 'scoop' -Output 'git 2.40.0'
            { Find-ScoopPackage git -Verbose 4>&1 | Out-Null } | Should -Not -Throw
            Assert-TestCommandInvokedExactlyOnce
                Assert-TestCommandInvocationContains 'search'
                Assert-TestCommandInvocationContains 'git'
        }

        It 'Creates ss alias for Find-ScoopPackage' {
            Assert-ProfileShadowedAlias -AliasName 'ss' -FunctionName 'Find-ScoopPackage'
        }

        It 'Update-ScoopPackage calls scoop update' {
            Setup-CapturingCommandMock -CommandName 'scoop' -Output 'Package updated successfully'
            { Update-ScoopPackage git -Verbose 4>&1 | Out-Null } | Should -Not -Throw
            Assert-TestCommandInvokedExactlyOnce
                Assert-TestCommandInvocationContains 'update'
                Assert-TestCommandInvocationContains 'git'
        }

        It 'Creates su alias for Update-ScoopPackage' {
            Assert-ProfileShadowedAlias -AliasName 'su' -FunctionName 'Update-ScoopPackage'
        }

        It 'Update-ScoopAll calls scoop update *' {
            Setup-CapturingCommandMock -CommandName 'scoop' -Output 'All packages updated successfully'
            { Update-ScoopAll -Verbose 4>&1 | Out-Null } | Should -Not -Throw
            Assert-TestCommandInvokedExactlyOnce
                Assert-TestCommandInvocationContains 'update'
                Assert-TestCommandInvocationContains '*'
        }

        It 'Creates suu alias for Update-ScoopAll' {
            Get-Alias suu -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias suu).ResolvedCommandName | Should -Be 'Update-ScoopAll'
        }

        It 'Uninstall-ScoopPackage calls scoop uninstall' {
            Setup-CapturingCommandMock -CommandName 'scoop' -Output 'Package uninstalled successfully'
            { Uninstall-ScoopPackage git -Verbose 4>&1 | Out-Null } | Should -Not -Throw
            Assert-TestCommandInvokedExactlyOnce
                Assert-TestCommandInvocationContains 'uninstall'
                Assert-TestCommandInvocationContains 'git'
        }

        It 'Creates sr alias for Uninstall-ScoopPackage' {
            Get-Alias sr -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias sr).ResolvedCommandName | Should -Be 'Uninstall-ScoopPackage'
        }

        It 'Get-ScoopPackage calls scoop list' {
            Setup-CapturingCommandMock -CommandName 'scoop' -Output @(
                'Installed packages:'
                'git 2.40.0'
            )
            { Get-ScoopPackage -Verbose 4>&1 | Out-Null } | Should -Not -Throw
            Assert-TestCommandInvokedExactlyOnce
                Assert-TestCommandInvocationContains 'list'
        }

        It 'Creates slist alias for Get-ScoopPackage' {
            Assert-ProfileShadowedAlias -AliasName 'slist' -FunctionName 'Get-ScoopPackage'
        }

        It 'Get-ScoopPackageInfo calls scoop info' {
            Setup-CapturingCommandMock -CommandName 'scoop' -Output @(
                'Name: git'
                'Version: 2.40.0'
            )
            { Get-ScoopPackageInfo git -Verbose 4>&1 | Out-Null } | Should -Not -Throw
            Assert-TestCommandInvokedExactlyOnce
                Assert-TestCommandInvocationContains 'info'
                Assert-TestCommandInvocationContains 'git'
        }

        It 'Creates sh alias for Get-ScoopPackageInfo' {
            Assert-ProfileShadowedAlias -AliasName 'sh' -FunctionName 'Get-ScoopPackageInfo'
        }

        It 'Clear-ScoopCache calls scoop cleanup and cache rm' {
            Setup-CapturingCommandMock -CommandName 'scoop' -Output 'Cache cleaned successfully'
            { Clear-ScoopCache -Verbose 4>&1 | Out-Null } | Should -Not -Throw
            $global:TestCommandInvocationCaptures.Count | Should -Be 2
            $global:TestCommandInvocationCaptures[0] | Should -Contain 'cleanup'
            $global:TestCommandInvocationCaptures[1] | Should -Contain 'cache'
            $global:TestCommandInvocationCaptures[1] | Should -Contain 'rm'
        }

        It 'Creates scleanup alias for Clear-ScoopCache' {
            Get-Alias scleanup -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias scleanup).ResolvedCommandName | Should -Be 'Clear-ScoopCache'
        }
    }

}

Describe 'Scoop unavailable graceful degradation' {
    BeforeAll {
        $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
        . (Join-Path $script:ProfileDir 'bootstrap.ps1')
    }

    It 'Functions are not created when scoop is unavailable' {
        $installCommand = & {
            if ($global:CollectedMissingToolWarnings) {
                $global:CollectedMissingToolWarnings.Clear()
            }
            if ($global:MissingToolWarnings) {
                $global:MissingToolWarnings.Clear()
            }
            if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
                Clear-TestCachedCommandCache | Out-Null
            }

            Set-TestCommandAvailabilityState -CommandName 'scoop' -Available $false
            . (Join-Path $script:ProfileDir 'scoop.ps1')
            Get-Command Install-ScoopPackage -ErrorAction SilentlyContinue
        }

        $installCommand | Should -BeNullOrEmpty
    }

    It 'Emits missing-tool warning when scoop is unavailable' {
        $output = & {
            if ($global:CollectedMissingToolWarnings) {
                $global:CollectedMissingToolWarnings.Clear()
            }
            if ($global:MissingToolWarnings) {
                $global:MissingToolWarnings.Clear()
            }
            if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
                Clear-TestCachedCommandCache | Out-Null
            }

            Set-TestCommandAvailabilityState -CommandName 'scoop' -Available $false
            . (Join-Path $script:ProfileDir 'scoop.ps1')
        } 2>&1 3>&1 | Out-String

        Assert-TestMissingToolWarning -Output $output -Pattern 'Scoop not found'
        Assert-TestOutputContainsInstallCommand -Output $output -ToolName 'scoop'
    }
}

