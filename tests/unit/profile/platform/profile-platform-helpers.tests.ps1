<#
.SYNOPSIS
    Resolves bootstrap resources for platform helper tests.
.DESCRIPTION
    Locates the repository profile directory and bootstrap fragment so tests can dot-source
    the same helpers used by the interactive profile. The resolved paths are stored in
    script-scoped variables for reuse within the current test file.
.PARAMETER BasePath
    Optional start path for repository discovery. Defaults to the current test directory.
#>
function Set-TestBootstrapContext {
    param(
        [string]$BasePath = $PSScriptRoot
    )

    # Use Get-TestPath from TestSupport.ps1 for consistent path resolution
    $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $BasePath -EnsureExists
    $script:BootstrapPath = Get-TestPath -RelativePath 'profile.d\bootstrap.ps1' -StartPath $BasePath -EnsureExists
}

Describe 'Platform Detection Helpers' {
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
        # Define function locally if not available
        if (-not (Get-Command Set-TestBootstrapContext -ErrorAction SilentlyContinue)) {
            function Set-TestBootstrapContext {
                param([string]$BasePath = $PSScriptRoot)
                $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $BasePath -EnsureExists
                $script:BootstrapPath = Get-TestPath -RelativePath 'profile.d\bootstrap.ps1' -StartPath $BasePath -EnsureExists
            }
        }
        Set-TestBootstrapContext
        # Import Platform module directly (functions are in scripts/lib/Platform.psm1, not bootstrap)
        $libPath = Get-TestPath -RelativePath 'scripts\lib' -StartPath $PSScriptRoot -EnsureExists
        Import-Module (Join-Path $libPath 'core' 'Platform.psm1') -DisableNameChecking -ErrorAction Stop
    }

    BeforeEach {
        # Load bootstrap to get other helpers (Register-LazyFunction, etc.)
        # Ensure bootstrap path exists and can be loaded
        if (-not (Test-Path $script:BootstrapPath)) {
            throw "Bootstrap path not found: $script:BootstrapPath"
        }
        . $script:BootstrapPath
        # Verify Get-UserHome is available after loading bootstrap
        if (-not (Get-Command Get-UserHome -ErrorAction SilentlyContinue)) {
            throw "Get-UserHome function not available after loading bootstrap"
        }
    }

    Context 'Platform Detection Functions' {
        It 'Test-IsWindows returns boolean' {
            $result = Test-IsWindows
            $result | Should -BeOfType [bool]
        }

        It 'Test-IsLinux returns boolean' {
            $result = Test-IsLinux
            $result | Should -BeOfType [bool]
        }

        It 'Test-IsMacOS returns boolean' {
            $result = Test-IsMacOS
            $result | Should -BeOfType [bool]
        }

        It 'Only one platform detection returns true' {
            $platformIndicators = @(
                (Test-IsWindows)
                (Test-IsLinux)
                (Test-IsMacOS)
            )

            $platformCount = $platformIndicators | Where-Object { $_ } | Measure-Object | Select-Object -ExpandProperty Count
            $platformCount | Should -BeLessOrEqual 1
        }
    }

    Context 'Get-UserHome Function' {
        It 'Get-UserHome returns a string' {
            $result = Get-UserHome
            $result | Should -BeOfType [string]
        }

        It 'Get-UserHome returns non-empty path' {
            $result = Get-UserHome
            $result | Should -Not -BeNullOrEmpty
        }

        It 'Get-UserHome path exists' {
            $homePath = Get-UserHome
            Test-Path $homePath | Should -Be $true
        }

        It 'Get-UserHome works with Join-Path' {
            $homePath = Get-UserHome
            $configPath = Join-Path $homePath '.config'
            $configPath | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Cross-Platform Compatibility' {
        It 'Get-UserHome prefers $env:HOME on Unix' {
            if ((Test-IsLinux) -or (Test-IsMacOS)) {
                $originalHome = $env:HOME
                                $env:HOME = '/test/home'
                $result = Get-UserHome
                $result | Should -Be '/test/home'
            }
            finally {
                $env:HOME = $originalHome
            }
        }

        It 'Get-UserHome falls back to $env:USERPROFILE' {
            try {
            $originalHome = $env:HOME
            $originalUserProfile = $env:USERPROFILE
                        $env:HOME = $null
            if ($env:USERPROFILE) {
                $result = Get-UserHome
                $result | Should -Not -BeNullOrEmpty
            }
            }
            finally {
                $env:HOME = $originalHome
                $env:USERPROFILE = $originalUserProfile
            }
        }
    }

    Context 'Platform Path Helpers' {
        It 'Get-TempDirectory returns a non-empty path' {
            if (-not (Get-Command Get-TempDirectory -ErrorAction SilentlyContinue)) {
                Set-ItResult -Skipped -Because 'Get-TempDirectory not loaded'
                return
            }

            $result = Get-TempDirectory
            $result | Should -Not -BeNullOrEmpty
        }

        It 'Get-ConfigDirectory returns a non-empty path' {
            if (-not (Get-Command Get-ConfigDirectory -ErrorAction SilentlyContinue)) {
                Set-ItResult -Skipped -Because 'Get-ConfigDirectory not loaded'
                return
            }

            $result = Get-ConfigDirectory
            $result | Should -Not -BeNullOrEmpty
        }

        It 'Get-CacheDirectory returns a non-empty path' {
            if (-not (Get-Command Get-CacheDirectory -ErrorAction SilentlyContinue)) {
                Set-ItResult -Skipped -Because 'Get-CacheDirectory not loaded'
                return
            }

            $result = Get-CacheDirectory
            $result | Should -Not -BeNullOrEmpty
        }

        It 'Get-DataDirectory returns a non-empty path' {
            if (-not (Get-Command Get-DataDirectory -ErrorAction SilentlyContinue)) {
                Set-ItResult -Skipped -Because 'Get-DataDirectory not loaded'
                return
            }

            $result = Get-DataDirectory
            $result | Should -Not -BeNullOrEmpty
        }

        It 'Get-UserDirectory returns a non-empty path' {
            if (-not (Get-Command Get-UserDirectory -ErrorAction SilentlyContinue)) {
                Set-ItResult -Skipped -Because 'Get-UserDirectory not loaded'
                return
            }

            $result = Get-UserDirectory -Name 'Desktop'
            $result | Should -Not -BeNullOrEmpty
        }

        It 'Get-UserDirectory works with Join-Path' {
            if (-not (Get-Command Get-UserDirectory -ErrorAction SilentlyContinue)) {
                Set-ItResult -Skipped -Because 'Get-UserDirectory not loaded'
                return
            }

            $downloads = Get-UserDirectory -Name 'Downloads'
            $downloads | Should -Not -BeNullOrEmpty
        }

        It 'Get-WranglerConfigPaths returns config paths' {
            if (-not (Get-Command Get-WranglerConfigPaths -ErrorAction SilentlyContinue)) {
                Set-ItResult -Skipped -Because 'Get-WranglerConfigPaths not loaded'
                return
            }

            $paths = Get-WranglerConfigPaths
            $paths.Dir | Should -Not -BeNullOrEmpty
            $paths.File | Should -Match 'default\.toml$'
        }

        It 'Get-PlatformInstallHint returns platform-aware text' {
            if (-not (Get-Command Get-PlatformInstallHint -ErrorAction SilentlyContinue)) {
                Set-ItResult -Skipped -Because 'Get-PlatformInstallHint not loaded'
                return
            }

            $hint = Get-PlatformInstallHint -ToolName 'fd'
            $hint | Should -Match '^Install with:'
        }

        It 'Get-PlatformInstallHint resolves cloud CLI package names' {
            if (-not (Get-Command Get-PlatformInstallHint -ErrorAction SilentlyContinue)) {
                Set-ItResult -Skipped -Because 'Get-PlatformInstallHint not loaded'
                return
            }

            $hint = Get-PlatformInstallHint -ToolName 'az'
            $hint | Should -Match '^Install with:'
            $hint | Should -Not -Match 'scoop install az\b'
        }

        It 'Get-PlatformInstallHint maps command aliases to package names' {
            if (-not (Get-Command Get-PlatformInstallHint -ErrorAction SilentlyContinue)) {
                Set-ItResult -Skipped -Because 'Get-PlatformInstallHint not loaded'
                return
            }

            $hint = Get-PlatformInstallHint -ToolName 'rg'
            $hint | Should -Match '^Install with:'
            $hint | Should -Match 'ripgrep'
        }

        It 'Get-ContainerEngineInstallHint combines docker and podman hints' {
            if (-not (Get-Command Get-ContainerEngineInstallHint -ErrorAction SilentlyContinue)) {
                Set-ItResult -Skipped -Because 'Get-ContainerEngineInstallHint not loaded'
                return
            }

            $hint = Get-ContainerEngineInstallHint
            $hint | Should -Match 'docker'
            $hint | Should -Match 'podman'
        }

        It 'Get-ConversionToolMissingMessage returns platform-aware text' {
            if (-not (Get-Command Get-ConversionToolMissingMessage -ErrorAction SilentlyContinue)) {
                Set-ItResult -Skipped -Because 'Get-ConversionToolMissingMessage not loaded'
                return
            }

            $message = Get-ConversionToolMissingMessage -ToolName 'ffmpeg'
            $message | Should -Match 'ffmpeg'
            $message | Should -Match 'Install with:'
        }

        It 'Get-PlatformInstallHint resolves content and media tool aliases' {
            if (-not (Get-Command Get-PlatformInstallHint -ErrorAction SilentlyContinue)) {
                Set-ItResult -Skipped -Because 'Get-PlatformInstallHint not loaded'
                return
            }

            $ytHint = Get-PlatformInstallHint -ToolName 'yt-dlp-nightly'
            $ytHint | Should -Match '^Install with:'
            $ytHint | Should -Match 'yt-dlp'

            $handbrakeHint = Get-PlatformInstallHint -ToolName 'handbrake-cli'
            $handbrakeHint | Should -Match '^Install with:'
            $handbrakeHint | Should -Match 'handbrake'
        }

        It 'Get-PlatformInstallHint returns hints for RE and network analysis tools' {
            if (-not (Get-Command Get-PlatformInstallHint -ErrorAction SilentlyContinue)) {
                Set-ItResult -Skipped -Because 'Get-PlatformInstallHint not loaded'
                return
            }

            $wiresharkHint = Get-PlatformInstallHint -ToolName 'wireshark'
            $wiresharkHint | Should -Match '^Install with:'
            $wiresharkHint | Should -Match 'wireshark'

            $cloudflaredHint = Get-PlatformInstallHint -ToolName 'cloudflared'
            $cloudflaredHint | Should -Match '^Install with:'
            $cloudflaredHint | Should -Match 'cloudflared'
        }

        It 'Get-PlatformInstallHint resolves editor and database client aliases' {
            if (-not (Get-Command Get-PlatformInstallHint -ErrorAction SilentlyContinue)) {
                Set-ItResult -Skipped -Because 'Get-PlatformInstallHint not loaded'
                return
            }

            $neovimHint = Get-PlatformInstallHint -ToolName 'neovim-nightly'
            $neovimHint | Should -Match '^Install with:'
            $neovimHint | Should -Match 'neovim'

            $psqlHint = Get-PlatformInstallHint -ToolName 'psql'
            $psqlHint | Should -Match '^Install with:'
            $psqlHint | Should -Match 'postgresql|psql|libpq|PostgreSQL'
        }

        It 'Get-PlatformInstallHint returns hints for dev tools and mobile utilities' {
            if (-not (Get-Command Get-PlatformInstallHint -ErrorAction SilentlyContinue)) {
                Set-ItResult -Skipped -Because 'Get-PlatformInstallHint not loaded'
                return
            }

            $godotHint = Get-PlatformInstallHint -ToolName 'godot'
            $godotHint | Should -Match '^Install with:'
            $godotHint | Should -Match 'godot'

            $adbHint = Get-PlatformInstallHint -ToolName 'adb'
            $adbHint | Should -Match '^Install with:'
            $adbHint | Should -Match 'adb|android'
        }

        It 'Get-PlatformInstallHint resolves git-enhanced and modern CLI tools' {
            if (-not (Get-Command Get-PlatformInstallHint -ErrorAction SilentlyContinue)) {
                Set-ItResult -Skipped -Because 'Get-PlatformInstallHint not loaded'
                return
            }

            $batHint = Get-PlatformInstallHint -ToolName 'bat'
            $batHint | Should -Match '^Install with:'
            $batHint | Should -Match 'bat'

            $jjHint = Get-PlatformInstallHint -ToolName 'jj'
            $jjHint | Should -Match '^Install with:'
            $jjHint | Should -Match 'jj'

            $gitbutlerHint = Get-PlatformInstallHint -ToolName 'gitbutler-nightly'
            $gitbutlerHint | Should -Match '^Install with:'
            $gitbutlerHint | Should -Match 'gitbutler'
        }

        It 'Get-PlatformInstallHint returns hints for build and container utilities' {
            if (-not (Get-Command Get-PlatformInstallHint -ErrorAction SilentlyContinue)) {
                Set-ItResult -Skipped -Because 'Get-PlatformInstallHint not loaded'
                return
            }

            $vcpkgHint = Get-PlatformInstallHint -ToolName 'vcpkg'
            $vcpkgHint | Should -Match '^Install with:'
            $vcpkgHint | Should -Match 'vcpkg'

            $komposeHint = Get-PlatformInstallHint -ToolName 'kompose'
            $komposeHint | Should -Match '^Install with:'
            $komposeHint | Should -Match 'kompose'
        }

        It 'Get-PlatformInstallHint returns hints for prompt and language tools' {
            if (-not (Get-Command Get-PlatformInstallHint -ErrorAction SilentlyContinue)) {
                Set-ItResult -Skipped -Because 'Get-PlatformInstallHint not loaded'
                return
            }

            $starshipHint = Get-PlatformInstallHint -ToolName 'starship'
            $starshipHint | Should -Match '^Install with:'
            $starshipHint | Should -Match 'starship'

            $mageHint = Get-PlatformInstallHint -ToolName 'mage' -ToolType 'go-package'
            $mageHint | Should -Match '^Install with:'
            $mageHint | Should -Match 'mage'
        }

        It 'Resolve-InstallPackageName maps package manager and CLI aliases' {
            if (-not (Get-Command Resolve-InstallPackageName -ErrorAction SilentlyContinue)) {
                Set-ItResult -Skipped -Because 'Resolve-InstallPackageName not loaded'
                return
            }

            Resolve-InstallPackageName -ToolName 'comfy' | Should -Be 'comfy-cli'
            Resolve-InstallPackageName -ToolName 'ng' | Should -Be '@angular/cli'
            Resolve-InstallPackageName -ToolName 'brew' | Should -Be 'homebrew'
            Resolve-InstallPackageName -ToolName 'choco' | Should -Be 'chocolatey'
        }

        It 'Resolve-CommandInstallToolType infers package manager categories' {
            if (-not (Get-Command Resolve-CommandInstallToolType -ErrorAction SilentlyContinue)) {
                Set-ItResult -Skipped -Because 'Resolve-CommandInstallToolType not loaded'
                return
            }

            Resolve-CommandInstallToolType -CommandName 'npm' | Should -Be 'node-package'
            Resolve-CommandInstallToolType -CommandName 'pip' | Should -Be 'python-package'
            Resolve-CommandInstallToolType -CommandName 'cargo' | Should -Be 'rust-package'
            Resolve-CommandInstallToolType -CommandName 'go' | Should -Be 'go-package'
            Resolve-CommandInstallToolType -CommandName 'docker' | Should -Be 'generic'
        }

        It 'Invoke-ContainerEngineMissingWarning emits combined docker and podman hints' {
            if (-not (Get-Command Invoke-ContainerEngineMissingWarning -ErrorAction SilentlyContinue)) {
                Set-ItResult -Skipped -Because 'Invoke-ContainerEngineMissingWarning not loaded'
                return
            }

            $script:MissingToolWarningCaptures = [System.Collections.Generic.List[hashtable]]::new()
            $originalWriteMissingToolWarning = Get-Command Write-MissingToolWarning -ErrorAction SilentlyContinue

            function global:Write-MissingToolWarning {
                param(
                    [string]$Tool,
                    [string]$InstallHint
                )
                $null = $script:MissingToolWarningCaptures.Add(@{
                        Tool        = $Tool
                        InstallHint = $InstallHint
                    })
            }

            try {
                Invoke-ContainerEngineMissingWarning

                $script:MissingToolWarningCaptures.Count | Should -Be 1
                $script:MissingToolWarningCaptures[0].Tool | Should -Be 'docker/podman'
                $script:MissingToolWarningCaptures[0].InstallHint | Should -Match 'docker'
                $script:MissingToolWarningCaptures[0].InstallHint | Should -Match 'podman'
            }
            finally {
                Remove-Item Function:\Write-MissingToolWarning -Force -ErrorAction SilentlyContinue
                Remove-Item Function:\global:Write-MissingToolWarning -Force -ErrorAction SilentlyContinue
                if ($originalWriteMissingToolWarning) {
                    Set-Item -Path Function:\global:Write-MissingToolWarning -Value $originalWriteMissingToolWarning.ScriptBlock -Force
                }
            }
        }

        It 'Get-PlatformInstallHint returns hints for JavaScript testing tools' {
            if (-not (Get-Command Get-PlatformInstallHint -ErrorAction SilentlyContinue)) {
                Set-ItResult -Skipped -Because 'Get-PlatformInstallHint not loaded'
                return
            }

            $jestHint = Get-PlatformInstallHint -ToolName 'jest' -ToolType 'node-package'
            $jestHint | Should -Match '^Install with:'
            $jestHint | Should -Match 'jest'

            $typescriptHint = Get-PlatformInstallHint -ToolName 'typescript' -ToolType 'node-package'
            $typescriptHint | Should -Match '^Install with:'
            $typescriptHint | Should -Match 'typescript'
        }

        It 'Get-PlatformInstallHint resolves package aliases in registry lookup' {
            if (-not (Get-Command Get-PreferenceAwareInstallHint -ErrorAction SilentlyContinue)) {
                Set-ItResult -Skipped -Because 'Get-PreferenceAwareInstallHint not loaded'
                return
            }

            $hint = Get-PreferenceAwareInstallHint -ToolName 'rg' -ToolType 'generic'
            $hint | Should -Match 'ripgrep'
        }

        It 'Resolve-InstallPackageName maps runtime command aliases' {
            if (-not (Get-Command Resolve-InstallPackageName -ErrorAction SilentlyContinue)) {
                Set-ItResult -Skipped -Because 'Resolve-InstallPackageName not loaded'
                return
            }

            Resolve-InstallPackageName -ToolName 'node' | Should -Be 'nodejs'
            Resolve-InstallPackageName -ToolName 'ssh' | Should -Be 'openssh'
            Resolve-InstallPackageName -ToolName 'pdflatex' | Should -Be 'miktex'
        }

        It 'Get-PlatformInstallHint returns hints for document and SSH utilities' {
            if (-not (Get-Command Get-PlatformInstallHint -ErrorAction SilentlyContinue)) {
                Set-ItResult -Skipped -Because 'Get-PlatformInstallHint not loaded'
                return
            }

            $djvuHint = Get-PlatformInstallHint -ToolName 'djvulibre'
            $djvuHint | Should -Match '^Install with:'
            $djvuHint | Should -Match 'djvulibre'

            $sshHint = Get-PlatformInstallHint -ToolName 'ssh'
            $sshHint | Should -Match '^Install with:'
            $sshHint | Should -Match 'openssh'
        }

        It 'Invoke-DangerzoneMissingWarning appends Docker requirement when needed' {
            if (-not (Get-Command Invoke-DangerzoneMissingWarning -ErrorAction SilentlyContinue)) {
                Set-ItResult -Skipped -Because 'Invoke-DangerzoneMissingWarning not loaded'
                return
            }

            $script:MissingToolWarningCaptures = [System.Collections.Generic.List[hashtable]]::new()
            $originalWriteMissingToolWarning = Get-Command Write-MissingToolWarning -ErrorAction SilentlyContinue
            $originalGetPlatformInstallHint = Get-Command Get-PlatformInstallHint -ErrorAction SilentlyContinue

            function global:Write-MissingToolWarning {
                param(
                    [string]$Tool,
                    [string]$InstallHint
                )
                $null = $script:MissingToolWarningCaptures.Add(@{
                        Tool        = $Tool
                        InstallHint = $InstallHint
                    })
            }

            function global:Get-PlatformInstallHint {
                param(
                    [string]$ToolName,
                    [string]$ToolType = 'generic',
                    [string]$InstallPackageName
                )
                return 'Install with: scoop install dangerzone'
            }

            try {
                Invoke-DangerzoneMissingWarning

                $script:MissingToolWarningCaptures.Count | Should -Be 1
                $script:MissingToolWarningCaptures[0].Tool | Should -Be 'dangerzone'
                $script:MissingToolWarningCaptures[0].InstallHint | Should -Match 'Docker'
            }
            finally {
                Remove-Item Function:\Write-MissingToolWarning -Force -ErrorAction SilentlyContinue
                Remove-Item Function:\global:Write-MissingToolWarning -Force -ErrorAction SilentlyContinue
                Remove-Item Function:\Get-PlatformInstallHint -Force -ErrorAction SilentlyContinue
                Remove-Item Function:\global:Get-PlatformInstallHint -Force -ErrorAction SilentlyContinue

                if ($originalWriteMissingToolWarning) {
                    Set-Item -Path Function:\global:Write-MissingToolWarning -Value $originalWriteMissingToolWarning.ScriptBlock -Force
                }

                if ($originalGetPlatformInstallHint) {
                    Set-Item -Path Function:\global:Get-PlatformInstallHint -Value $originalGetPlatformInstallHint.ScriptBlock -Force
                }
            }
        }

        It 'Invoke-MissingToolWarning supports AdditionalHint parameter' {
            if (-not (Get-Command Invoke-MissingToolWarning -ErrorAction SilentlyContinue)) {
                Set-ItResult -Skipped -Because 'Invoke-MissingToolWarning not loaded'
                return
            }

            $script:MissingToolWarningCaptures = [System.Collections.Generic.List[hashtable]]::new()
            $originalWriteMissingToolWarning = Get-Command Write-MissingToolWarning -ErrorAction SilentlyContinue
            $originalGetPlatformInstallHint = Get-Command Get-PlatformInstallHint -ErrorAction SilentlyContinue

            function global:Write-MissingToolWarning {
                param(
                    [string]$Tool,
                    [string]$InstallHint
                )
                $null = $script:MissingToolWarningCaptures.Add(@{
                        Tool        = $Tool
                        InstallHint = $InstallHint
                    })
            }

            function global:Get-PlatformInstallHint {
                param(
                    [string]$ToolName,
                    [string]$ToolType = 'generic',
                    [string]$InstallPackageName
                )
                return 'Install with: scoop install example'
            }

            try {
                Invoke-MissingToolWarning -ToolName 'example' -AdditionalHint '(requires extra setup)'

                $script:MissingToolWarningCaptures.Count | Should -Be 1
                $script:MissingToolWarningCaptures[0].InstallHint | Should -Match 'extra setup'
            }
            finally {
                Remove-Item Function:\Write-MissingToolWarning -Force -ErrorAction SilentlyContinue
                Remove-Item Function:\global:Write-MissingToolWarning -Force -ErrorAction SilentlyContinue
                Remove-Item Function:\Get-PlatformInstallHint -Force -ErrorAction SilentlyContinue
                Remove-Item Function:\global:Get-PlatformInstallHint -Force -ErrorAction SilentlyContinue

                if ($originalWriteMissingToolWarning) {
                    Set-Item -Path Function:\global:Write-MissingToolWarning -Value $originalWriteMissingToolWarning.ScriptBlock -Force
                }

                if ($originalGetPlatformInstallHint) {
                    Set-Item -Path Function:\global:Get-PlatformInstallHint -Value $originalGetPlatformInstallHint.ScriptBlock -Force
                }
            }
        }
    }
}

Describe 'Register-LazyFunction Helper' {
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
        # Define function locally if not available
        if (-not (Get-Command Set-TestBootstrapContext -ErrorAction SilentlyContinue)) {
            function Set-TestBootstrapContext {
                param([string]$BasePath = $PSScriptRoot)
                $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $BasePath -EnsureExists
                $script:BootstrapPath = Get-TestPath -RelativePath 'profile.d\bootstrap.ps1' -StartPath $BasePath -EnsureExists
            }
        }
        Set-TestBootstrapContext
    }

    BeforeEach {
        # Ensure bootstrap path exists and can be loaded
        if (-not (Test-Path $script:BootstrapPath)) {
            throw "Bootstrap path not found: $script:BootstrapPath"
        }
        . $script:BootstrapPath
        # Verify Register-LazyFunction is available after loading bootstrap
        if (-not (Get-Command Register-LazyFunction -ErrorAction SilentlyContinue)) {
            throw "Register-LazyFunction not available after loading bootstrap"
        }
    }

    Context 'Lazy Function Registration' {
        It 'Register-LazyFunction creates a function stub' {
            $testFuncName = "Test-LazyFunction_$(Get-Random)"
            $flagName = "TestLazyInitialized_{0}" -f (Get-Random)
            Set-Variable -Name $flagName -Value $false -Scope Global

            $initializer = {
                Set-Variable -Name $flagName -Value $true -Scope Global
                Set-AgentModeFunction -Name $testFuncName -Body { Write-Output 'initialized' }
            }.GetNewClosure()

            Register-LazyFunction -Name $testFuncName -Initializer $initializer

            Test-Path "Function:$testFuncName" | Should -Be $true
            (Get-Variable -Name $flagName -Scope Global -ValueOnly) | Should -Be $false

            # Cleanup
            Remove-Item "Function:$testFuncName" -ErrorAction SilentlyContinue
            Remove-Variable -Name $flagName -Scope Global -ErrorAction SilentlyContinue
        }

        It 'Register-LazyFunction initializes on first call' {
            $testFuncName = "Test-LazyInit_$(Get-Random)"
            $flagName = "TestLazyInitialized_{0}" -f (Get-Random)
            Set-Variable -Name $flagName -Value $false -Scope Global

            $initializer = {
                Set-Variable -Name $flagName -Value $true -Scope Global
                Set-AgentModeFunction -Name $testFuncName -Body { Write-Output 'initialized' }
            }.GetNewClosure()

            Register-LazyFunction -Name $testFuncName -Initializer $initializer

            $result = & $testFuncName
            (Get-Variable -Name $flagName -Scope Global -ValueOnly) | Should -Be $true
            $result | Should -Be 'initialized'

            # Cleanup
            Remove-Item "Function:$testFuncName" -ErrorAction SilentlyContinue
            Remove-Variable -Name $flagName -Scope Global -ErrorAction SilentlyContinue
        }

        It 'Register-LazyFunction creates alias when specified' {
            $testFuncName = "Test-LazyWithAlias_$(Get-Random)"
            $testAlias = "tla_$(Get-Random)"
            $flagName = "TestLazyInitialized_{0}" -f (Get-Random)
            Set-Variable -Name $flagName -Value $false -Scope Global

            $initializer = {
                Set-Variable -Name $flagName -Value $true -Scope Global
                Set-AgentModeFunction -Name $testFuncName -Body { Write-Output 'aliased' }
            }.GetNewClosure()

            Register-LazyFunction -Name $testFuncName -Initializer $initializer -Alias $testAlias

            Get-Alias -Name $testAlias -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty

            # Cleanup
            Remove-Item "Function:$testFuncName" -ErrorAction SilentlyContinue
            Remove-Item "Alias:$testAlias" -ErrorAction SilentlyContinue
            Remove-Variable -Name $flagName -Scope Global -ErrorAction SilentlyContinue
        }
    }
}

Describe 'Test-CachedCommand with TTL' {
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
        # Define function locally if not available
        if (-not (Get-Command Set-TestBootstrapContext -ErrorAction SilentlyContinue)) {
            function Set-TestBootstrapContext {
                param([string]$BasePath = $PSScriptRoot)
                $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $BasePath -EnsureExists
                $script:BootstrapPath = Get-TestPath -RelativePath 'profile.d\bootstrap.ps1' -StartPath $BasePath -EnsureExists
            }
        }
        Set-TestBootstrapContext
    }

    BeforeEach {
        # Ensure bootstrap path exists and can be loaded
        if (-not (Test-Path $script:BootstrapPath)) {
            throw "Bootstrap path not found: $script:BootstrapPath"
        }
        . $script:BootstrapPath
        # Verify Register-LazyFunction is available after loading bootstrap
        if (-not (Get-Command Register-LazyFunction -ErrorAction SilentlyContinue)) {
            throw "Register-LazyFunction not available after loading bootstrap"
        }
    }

    Context 'Command Cache TTL' {
        It 'Test-CachedCommand caches results' {
            $result1 = Test-CachedCommand 'Get-Command'
            $result2 = Test-CachedCommand 'Get-Command'
            $result1 | Should -Be $result2
        }

        It 'Test-CachedCommand accepts CacheTTLMinutes parameter' {
            { Test-CachedCommand -Name 'Get-Command' -CacheTTLMinutes 10 } | Should -Not -Throw
        }

        It 'Test-CachedCommand returns boolean' {
            $result = Test-CachedCommand 'Get-Command'
            $result | Should -BeOfType [bool]
        }
    }
}

Describe 'Test-SafePath Security Helper' {
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
        $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
        $script:UtilitiesPath = Get-TestPath -RelativePath 'profile.d\utilities.ps1' -StartPath $PSScriptRoot -EnsureExists
        $script:TestTempRoot = New-TestTempDirectory -Prefix 'ProfilePlatformPath'
        . (Join-Path $script:ProfileDir 'bootstrap.ps1')
        . (Join-Path $script:ProfileDir 'files-module-registry.ps1')
        . $script:UtilitiesPath
        Ensure-Utilities
    }

    Context 'Path Validation' {
        It 'Test-SafePath returns boolean' {
            $testBase = $script:TestTempRoot
            $testPath = Join-Path $testBase 'test.txt'
            New-Item -ItemType File -Path $testPath -Force | Out-Null

            $result = Test-SafePath -Path $testPath -BasePath $testBase
            $result | Should -BeOfType [bool]
        }

        It 'Test-SafePath allows paths within base directory' {
            $testBase = $script:TestTempRoot
            $testPath = Join-Path $testBase 'subdir' 'test.txt'
            New-Item -ItemType File -Path $testPath -Force | Out-Null

            $result = Test-SafePath -Path $testPath -BasePath $testBase
            $result | Should -Be $true
        }

        It 'Test-SafePath rejects paths outside base directory' {
            $testBase = $script:TestTempRoot
            $outsidePath = Join-Path (Split-Path $testBase -Parent) 'outside.txt'

            $result = Test-SafePath -Path $outsidePath -BasePath $testBase
            $result | Should -Be $false
        }

        It 'Test-SafePath handles path traversal attempts' {
            $testBase = $script:TestTempRoot
            $traversalPath = Join-Path $testBase '..' '..' 'etc' 'passwd'

            $result = Test-SafePath -Path $traversalPath -BasePath $testBase
            $result | Should -Be $false
        }

        It 'Test-SafePath handles invalid paths gracefully' {
            $testBase = $script:TestTempRoot
            $invalidPath = "C:\Invalid<>Path|Test"

            { Test-SafePath -Path $invalidPath -BasePath $testBase } | Should -Not -Throw
            $result = Test-SafePath -Path $invalidPath -BasePath $testBase
            $result | Should -Be $false
        }
    }

    Context 'EmbeddedInstallHints helpers' {
        It 'Expand-EmbeddedNodeInstallHints replaces placeholders' {
            if (-not (Get-Command Expand-EmbeddedNodeInstallHints -ErrorAction SilentlyContinue)) {
                Set-ItResult -Skipped -Because 'Expand-EmbeddedNodeInstallHints not loaded'
                return
            }

            $script = "console.error('Install with: __NODE_INSTALL_CMD__');"
            $expanded = Expand-EmbeddedNodeInstallHints -Script $script -PackageNames 'json5' -Global
            $expanded | Should -Not -Match '__NODE_INSTALL_CMD__'
            $expanded | Should -Match 'json5'
        }

        It 'Expand-EmbeddedNodeInstallHints combines multiple packages' {
            if (-not (Get-Command Expand-EmbeddedNodeInstallHints -ErrorAction SilentlyContinue)) {
                Set-ItResult -Skipped -Because 'Expand-EmbeddedNodeInstallHints not loaded'
                return
            }

            $expanded = Expand-EmbeddedNodeInstallHints -Script '__NODE_INSTALL_CMD__' -PackageNames @('bson', 'cbor') -Global
            $expanded | Should -Match 'bson'
            $expanded | Should -Match 'cbor'
        }

        It 'Expand-EmbeddedPythonInstallHints replaces placeholders' {
            if (-not (Get-Command Expand-EmbeddedPythonInstallHints -ErrorAction SilentlyContinue)) {
                Set-ItResult -Skipped -Because 'Expand-EmbeddedPythonInstallHints not loaded'
                return
            }

            $expanded = Expand-EmbeddedPythonInstallHints -Script '__PYTHON_INSTALL_CMD__' -PackageNames 'h5py' -Global
            $expanded | Should -Not -Match '__PYTHON_INSTALL_CMD__'
            $expanded | Should -Match 'h5py'
        }

        It 'Resolve-NodeInstallHintMessage resolves embedded messages' {
            if (-not (Get-Command Resolve-NodeInstallHintMessage -ErrorAction SilentlyContinue)) {
                Set-ItResult -Skipped -Because 'Resolve-NodeInstallHintMessage not loaded'
                return
            }

            $message = Resolve-NodeInstallHintMessage -Message 'Install it with: __NODE_INSTALL_CMD__' -PackageNames 'cbor' -Global
            $message | Should -Not -Match '__NODE_INSTALL_CMD__'
            $message | Should -Match 'cbor'
        }
    }
}
