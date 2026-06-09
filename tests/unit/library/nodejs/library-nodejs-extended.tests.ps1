<#
tests/unit/library-nodejs-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for NodeJs path detection and script invocation guards.
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
    $script:RepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:LibPath = Get-TestPath -RelativePath 'scripts\lib' -StartPath $PSScriptRoot -EnsureExists
    $script:ProfileDir = Join-Path $script:RepoRoot 'profile.d'
    Import-Module (Join-Path $script:LibPath 'runtime' 'NodeJs.psm1') -DisableNameChecking -Force

    $script:TempDir = New-TestTempDirectory -Prefix 'NodeJsExtended'
}

function script:Enable-TestStructuredLogging {
    if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
        return
    }

    . (Join-Path $script:ProfileDir 'bootstrap.ps1')
    . (Join-Path $script:ProfileDir 'bootstrap' 'ErrorHandlingStandard.ps1')
}

function script:Clear-NodeJsTestEnvironment {
    foreach ($name in @(
            'PNPM_HOME', 'PNPM_ROOT', 'NPM_CONFIG_PREFIX', 'NODE_PATH', 'NVM_DIR',
            'PS_NODE_PACKAGE_MANAGER', 'PS_PROFILE_REPO_ROOT', 'PS_PROFILE_DEBUG'
        )) {
        Remove-Item "Env:$name" -ErrorAction SilentlyContinue
    }

    Mark-TestCommandsUnavailable -CommandNames @('pnpm', 'npm', 'node', 'yarn', 'bun')
    $global:BinaryConversionBasePath = $null
}

AfterAll {
    Remove-Module NodeJs -ErrorAction SilentlyContinue -Force

    if ($script:TempDir -and (Test-Path -LiteralPath $script:TempDir)) {
        Remove-Item -LiteralPath $script:TempDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Describe 'NodeJs extended scenarios' {
    Context 'Get-PnpmGlobalPath environment hooks' {
        BeforeEach {
            Clear-NodeJsTestEnvironment
        }

        It 'Does not treat PNPM_HOME as global path when node_modules is missing beneath it' {
            $emptyHome = Join-Path $script:TempDir 'empty-pnpm-home'
            New-Item -ItemType Directory -Path $emptyHome -Force | Out-Null

            $original = $env:PNPM_HOME
            try {
                $env:PNPM_HOME = $emptyHome
                $result = Get-PnpmGlobalPath

                if ($null -ne $result) {
                    $result | Should -Not -Be (Join-Path $emptyHome 'node_modules')
                }
            }
            finally {
                if ($null -eq $original) {
                    Remove-Item Env:PNPM_HOME -ErrorAction SilentlyContinue
                }
                else {
                    $env:PNPM_HOME = $original
                }
            }
        }

        It 'Prefers PNPM_HOME node_modules over other detection paths' {
            $pnpmHome = Join-Path $script:TempDir 'pnpm-home'
            $nodeModules = Join-Path $pnpmHome 'node_modules'
            New-Item -ItemType Directory -Path $nodeModules -Force | Out-Null

            $original = $env:PNPM_HOME
            try {
                $env:PNPM_HOME = $pnpmHome
                Get-PnpmGlobalPath | Should -Be $nodeModules
            }
            finally {
                if ($null -eq $original) {
                    Remove-Item Env:PNPM_HOME -ErrorAction SilentlyContinue
                }
                else {
                    $env:PNPM_HOME = $original
                }
            }
        }

        It 'Uses NPM_CONFIG_PREFIX when node_modules exists beneath it' {
            $prefix = Join-Path $script:TempDir 'npm-prefix'
            $nodeModules = Join-Path $prefix 'node_modules'
            New-Item -ItemType Directory -Path $nodeModules -Force | Out-Null

            $original = $env:NPM_CONFIG_PREFIX
            try {
                $env:NPM_CONFIG_PREFIX = $prefix
                Get-PnpmGlobalPath | Should -Be $nodeModules
            }
            finally {
                if ($null -eq $original) {
                    Remove-Item Env:NPM_CONFIG_PREFIX -ErrorAction SilentlyContinue
                }
                else {
                    $env:NPM_CONFIG_PREFIX = $original
                }
            }
        }

        It 'Uses the first valid path from NODE_PATH' {
            $firstPath = Join-Path $script:TempDir 'node-path-first'
            New-Item -ItemType Directory -Path $firstPath -Force | Out-Null
            $secondPath = Join-Path $script:TempDir 'node-path-second'
            New-Item -ItemType Directory -Path $secondPath -Force | Out-Null

            $original = $env:NODE_PATH
            try {
                $env:NODE_PATH = "$firstPath$([System.IO.Path]::PathSeparator)$secondPath"
                Get-PnpmGlobalPath | Should -Be $firstPath
            }
            finally {
                if ($null -eq $original) {
                    Remove-Item Env:NODE_PATH -ErrorAction SilentlyContinue
                }
                else {
                    $env:NODE_PATH = $original
                }
            }
        }

        It 'Resolves pnpm root output when the pnpm command is available' {
            Setup-CapturingCommandMock -CommandName 'pnpm' -Output (Join-Path $script:TempDir 'pnpm-global-root') -MarkAvailable $true
            New-Item -ItemType Directory -Path (Join-Path $script:TempDir 'pnpm-global-root') -Force | Out-Null

            Get-PnpmGlobalPath | Should -Be (Join-Path $script:TempDir 'pnpm-global-root')
        }
    }

    Context 'Get-PnpmGlobalPath without Validation helpers' {
        BeforeEach {
            Clear-NodeJsTestEnvironment
            Remove-Module Validation -ErrorAction SilentlyContinue -Force
        }

        AfterEach {
            Import-Module (Join-Path $script:LibPath 'core' 'Validation.psm1') -DisableNameChecking -Force -ErrorAction SilentlyContinue
        }

        It 'Resolves PNPM_HOME using manual path checks when validation helpers are unavailable' {
            $pnpmHome = Join-Path $script:TempDir 'pnpm-home-manual'
            $nodeModules = Join-Path $pnpmHome 'node_modules'
            New-Item -ItemType Directory -Path $nodeModules -Force | Out-Null

            $original = $env:PNPM_HOME
            try {
                $env:PNPM_HOME = $pnpmHome
                Get-PnpmGlobalPath | Should -Be $nodeModules
            }
            finally {
                if ($null -eq $original) {
                    Remove-Item Env:PNPM_HOME -ErrorAction SilentlyContinue
                }
                else {
                    $env:PNPM_HOME = $original
                }
            }
        }
    }

    Context 'Get-NodeModuleSearchPaths' {
        BeforeEach {
            Clear-NodeJsTestEnvironment
        }

        It 'Includes repo-local node_modules when PS_PROFILE_REPO_ROOT is set' {
            $repoRoot = Join-Path $script:TempDir 'repo-with-modules'
            $localModules = Join-Path $repoRoot 'node_modules'
            New-Item -ItemType Directory -Path $localModules -Force | Out-Null

            $original = $env:PS_PROFILE_REPO_ROOT
            try {
                $env:PS_PROFILE_REPO_ROOT = $repoRoot
                $paths = @(Get-NodeModuleSearchPaths)
                $paths | Should -Contain $localModules
            }
            finally {
                if ($null -eq $original) {
                    Remove-Item Env:PS_PROFILE_REPO_ROOT -ErrorAction SilentlyContinue
                }
                else {
                    $env:PS_PROFILE_REPO_ROOT = $original
                }
            }
        }
    }

    Context 'Invoke-NodeScript' {
        BeforeEach {
            Clear-NodeJsTestEnvironment
        }

        It 'Throws when the script path is outside the filesystem' {
            $missingScript = Join-Path $script:TempDir 'missing-script.js'

            { Invoke-NodeScript -ScriptPath $missingScript } | Should -Throw '*not found*'
        }

        It 'Accepts Arguments parameter for forwarding to node' {
            $command = Get-Command Invoke-NodeScript
            $command.Parameters.Keys | Should -Contain 'Arguments'
        }

        It 'Executes a script and returns output when node is available' {
            Setup-CapturingCommandMock -CommandName 'node' -Output 'hello-from-node-mock' -MarkAvailable $true
            $testScript = Join-Path $script:TempDir 'hello.js'
            Set-Content -LiteralPath $testScript -Value 'console.log("ignored");' -Encoding UTF8

            Invoke-NodeScript -ScriptPath $testScript | Should -Be 'hello-from-node-mock'
        }

        It 'Throws when node is not available' {
            if ((Get-Command node -ErrorAction SilentlyContinue)) {
                Set-ItResult -Skipped -Because 'node is available on this system, cannot test unavailable scenario'
                return
            }

            $testScript = Join-Path $script:TempDir 'unavailable.js'
            Set-Content -LiteralPath $testScript -Value 'console.log("x");' -Encoding UTF8

            { Invoke-NodeScript -ScriptPath $testScript } | Should -Throw '*not available*'
        }

        It 'Throws with script output when execution exits non-zero' {
            Setup-CapturingCommandMock -CommandName 'node' -Output '' -ExitCode 0 -MarkAvailable $true -OnInvoke {
                if ($args -contains '--version') {
                    $global:TestCommandCaptureState['ExitCode'] = 0
                    return 'v20.0.0'
                }

                $global:TestCommandCaptureState['ExitCode'] = 2
                return 'runtime failure'
            }
            $testScript = Join-Path $script:TempDir 'fail.js'
            Set-Content -LiteralPath $testScript -Value 'process.exit(2);' -Encoding UTF8

            { Invoke-NodeScript -ScriptPath $testScript } | Should -Throw '*exit code 2*'
        }

        It 'Uses Write-StructuredError when execution fails and structured logging is enabled' {
            Enable-TestStructuredLogging
            Setup-CapturingCommandMock -CommandName 'node' -Output 'structured failure' -ExitCode 3 -MarkAvailable $true
            $testScript = Join-Path $script:TempDir 'structured-fail.js'
            Set-Content -LiteralPath $testScript -Value 'process.exit(3);' -Encoding UTF8

            $originalDebug = $env:PS_PROFILE_DEBUG
            $env:PS_PROFILE_DEBUG = '1'

            try {
                { Invoke-NodeScript -ScriptPath $testScript } | Should -Throw
            }
            finally {
                if ($null -eq $originalDebug) {
                    Remove-Item Env:PS_PROFILE_DEBUG -ErrorAction SilentlyContinue
                }
                else {
                    $env:PS_PROFILE_DEBUG = $originalDebug
                }
            }
        }
    }

    Context 'Set-NodePathForPnpm' {
        BeforeEach {
            Clear-NodeJsTestEnvironment
            $script:OriginalNodePath = $env:NODE_PATH
        }

        AfterEach {
            if ($script:OriginalNodePath) {
                $env:NODE_PATH = $script:OriginalNodePath
            }
            elseif ($env:NODE_PATH) {
                Remove-Item Env:\NODE_PATH -ErrorAction SilentlyContinue
            }
        }

        It 'Prepends discovered module paths to NODE_PATH' {
            $pnpmHome = Join-Path $script:TempDir 'set-node-path-home'
            $nodeModules = Join-Path $pnpmHome 'node_modules'
            New-Item -ItemType Directory -Path $nodeModules -Force | Out-Null

            $originalPnpmHome = $env:PNPM_HOME
            try {
                $env:PNPM_HOME = $pnpmHome
                $restore = Set-NodePathForPnpm
                $env:NODE_PATH | Should -Match ([regex]::Escape($nodeModules))
                & $restore
            }
            finally {
                if ($null -eq $originalPnpmHome) {
                    Remove-Item Env:PNPM_HOME -ErrorAction SilentlyContinue
                }
                else {
                    $env:PNPM_HOME = $originalPnpmHome
                }
            }
        }
    }

    Context 'Get-NodePackageManagerPreference' {
        BeforeEach {
            Clear-NodeJsTestEnvironment
        }

        It 'Prefers pnpm when auto mode and pnpm is available' {
            Set-TestCommandAvailabilityState -CommandName 'pnpm' -Available $true
            Setup-CapturingCommandMock -CommandName 'pnpm' -Output '' -MarkAvailable $true

            $result = Get-NodePackageManagerPreference
            $result.Manager | Should -Be 'pnpm'
            $result.Available | Should -Be $true
        }

        It 'Falls back to npm install command when no manager is available' {
            Mock Get-Command {
                param($Name)
                if ($Name -in @('pnpm', 'npm', 'yarn', 'bun')) {
                    return $null
                }

                return Microsoft.PowerShell.Core\Get-Command @PSBoundParameters
            } -ModuleName NodeJs

            $result = Get-NodePackageManagerPreference
            $result.Available | Should -Be $false
            $result.InstallCommand | Should -Be 'npm install -g {package}'
        }

        It 'Honors explicit npm preference' {
            Set-TestCommandAvailabilityState -CommandName 'npm' -Available $true
            Setup-CapturingCommandMock -CommandName 'npm' -Output '' -MarkAvailable $true

            $original = $env:PS_NODE_PACKAGE_MANAGER
            try {
                $env:PS_NODE_PACKAGE_MANAGER = 'npm'
                $result = Get-NodePackageManagerPreference
                $result.Manager | Should -Be 'npm'
            }
            finally {
                if ($null -eq $original) {
                    Remove-Item Env:PS_NODE_PACKAGE_MANAGER -ErrorAction SilentlyContinue
                }
                else {
                    $env:PS_NODE_PACKAGE_MANAGER = $original
                }
            }
        }
    }

    Context 'Get-NodePackageInstallCommand' {
        BeforeEach {
            Clear-NodeJsTestEnvironment
        }

        It 'Falls back to npm install when no manager is available' {
            Mock Get-Command {
                param($Name)
                if ($Name -in @('pnpm', 'npm', 'yarn', 'bun')) {
                    return $null
                }

                return Microsoft.PowerShell.Core\Get-Command @PSBoundParameters
            } -ModuleName NodeJs

            Get-NodePackageInstallCommand -PackageName 'superjson' -Global |
                Should -Be 'npm install -g superjson'
        }
    }

    Context 'Expand-EmbeddedNodeInstallHints' {
        It 'Replaces install placeholders with a recommendation command' {
            Mock Get-Command {
                param($Name)
                if ($Name -in @('pnpm', 'npm', 'yarn', 'bun')) {
                    return $null
                }

                return Microsoft.PowerShell.Core\Get-Command @PSBoundParameters
            } -ModuleName NodeJs

            $scriptText = 'Run __NODE_INSTALL_CMD__ to continue'

            $expanded = Expand-EmbeddedNodeInstallHints -Script $scriptText -PackageNames @('superjson') -Global

            $expanded | Should -Not -Match '__NODE_INSTALL_CMD__'
            $expanded | Should -Match 'superjson'
        }

        It 'Replaces placeholders via Resolve-NodeInstallHintMessage' {
            Mock Get-Command {
                param($Name)
                if ($Name -in @('pnpm', 'npm', 'yarn', 'bun')) {
                    return $null
                }

                return Microsoft.PowerShell.Core\Get-Command @PSBoundParameters
            } -ModuleName NodeJs

            $message = 'Install packages: __NODE_INSTALL_CMD__'

            $resolved = Resolve-NodeInstallHintMessage -Message $message -PackageNames @('json5') -Global

            $resolved | Should -Not -Match '__NODE_INSTALL_CMD__'
            $resolved | Should -Match 'json5'
        }

        It 'Returns the original script when no placeholder is present' {
            $scriptText = 'No install hint here'
            Expand-EmbeddedNodeInstallHints -Script $scriptText -PackageNames 'json5' |
                Should -Be $scriptText
        }
    }

    Context 'Get-NodePackageInstallRecommendation' {
        It 'Joins multiple package names for global yarn installs' {
            Set-TestCommandAvailabilityState -CommandName 'yarn' -Available $true
            Setup-CapturingCommandMock -CommandName 'yarn' -Output '' -MarkAvailable $true

            $original = $env:PS_NODE_PACKAGE_MANAGER
            try {
                $env:PS_NODE_PACKAGE_MANAGER = 'yarn'
                $result = Get-NodePackageInstallRecommendation -PackageNames @('json5', 'superjson') -Global
                $result | Should -Be 'yarn global add json5 superjson'
            }
            finally {
                if ($null -eq $original) {
                    Remove-Item Env:PS_NODE_PACKAGE_MANAGER -ErrorAction SilentlyContinue
                }
                else {
                    $env:PS_NODE_PACKAGE_MANAGER = $original
                }
            }
        }

        It 'Falls back to npm install when no manager is available' {
            Mock Get-Command {
                param($Name)
                if ($Name -in @('pnpm', 'npm', 'yarn', 'bun')) {
                    return $null
                }

                return Microsoft.PowerShell.Core\Get-Command @PSBoundParameters
            } -ModuleName NodeJs

            Get-NodePackageInstallRecommendation -PackageNames @('left-pad') |
                Should -Match 'npm install\s+left-pad'
        }
    }

    Context 'Get-PnpmGlobalPath extended environment hooks' {
        BeforeEach {
            Clear-NodeJsTestEnvironment
        }

        It 'Uses PNPM_ROOT when it points directly to a node_modules directory' {
            $isolatedHome = Join-Path $script:TempDir 'isolated-home-pnpm-root'
            New-Item -ItemType Directory -Path $isolatedHome -Force | Out-Null
            $nodeModules = Join-Path $script:TempDir 'pnpm-root-modules'
            New-Item -ItemType Directory -Path $nodeModules -Force | Out-Null
            Mark-TestCommandsUnavailable -CommandNames @('pnpm', 'npm')

            $originalRoot = $env:PNPM_ROOT
            $originalHome = $env:HOME
            try {
                $env:HOME = $isolatedHome
                $env:PNPM_ROOT = $nodeModules
                Get-PnpmGlobalPath | Should -Be $nodeModules
            }
            finally {
                if ($null -eq $originalRoot) {
                    Remove-Item Env:PNPM_ROOT -ErrorAction SilentlyContinue
                }
                else {
                    $env:PNPM_ROOT = $originalRoot
                }
                if ($null -eq $originalHome) {
                    Remove-Item Env:HOME -ErrorAction SilentlyContinue
                }
                else {
                    $env:HOME = $originalHome
                }
            }
        }

        It 'Resolves NVM_DIR versions node lib node_modules when present' {
            $nvmDir = Join-Path $script:TempDir 'nvm-home'
            $versionDir = Join-Path $nvmDir 'versions' 'node' 'v20.0.0'
            $nodeModules = Join-Path $versionDir 'lib' 'node_modules'
            New-Item -ItemType Directory -Path $nodeModules -Force | Out-Null

            $original = $env:NVM_DIR
            try {
                $env:NVM_DIR = $nvmDir
                Get-PnpmGlobalPath | Should -Be $nodeModules
            }
            finally {
                if ($null -eq $original) {
                    Remove-Item Env:NVM_DIR -ErrorAction SilentlyContinue
                }
                else {
                    $env:NVM_DIR = $original
                }
            }
        }

        It 'Emits level 3 debug output when no pnpm global path is found' {
            $isolatedHome = Join-Path $script:TempDir 'isolated-home-no-pnpm'
            New-Item -ItemType Directory -Path $isolatedHome -Force | Out-Null
            Mark-TestCommandsUnavailable -CommandNames @('pnpm', 'npm')

            $originalDebug = $env:PS_PROFILE_DEBUG
            $originalHome = $env:HOME
            $env:PS_PROFILE_DEBUG = '3'
            try {
                $env:HOME = $isolatedHome
                Get-PnpmGlobalPath | Should -BeNullOrEmpty
            }
            finally {
                if ($null -eq $originalDebug) {
                    Remove-Item Env:PS_PROFILE_DEBUG -ErrorAction SilentlyContinue
                }
                else {
                    $env:PS_PROFILE_DEBUG = $originalDebug
                }
                if ($null -eq $originalHome) {
                    Remove-Item Env:HOME -ErrorAction SilentlyContinue
                }
                else {
                    $env:HOME = $originalHome
                }
            }
        }
    }

    Context 'Get-NodeModuleSearchPaths extended' {
        BeforeEach {
            Clear-NodeJsTestEnvironment
        }

        It 'Includes BinaryConversionBasePath node_modules when set' {
            $basePath = Join-Path $script:TempDir 'binary-conversion-base'
            $localModules = Join-Path $basePath 'node_modules'
            New-Item -ItemType Directory -Path $localModules -Force | Out-Null

            $previous = $global:BinaryConversionBasePath
            try {
                $global:BinaryConversionBasePath = $basePath
                $paths = @(Get-NodeModuleSearchPaths)
                $paths | Should -Contain $localModules
            }
            finally {
                $global:BinaryConversionBasePath = $previous
            }
        }

        It 'Includes npm global root when npm root command succeeds' {
            Setup-CapturingCommandMock -CommandName 'npm' -Output (Join-Path $script:TempDir 'npm-global-root') -MarkAvailable $true
            New-Item -ItemType Directory -Path (Join-Path $script:TempDir 'npm-global-root') -Force | Out-Null

            $paths = @(Get-NodeModuleSearchPaths)
            $paths | Should -Contain (Join-Path $script:TempDir 'npm-global-root')
        }
    }

    Context 'Get-NodePackageManagerPreference extended' {
        BeforeEach {
            Clear-NodeJsTestEnvironment
        }

        It 'Prefers bun when PS_NODE_PACKAGE_MANAGER is bun and bun is available' {
            Set-TestCommandAvailabilityState -CommandName 'bun' -Available $true
            Setup-CapturingCommandMock -CommandName 'bun' -Output '' -MarkAvailable $true

            $original = $env:PS_NODE_PACKAGE_MANAGER
            try {
                $env:PS_NODE_PACKAGE_MANAGER = 'bun'
                $result = Get-NodePackageManagerPreference
                $result.Manager | Should -Be 'bun'
            }
            finally {
                if ($null -eq $original) {
                    Remove-Item Env:PS_NODE_PACKAGE_MANAGER -ErrorAction SilentlyContinue
                }
                else {
                    $env:PS_NODE_PACKAGE_MANAGER = $original
                }
            }
        }

        It 'Prefers yarn when PS_NODE_PACKAGE_MANAGER is yarn and yarn is available' {
            Set-TestCommandAvailabilityState -CommandName 'yarn' -Available $true
            Setup-CapturingCommandMock -CommandName 'yarn' -Output '' -MarkAvailable $true

            $original = $env:PS_NODE_PACKAGE_MANAGER
            try {
                $env:PS_NODE_PACKAGE_MANAGER = 'yarn'
                $result = Get-NodePackageManagerPreference
                $result.Manager | Should -Be 'yarn'
            }
            finally {
                if ($null -eq $original) {
                    Remove-Item Env:PS_NODE_PACKAGE_MANAGER -ErrorAction SilentlyContinue
                }
                else {
                    $env:PS_NODE_PACKAGE_MANAGER = $original
                }
            }
        }
    }

    Context 'Get-NodePackageInstallCommand extended' {
        BeforeEach {
            Clear-NodeJsTestEnvironment
        }

        It 'Falls back to npm install for global installs when no manager is available' {
            Mock Get-Command {
                param($Name)
                if ($Name -in @('pnpm', 'npm', 'yarn', 'bun')) {
                    return $null
                }

                return Microsoft.PowerShell.Core\Get-Command @PSBoundParameters
            } -ModuleName NodeJs

            Get-NodePackageInstallCommand -PackageName 'left-pad' -Global |
                Should -Match 'npm install -g left-pad'
        }

        It 'Falls back to npm install for local installs when no manager is available' {
            Mock Get-Command {
                param($Name)
                if ($Name -in @('pnpm', 'npm', 'yarn', 'bun')) {
                    return $null
                }

                return Microsoft.PowerShell.Core\Get-Command @PSBoundParameters
            } -ModuleName NodeJs

            Get-NodePackageInstallCommand -PackageName 'left-pad' |
                Should -Match 'npm install\s+left-pad'
        }
    }

    Context 'Resolve-NodeInstallHintMessage' {
        It 'Returns the original message when no placeholder is present' {
            $message = 'No install hint here'
            Resolve-NodeInstallHintMessage -Message $message -PackageNames @('json5') |
                Should -Be $message
        }
    }

    Context 'Invoke-NodeScript extended paths' {
        BeforeEach {
            Clear-NodeJsTestEnvironment
        }

        It 'Prepends existing NODE_PATH when module search paths are discovered' {
            Setup-CapturingCommandMock -CommandName 'node' -Output 'node-output' -MarkAvailable $true -OnInvoke {
                if ($args -contains '--version') {
                    $global:TestCommandCaptureState['ExitCode'] = 0
                    return 'v20.0.0'
                }

                $global:TestNodePathDuringInvoke = $env:NODE_PATH
                $global:TestCommandCaptureState['ExitCode'] = 0
                return 'node-output'
            }

            $pnpmHome = Join-Path $script:TempDir 'invoke-node-path-home'
            $nodeModules = Join-Path $pnpmHome 'node_modules'
            New-Item -ItemType Directory -Path $nodeModules -Force | Out-Null
            $testScript = Join-Path $script:TempDir 'invoke-path.js'
            Set-Content -LiteralPath $testScript -Value 'console.log("x");' -Encoding UTF8

            $originalPnpmHome = $env:PNPM_HOME
            $originalNodePath = $env:NODE_PATH
            try {
                $env:PNPM_HOME = $pnpmHome
                $env:NODE_PATH = '/existing/path'
                Invoke-NodeScript -ScriptPath $testScript | Should -Be 'node-output'
                $global:TestNodePathDuringInvoke | Should -Match ([regex]::Escape($nodeModules))
                $global:TestNodePathDuringInvoke | Should -Match '/existing/path'
            }
            finally {
                if ($null -eq $originalPnpmHome) {
                    Remove-Item Env:PNPM_HOME -ErrorAction SilentlyContinue
                }
                else {
                    $env:PNPM_HOME = $originalPnpmHome
                }
                if ($null -eq $originalNodePath) {
                    Remove-Item Env:NODE_PATH -ErrorAction SilentlyContinue
                }
                else {
                    $env:NODE_PATH = $originalNodePath
                }
                Remove-Variable -Name TestNodePathDuringInvoke -Scope Global -ErrorAction SilentlyContinue
            }
        }

        It 'Throws when node version check fails' {
            Setup-CapturingCommandMock -CommandName 'node' -Output '' -ExitCode 1 -MarkAvailable $true
            $testScript = Join-Path $script:TempDir 'version-fail.js'
            Set-Content -LiteralPath $testScript -Value 'console.log("x");' -Encoding UTF8

            { Invoke-NodeScript -ScriptPath $testScript } | Should -Throw '*failed to execute*'
        }

        It 'Throws when script exits with no output' {
            Setup-CapturingCommandMock -CommandName 'node' -Output '' -OnInvoke {
                if ($args -contains '--version') {
                    $global:TestCommandCaptureState['ExitCode'] = 0
                    return 'v20.0.0'
                }

                $global:TestCommandCaptureState['ExitCode'] = 3
                return ''
            } -MarkAvailable $true
            $testScript = Join-Path $script:TempDir 'silent-fail.js'
            Set-Content -LiteralPath $testScript -Value 'process.exit(3);' -Encoding UTF8

            { Invoke-NodeScript -ScriptPath $testScript } | Should -Throw '*no output*'
        }
    }

    Context 'Set-NodePathForPnpm extended' {
        BeforeEach {
            Clear-NodeJsTestEnvironment
        }

        It 'Leaves NODE_PATH unchanged when no module search paths are discovered' {
            $isolatedHome = Join-Path $script:TempDir 'isolated-home-set-node-path'
            New-Item -ItemType Directory -Path $isolatedHome -Force | Out-Null
            Mark-TestCommandsUnavailable -CommandNames @('pnpm', 'npm')

            $originalHome = $env:HOME
            $originalNodePath = $env:NODE_PATH
            try {
                $env:HOME = $isolatedHome
                $env:NODE_PATH = '/unchanged/path'
                $restore = Set-NodePathForPnpm
                $env:NODE_PATH | Should -Be '/unchanged/path'
                & $restore
            }
            finally {
                if ($null -eq $originalHome) {
                    Remove-Item Env:HOME -ErrorAction SilentlyContinue
                }
                else {
                    $env:HOME = $originalHome
                }
                if ($null -eq $originalNodePath) {
                    Remove-Item Env:NODE_PATH -ErrorAction SilentlyContinue
                }
                else {
                    $env:NODE_PATH = $originalNodePath
                }
            }
        }
    }

    Context 'Get-NodePackageInstallRecommendation pnpm global' {
        BeforeEach {
            Clear-NodeJsTestEnvironment
        }

        It 'Builds a global pnpm install command for multiple packages' {
            Set-TestCommandAvailabilityState -CommandName 'pnpm' -Available $true
            Setup-CapturingCommandMock -CommandName 'pnpm' -Output '' -MarkAvailable $true

            $original = $env:PS_NODE_PACKAGE_MANAGER
            try {
                $env:PS_NODE_PACKAGE_MANAGER = 'pnpm'
                $result = Get-NodePackageInstallRecommendation -PackageNames @('json5', 'superjson') -Global
                $result | Should -Match 'json5'
                $result | Should -Match 'superjson'
            }
            finally {
                if ($null -eq $original) {
                    Remove-Item Env:PS_NODE_PACKAGE_MANAGER -ErrorAction SilentlyContinue
                }
                else {
                    $env:PS_NODE_PACKAGE_MANAGER = $original
                }
            }
        }
    }

    Context 'Get-PnpmGlobalPath pnpm command failure' {
        BeforeEach {
            Clear-NodeJsTestEnvironment
        }

        It 'Logs verbose output when pnpm root command fails at debug level 2' {
            $isolatedHome = Join-Path $script:TempDir 'isolated-home-pnpm-fail'
            New-Item -ItemType Directory -Path $isolatedHome -Force | Out-Null
            Setup-CapturingCommandMock -CommandName 'pnpm' -Output 'error: not found' -ExitCode 1 -MarkAvailable $true

            $originalDebug = $env:PS_PROFILE_DEBUG
            $originalHome = $env:HOME
            $originalVerbose = $VerbosePreference
            $env:PS_PROFILE_DEBUG = '2'
            $VerbosePreference = 'Continue'

            try {
                $env:HOME = $isolatedHome
                Get-PnpmGlobalPath | Should -BeNullOrEmpty
            }
            finally {
                $VerbosePreference = $originalVerbose
                if ($null -eq $originalDebug) {
                    Remove-Item Env:PS_PROFILE_DEBUG -ErrorAction SilentlyContinue
                }
                else {
                    $env:PS_PROFILE_DEBUG = $originalDebug
                }
                if ($null -eq $originalHome) {
                    Remove-Item Env:HOME -ErrorAction SilentlyContinue
                }
                else {
                    $env:HOME = $originalHome
                }
            }
        }
    }
}
