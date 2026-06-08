<#
.SYNOPSIS
    Integration tests for Poetry tool fragment.

.DESCRIPTION
    Tests Poetry helper functions.
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

Describe 'Poetry Tools Integration Tests' {
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
            Write-Error "Failed to initialize Poetry tools tests in BeforeAll: $($errorDetails | ConvertTo-Json -Compress)" -ErrorAction Stop
            throw
        }
    }

    Context 'Poetry helpers (poetry.ps1)' {
        BeforeAll {
            Set-TestCommandAvailabilityState -CommandName 'poetry' -Available $true
            . (Join-Path $script:ProfileDir 'poetry.ps1')
        }

        BeforeEach {
            Clear-TestCommandInvocationCapture
        }

        It 'Creates Install-PoetryDependencies function' {
            Get-Command Install-PoetryDependencies -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates poetry-install alias for Install-PoetryDependencies' {
            Get-Alias poetry-install -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias poetry-install).ResolvedCommandName | Should -Be 'Install-PoetryDependencies'
        }

        It 'Creates Test-PoetryOutdated function' {
            Get-Command Test-PoetryOutdated -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates poetry-outdated alias for Test-PoetryOutdated' {
            Get-Alias poetry-outdated -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias poetry-outdated).ResolvedCommandName | Should -Be 'Test-PoetryOutdated'
        }

        It 'Test-PoetryOutdated calls poetry show --outdated' {
            Setup-CapturingCommandMock -CommandName 'poetry' -Output @(
                'Package    Version  Latest'
                'package1  1.0.0    1.2.0'
            )

            Test-PoetryOutdated
            Assert-TestCommandInvokedExactlyOnce
            Get-Command Test-PoetryOutdated -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates Update-PoetryDependencies function' {
            Get-Command Update-PoetryDependencies -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates poetry-update alias for Update-PoetryDependencies' {
            Get-Alias poetry-update -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias poetry-update).ResolvedCommandName | Should -Be 'Update-PoetryDependencies'
        }

        It 'Update-PoetryDependencies calls poetry update' {
            Setup-CapturingCommandMock -CommandName 'poetry' -Output 'Dependencies updated successfully'

            Update-PoetryDependencies
            Assert-TestCommandInvokedExactlyOnce
            Get-Command Update-PoetryDependencies -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates Update-PoetrySelf function' {
            Get-Command Update-PoetrySelf -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates poetry-self-update alias for Update-PoetrySelf' {
            Get-Alias poetry-self-update -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias poetry-self-update).ResolvedCommandName | Should -Be 'Update-PoetrySelf'
        }

        It 'Update-PoetrySelf calls poetry self update' {
            Setup-CapturingCommandMock -CommandName 'poetry' -Output 'Poetry updated successfully'

            Update-PoetrySelf
            Assert-TestCommandInvokedExactlyOnce
            Get-Command Update-PoetrySelf -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates Export-PoetryDependencies function' {
            Get-Command Export-PoetryDependencies -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates poetryexport alias for Export-PoetryDependencies' {
            Get-Alias poetryexport -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias poetryexport).ResolvedCommandName | Should -Be 'Export-PoetryDependencies'
        }

        It 'Export-PoetryDependencies calls poetry export' {
            Setup-CapturingCommandMock -CommandName 'poetry' -Output 'requests==2.31.0'
            { Export-PoetryDependencies -Path (Get-TestArtifactPath -FileName 'test-requirements.txt') -Verbose 4>&1 | Out-Null } | Should -Not -Throw
            Assert-TestCommandInvokedExactlyOnce
                Assert-TestCommandInvocationContains 'export'
                Assert-TestCommandInvocationContains '-f'
                Assert-TestCommandInvocationContains 'requirements.txt'
        }

        It 'Export-PoetryDependencies with WithoutHashes passes --without-hashes flag' {
            Setup-CapturingCommandMock -CommandName 'poetry' -Output 'requests==2.31.0'
            { Export-PoetryDependencies -Path (Get-TestArtifactPath -FileName 'test-requirements.txt') -WithoutHashes -Verbose 4>&1 | Out-Null } | Should -Not -Throw
            Assert-TestCommandInvokedExactlyOnce
                Assert-TestCommandInvocationContains 'export'
                Assert-TestCommandInvocationContains '--without-hashes'
        }

        It 'Creates Import-PoetryDependencies function' {
            Get-Command Import-PoetryDependencies -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates poetryimport alias for Import-PoetryDependencies' {
            Get-Alias poetryimport -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias poetryimport).ResolvedCommandName | Should -Be 'Import-PoetryDependencies'
        }

        It 'Import-PoetryDependencies calls pip install -r' {
            $testFile = Get-TestArtifactPath -FileName 'test-requirements.txt'
            'requests==2.31.0' | Out-File -FilePath $testFile -ErrorAction SilentlyContinue
            
            Setup-CapturingCommandMock -CommandName 'pip' -Output 'Packages installed successfully'
            { Import-PoetryDependencies -Path $testFile -Verbose 4>&1 | Out-Null } | Should -Not -Throw
            Assert-TestCommandInvokedExactlyOnce
                Assert-TestCommandInvocationContains 'install'
                Assert-TestCommandInvocationContains '-r'
                Assert-TestCommandInvocationContains $testFile
            Remove-Item -Path $testFile -ErrorAction SilentlyContinue
        }

        It 'Import-PoetryDependencies with NoDeps passes --no-deps flag' {
            $testFile = Get-TestArtifactPath -FileName 'test-requirements.txt'
            'requests==2.31.0' | Out-File -FilePath $testFile -ErrorAction SilentlyContinue
            
            Setup-CapturingCommandMock -CommandName 'pip' -Output 'Packages installed'
            { Import-PoetryDependencies -Path $testFile -NoDeps -Verbose 4>&1 | Out-Null } | Should -Not -Throw
            Assert-TestCommandInvokedExactlyOnce
                Assert-TestCommandInvocationContains 'install'
                Assert-TestCommandInvocationContains '--no-deps'
            Remove-Item -Path $testFile -ErrorAction SilentlyContinue
        }

        It 'Creates poetrybackup alias for Export-PoetryDependencies' {
            Get-Alias poetrybackup -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias poetrybackup).ResolvedCommandName | Should -Be 'Export-PoetryDependencies'
        }

        It 'Creates poetryrestore alias for Import-PoetryDependencies' {
            Get-Alias poetryrestore -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias poetryrestore).ResolvedCommandName | Should -Be 'Import-PoetryDependencies'
        }

        It 'Export-PoetryDependencies with Dev passes --dev flag' {
            Setup-CapturingCommandMock -CommandName 'poetry' -Output 'requests==2.31.0'
            { Export-PoetryDependencies -Path (Get-TestArtifactPath -FileName 'test-requirements.txt') -Dev -Verbose 4>&1 | Out-Null } | Should -Not -Throw
            Assert-TestCommandInvokedExactlyOnce
            Assert-TestCommandInvocationContains 'export' '--with' 'dev'
        }

        It 'Import-PoetryDependencies handles missing file gracefully' {
            Setup-CapturingCommandMock -CommandName 'pip' -Output 'Packages installed'
            { Import-PoetryDependencies -Path (Get-TestArtifactPath -FileName 'nonexistent.txt') -ErrorAction SilentlyContinue 2>&1 | Out-Null } | Should -Not -Throw
            $global:TestCommandInvocationCaptures.Count | Should -Be 0
        }
    }

    Context 'Poetry graceful degradation' {
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

            # Remove functions/aliases from previous context
            Remove-Item Function:Install-PoetryDependencies -ErrorAction SilentlyContinue
            Remove-Item Function:Test-PoetryOutdated -ErrorAction SilentlyContinue
            Remove-Item Function:Update-PoetryDependencies -ErrorAction SilentlyContinue
            Remove-Item Function:Update-PoetrySelf -ErrorAction SilentlyContinue
            Remove-Item Function:Export-PoetryDependencies -ErrorAction SilentlyContinue
            Remove-Item Function:Import-PoetryDependencies -ErrorAction SilentlyContinue
            Remove-Item Alias:poetry-install -ErrorAction SilentlyContinue
            Remove-Item Alias:poetry-outdated -ErrorAction SilentlyContinue
            Remove-Item Alias:poetry-update -ErrorAction SilentlyContinue
            Remove-Item Alias:poetry-self-update -ErrorAction SilentlyContinue
            Remove-Item Alias:poetryexport -ErrorAction SilentlyContinue
            Remove-Item Alias:poetrybackup -ErrorAction SilentlyContinue
            Remove-Item Alias:poetryimport -ErrorAction SilentlyContinue
            Remove-Item Alias:poetryrestore -ErrorAction SilentlyContinue

            Set-TestCommandAvailabilityState -CommandName 'poetry' -Available $false
            $script:MissingPoetryOutput = & { . (Join-Path $script:ProfileDir 'poetry.ps1') } 2>&1 3>&1 | Out-String
        }

        It 'Functions are not created when poetry is unavailable' {
            Get-Command Install-PoetryDependencies -ErrorAction SilentlyContinue | Should -BeNullOrEmpty
            Get-Command Test-PoetryOutdated -ErrorAction SilentlyContinue | Should -BeNullOrEmpty
            Get-Command Update-PoetryDependencies -ErrorAction SilentlyContinue | Should -BeNullOrEmpty
        }

        It 'Emits missing-tool warning when poetry is unavailable' {
            Assert-TestMissingToolWarning -Output $script:MissingPoetryOutput -Pattern 'poetry not found'
            Assert-TestOutputContainsInstallCommand -Output $script:MissingPoetryOutput -ToolName 'poetry'
        }
    }
}
