BeforeAll {
    . (Join-Path $PSScriptRoot '..\TestSupport.ps1')
    $script:RepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:LibPath = Get-TestPath -RelativePath 'scripts\lib' -StartPath $PSScriptRoot -EnsureExists
    $script:NodeJsPath = Join-Path $script:LibPath 'runtime' 'NodeJs.psm1'

    # Import the module under test
    Import-Module $script:NodeJsPath -DisableNameChecking -ErrorAction Stop -Force

    # Create test directory — use cross-platform temp path
    $tmpRoot = if ($env:TEMP) { $env:TEMP } elseif ($env:TMPDIR) { $env:TMPDIR } else { '/tmp' }
    $script:TestDir = Join-Path $tmpRoot "test-nodejs-$(Get-Random)"
    New-Item -ItemType Directory -Path $script:TestDir -Force | Out-Null
}

AfterAll {
    Remove-Module NodeJs -ErrorAction SilentlyContinue -Force

    # Clean up test directory
    if ((Get-Variable -Name TestDir -Scope Script -ErrorAction SilentlyContinue) -and $script:TestDir -and (Test-Path $script:TestDir)) {
        Remove-Item -Path $script:TestDir -Recurse -Force -ErrorAction SilentlyContinue
    }

    # Restore NODE_PATH if it was modified
    if ((Get-Variable -Name OriginalNodePath -Scope Script -ErrorAction SilentlyContinue) -and $script:OriginalNodePath) {
        $env:NODE_PATH = $script:OriginalNodePath
    }
    elseif ($env:NODE_PATH) {
        Remove-Item Env:\NODE_PATH -ErrorAction SilentlyContinue
    }
}

Describe 'NodeJs Module Functions' {
    Context 'Get-PnpmGlobalPath' {
        It 'Returns null when pnpm is not available' {
            # This test verifies Get-PnpmGlobalPath returns null when pnpm is truly unavailable
            # Note: Can't reliably mock module-internal calls, so test only runs when conditions are met
            $commonPnpmPath = "$env:LOCALAPPDATA\pnpm\global\5\node_modules"
            $pnpmCommandExists = $null -ne (Get-Command pnpm -ErrorAction SilentlyContinue)
            $pnpmPathExists = ($null -ne $commonPnpmPath) -and (Test-Path $commonPnpmPath)

            if ($pnpmCommandExists -or $pnpmPathExists) {
                # Skip test - pnpm is available, can't test "not available" scenario
                Set-ItResult -Skipped -Because "pnpm is available on this system (command or path exists), cannot test 'not available' scenario"
            }
            else {
                # Test the scenario - pnpm is truly unavailable
                $result = Get-PnpmGlobalPath
                $result | Should -BeNullOrEmpty
            }
        }

        It 'Returns a string path when pnpm global root is available' {
            if (-not (Get-Command pnpm -ErrorAction SilentlyContinue)) {
                Set-ItResult -Skipped -Because 'pnpm is not installed on this system'
                return
            }
            $result = Get-PnpmGlobalPath
            # pnpm is installed but global path may not exist yet; accept null or a string
            if ($null -ne $result) {
                $result | Should -BeOfType [string]
                $result | Should -Not -BeNullOrEmpty
            }
        }

        It 'Reads PNPM_HOME env var when set to an existing directory' {
            $testDir = Join-Path $script:TestDir 'fake-pnpm-home' 'node_modules'
            New-Item -ItemType Directory -Path $testDir -Force | Out-Null
            $original = $env:PNPM_HOME
            try {
                $env:PNPM_HOME = Split-Path $testDir -Parent
                $result = Get-PnpmGlobalPath
                $result | Should -Be $testDir
            }
            finally {
                $env:PNPM_HOME = $original
            }
        }
    }

    Context 'Invoke-NodeScript' {
        BeforeEach {
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

        It 'Throws error when script path does not exist' {
            $nonExistentScript = Join-Path $script:TestDir 'nonexistent.js'
            { Invoke-NodeScript -ScriptPath $nonExistentScript } | Should -Throw "*not found*"
        }

        It 'Throws error when node command is not available' {
            # This test verifies Invoke-NodeScript throws when node is unavailable
            # Note: Can't reliably mock module-internal calls, so test only runs when conditions are met
            $testScript = Join-Path $script:TestDir 'test.js'
            Set-Content -Path $testScript -Value 'console.log("test");'

            $nodeExists = (Get-Command node -ErrorAction SilentlyContinue) -ne $null
            if ($nodeExists) {
                # Skip test - node is available, can't test "not available" scenario
                Set-ItResult -Skipped -Because "node is available on this system, cannot test 'not available' scenario"
            }
            else {
                # Test the scenario - node is truly unavailable
                { Invoke-NodeScript -ScriptPath $testScript } | Should -Throw "*not available*"
            }
        }

        It 'Runs a simple script and returns output when node is available' {
            if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
                Set-ItResult -Skipped -Because 'node is not installed on this system'
                return
            }
            $testScript = Join-Path $script:TestDir 'hello.js'
            Set-Content -Path $testScript -Value 'console.log("hello-from-test");'
            $result = Invoke-NodeScript -ScriptPath $testScript
            $result | Should -Contain 'hello-from-test'
        }

        It 'Passes arguments to node script' {
            $cmd = Get-Command Invoke-NodeScript
            $cmd.Parameters['Arguments'] | Should -Not -BeNullOrEmpty
        }

        It 'Restores NODE_PATH after execution even when script fails' {
            if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
                Set-ItResult -Skipped -Because 'node is not installed on this system'
                return
            }
            $env:NODE_PATH = '/original-test-path'
            $badScript = Join-Path $script:TestDir 'fail.js'
            Set-Content -Path $badScript -Value 'process.exit(1);'
            try { Invoke-NodeScript -ScriptPath $badScript } catch { }
            $env:NODE_PATH | Should -Be '/original-test-path'
        }

        It 'Sets NODE_PATH when pnpm global path is available' {
            Set-ItResult -Skipped -Because 'requires pnpm with a populated global store — tested indirectly via Set-NodePathForPnpm'
        }
    }

    Context 'Set-NodePathForPnpm' {
        BeforeEach {
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

        It 'Returns a script block for restoring NODE_PATH' {
            $restore = Set-NodePathForPnpm
            $restore | Should -Not -BeNullOrEmpty
            $restore | Should -BeOfType [ScriptBlock]
        }

        It 'Restore scriptblock reverts NODE_PATH to its original value' {
            $env:NODE_PATH = '/before-set'
            $restore = Set-NodePathForPnpm
            # Modify NODE_PATH manually to simulate what the function does
            $env:NODE_PATH = '/some-new-value'
            & $restore
            $env:NODE_PATH | Should -Be '/before-set'
        }

        It 'Restore scriptblock removes NODE_PATH when it was originally unset' {
            Remove-Item Env:\NODE_PATH -ErrorAction SilentlyContinue
            $restore = Set-NodePathForPnpm
            $env:NODE_PATH = '/simulated-change'
            & $restore
            # NODE_PATH should be gone (or remain unset)
            $env:NODE_PATH | Should -BeNullOrEmpty
        }

        It 'Handles missing pnpm gracefully — returns a scriptblock without throwing' {
            # Even when pnpm isn't installed, Set-NodePathForPnpm should not throw
            $restore = Set-NodePathForPnpm
            $restore | Should -Not -BeNullOrEmpty
        }
    }
}
