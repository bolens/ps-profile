<#
tests/unit/library-envfile-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for Load-EnvFile preservation and parsing rules.
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
    $libPath = Get-TestPath -RelativePath 'scripts\lib' -StartPath $PSScriptRoot -EnsureExists
    Import-Module (Join-Path $libPath 'utilities' 'EnvFile.psm1') -DisableNameChecking -Force

    $script:TempRoot = New-TestTempDirectory -Prefix 'EnvFileExtended'
    $script:RepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:ProfileDir = Join-Path $script:RepoRoot 'profile.d'
}

AfterAll {
    Remove-Module EnvFile -ErrorAction SilentlyContinue -Force

    if ($script:TempRoot -and (Test-Path -LiteralPath $script:TempRoot)) {
        Remove-Item -LiteralPath $script:TempRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Describe 'EnvFile extended scenarios' {
    Context 'Load-EnvFile' {
        It 'Preserves existing environment variables unless Overwrite is specified' {
            $envFile = Join-Path $script:TempRoot 'preserve.env'
            'PRESERVE_ME=from-file' | Set-Content -LiteralPath $envFile -Encoding UTF8

            $env:PRESERVE_ME = 'existing-value'
            try {
                Load-EnvFile -EnvFilePath $envFile
                $env:PRESERVE_ME | Should -Be 'existing-value'
            }
            finally {
                Remove-Item Env:\PRESERVE_ME -ErrorAction SilentlyContinue
            }
        }

        It 'Overwrites existing environment variables when requested' {
            $envFile = Join-Path $script:TempRoot 'overwrite.env'
            'OVERWRITE_ME=replaced' | Set-Content -LiteralPath $envFile -Encoding UTF8

            $env:OVERWRITE_ME = 'original-value'
            try {
                Load-EnvFile -EnvFilePath $envFile -Overwrite
                $env:OVERWRITE_ME | Should -Be 'replaced'
            }
            finally {
                Remove-Item Env:\OVERWRITE_ME -ErrorAction SilentlyContinue
            }
        }

        It 'Skips lines that do not contain an assignment' {
            $envFile = Join-Path $script:TempRoot 'invalid-lines.env'
            @'
NOT_AN_ASSIGNMENT
VALID_VAR=loaded
'@ | Set-Content -LiteralPath $envFile -Encoding UTF8

            try {
                Load-EnvFile -EnvFilePath $envFile
                $env:VALID_VAR | Should -Be 'loaded'
                Get-Item Env:\NOT_AN_ASSIGNMENT -ErrorAction SilentlyContinue | Should -BeNullOrEmpty
            }
            finally {
                Remove-Item Env:\VALID_VAR -ErrorAction SilentlyContinue
            }
        }

        It 'Ignores comment-only lines mixed with assignments' {
            $envFile = Join-Path $script:TempRoot 'comments.env'
            @'
# comment line
COMMENTED_PAIR=kept
'@ | Set-Content -LiteralPath $envFile -Encoding UTF8

            try {
                Load-EnvFile -EnvFilePath $envFile
                $env:COMMENTED_PAIR | Should -Be 'kept'
            }
            finally {
                Remove-Item Env:\COMMENTED_PAIR -ErrorAction SilentlyContinue
            }
        }

        It 'Emits debug tracing when skipping existing variables at debug level 3' {
            $envFile = Join-Path $script:TempRoot 'debug-skip.env'
            'DEBUG_SKIP_VAR=file-value' | Set-Content -LiteralPath $envFile -Encoding UTF8
            $env:DEBUG_SKIP_VAR = 'preset'
            $originalDebug = $env:PS_PROFILE_DEBUG
            $env:PS_PROFILE_DEBUG = '3'

            try {
                Load-EnvFile -EnvFilePath $envFile
                $env:DEBUG_SKIP_VAR | Should -Be 'preset'
            }
            finally {
                Remove-Item Env:\DEBUG_SKIP_VAR -ErrorAction SilentlyContinue
                if ($null -eq $originalDebug) {
                    Remove-Item Env:PS_PROFILE_DEBUG -ErrorAction SilentlyContinue
                }
                else {
                    $env:PS_PROFILE_DEBUG = $originalDebug
                }
            }
        }

        It 'Warns on load failures when ErrorAction is Continue and debug is enabled' {
            Enable-TestStructuredLogging
            $envFile = Join-Path $script:TempRoot 'continue-error.env'
            'GOOD_VAR=ok' | Set-Content -LiteralPath $envFile -Encoding UTF8
            $originalDebug = $env:PS_PROFILE_DEBUG
            $env:PS_PROFILE_DEBUG = '1'

            $global:EnvFileContinueTestPath = $envFile
            try {
                InModuleScope -ModuleName EnvFile {
                    Mock Get-Content {
                        throw 'env read failure probe'
                    }

                    { Load-EnvFile -EnvFilePath $global:EnvFileContinueTestPath -ErrorAction Continue } | Should -Not -Throw
                }
            }
            finally {
                Remove-Variable -Name EnvFileContinueTestPath -Scope Global -ErrorAction SilentlyContinue
                if ($null -eq $originalDebug) {
                    Remove-Item Env:PS_PROFILE_DEBUG -ErrorAction SilentlyContinue
                }
                else {
                    $env:PS_PROFILE_DEBUG = $originalDebug
                }
            }
        }

        It 'Uses manual path validation when Test-ValidPath is unavailable' {
            Remove-Module Validation -ErrorAction SilentlyContinue -Force
            $missingFile = Join-Path $script:TempRoot 'missing-manual.env'

            try {
                { Load-EnvFile -EnvFilePath $missingFile -ErrorAction Stop } | Should -Throw '*Environment file not found*'
            }
            finally {
                Import-Module (Join-Path (Get-TestPath -RelativePath 'scripts\lib' -StartPath $PSScriptRoot -EnsureExists) 'core' 'Validation.psm1') -DisableNameChecking -Force
            }
        }

        It 'Returns silently when the env file is missing and ErrorAction is SilentlyContinue' {
            $missingFile = Join-Path $script:TempRoot 'missing-silent.env'

            { Load-EnvFile -EnvFilePath $missingFile } | Should -Not -Throw
        }

        It 'Returns without error for empty env files' {
            $envFile = Join-Path $script:TempRoot 'empty.env'
            Set-Content -LiteralPath $envFile -Value '' -Encoding UTF8

            { Load-EnvFile -EnvFilePath $envFile } | Should -Not -Throw
        }

        It 'Parses double-quoted values and unescapes embedded quotes' {
            $envFile = Join-Path $script:TempRoot 'quoted-double.env'
            @'
QUOTED_DOUBLE="say \"hello\""
'@ | Set-Content -LiteralPath $envFile -Encoding UTF8

            try {
                Load-EnvFile -EnvFilePath $envFile
                $env:QUOTED_DOUBLE | Should -Be 'say "hello"'
            }
            finally {
                Remove-Item Env:\QUOTED_DOUBLE -ErrorAction SilentlyContinue
            }
        }

        It 'Parses single-quoted values' {
            $envFile = Join-Path $script:TempRoot 'quoted-single.env'
            "QUOTED_SINGLE='plain value'" | Set-Content -LiteralPath $envFile -Encoding UTF8

            try {
                Load-EnvFile -EnvFilePath $envFile
                $env:QUOTED_SINGLE | Should -Be 'plain value'
            }
            finally {
                Remove-Item Env:\QUOTED_SINGLE -ErrorAction SilentlyContinue
            }
        }

        It 'Expands environment variables referenced in values' {
            $envFile = Join-Path $script:TempRoot 'expand.env'
            'EXPANDED_VALUE=$EXPAND_SOURCE' | Set-Content -LiteralPath $envFile -Encoding UTF8
            $env:EXPAND_SOURCE = 'resolved'

            try {
                Load-EnvFile -EnvFilePath $envFile
                $env:EXPANDED_VALUE | Should -Be 'resolved'
            }
            finally {
                Remove-Item Env:\EXPANDED_VALUE, Env:\EXPAND_SOURCE -ErrorAction SilentlyContinue
            }
        }

        It 'Emits debug tracing when loading variables at debug level 3' {
            $envFile = Join-Path $script:TempRoot 'debug-load.env'
            'DEBUG_LOAD_VAR=loaded' | Set-Content -LiteralPath $envFile -Encoding UTF8
            $originalDebug = $env:PS_PROFILE_DEBUG
            $env:PS_PROFILE_DEBUG = '3'

            try {
                Load-EnvFile -EnvFilePath $envFile
                $env:DEBUG_LOAD_VAR | Should -Be 'loaded'
            }
            finally {
                Remove-Item Env:\DEBUG_LOAD_VAR -ErrorAction SilentlyContinue
                if ($null -eq $originalDebug) {
                    Remove-Item Env:PS_PROFILE_DEBUG -ErrorAction SilentlyContinue
                }
                else {
                    $env:PS_PROFILE_DEBUG = $originalDebug
                }
            }
        }

        It 'Rethrows load failures when ErrorAction is Stop' {
            Enable-TestStructuredLogging
            $envFile = Join-Path $script:TempRoot 'stop-error.env'
            'GOOD_VAR=ok' | Set-Content -LiteralPath $envFile -Encoding UTF8

            $global:EnvFileStopTestPath = $envFile
            try {
                InModuleScope -ModuleName EnvFile {
                    Mock Get-Content {
                        throw 'env read failure stop probe'
                    }

                    { Load-EnvFile -EnvFilePath $global:EnvFileStopTestPath -ErrorAction Stop } |
                        Should -Throw '*Failed to load environment file*'
                }
            }
            finally {
                Remove-Variable -Name EnvFileStopTestPath -Scope Global -ErrorAction SilentlyContinue
            }
        }
    }

    Context 'Initialize-EnvFiles' {
        It 'Emits initialize tracing when PS_PROFILE_DEBUG is level 2' {
            $repoRoot = Join-Path $script:TempRoot 'debug-init-repo'
            New-Item -ItemType Directory -Path $repoRoot -Force | Out-Null
            'INIT_DEBUG_VAR=loaded' | Set-Content -LiteralPath (Join-Path $repoRoot '.env') -Encoding UTF8
            $originalDebug = $env:PS_PROFILE_DEBUG
            $env:PS_PROFILE_DEBUG = '2'

            try {
                Initialize-EnvFiles -RepoRoot $repoRoot
                $env:INIT_DEBUG_VAR | Should -Be 'loaded'
            }
            finally {
                Remove-Item Env:\INIT_DEBUG_VAR -ErrorAction SilentlyContinue
                if ($null -eq $originalDebug) {
                    Remove-Item Env:PS_PROFILE_DEBUG -ErrorAction SilentlyContinue
                }
                else {
                    $env:PS_PROFILE_DEBUG = $originalDebug
                }
            }
        }

        It 'Detects repository root by walking parent directories for .git' {
            $repoRoot = Join-Path $script:TempRoot 'walk-git-repo'
            $nestedDir = Join-Path $repoRoot 'nested' 'deep'
            New-Item -ItemType Directory -Path $nestedDir -Force | Out-Null
            New-Item -ItemType File -Path (Join-Path $repoRoot '.git') -Force | Out-Null
            'WALK_VAR=detected' | Set-Content -LiteralPath (Join-Path $repoRoot '.env') -Encoding UTF8

            $previousLocation = Get-Location
            try {
                Set-Location -LiteralPath $nestedDir
                Initialize-EnvFiles
                $env:WALK_VAR | Should -Be 'detected'
            }
            finally {
                Set-Location -LiteralPath $previousLocation.Path
                Remove-Item Env:\WALK_VAR -ErrorAction SilentlyContinue
            }
        }

        It 'Returns early when the repository root cannot be validated' {
            $originalDebug = $env:PS_PROFILE_DEBUG
            $env:PS_PROFILE_DEBUG = '2'

            try {
                { Initialize-EnvFiles -RepoRoot (Join-Path $script:TempRoot 'missing-repo-dir') } | Should -Not -Throw
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

        It 'Loads .env.local with overwrite after the base .env file' {
            $repoRoot = Join-Path $script:TempRoot 'local-override-repo'
            New-Item -ItemType Directory -Path $repoRoot -Force | Out-Null
            'SHARED_VAR=base' | Set-Content -LiteralPath (Join-Path $repoRoot '.env') -Encoding UTF8
            'SHARED_VAR=local' | Set-Content -LiteralPath (Join-Path $repoRoot '.env.local') -Encoding UTF8

            try {
                Initialize-EnvFiles -RepoRoot $repoRoot
                $env:SHARED_VAR | Should -Be 'local'
            }
            finally {
                Remove-Item Env:\SHARED_VAR -ErrorAction SilentlyContinue
            }
        }

        It 'Emits level 3 tracing when env files are missing' {
            $repoRoot = Join-Path $script:TempRoot 'missing-env-files-repo'
            New-Item -ItemType Directory -Path $repoRoot -Force | Out-Null
            $originalDebug = $env:PS_PROFILE_DEBUG
            $env:PS_PROFILE_DEBUG = '3'

            try {
                { Initialize-EnvFiles -RepoRoot $repoRoot } | Should -Not -Throw
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

        It 'Uses Get-RepoRoot when RepoRoot is omitted and a caller script path is available' {
            $repoRoot = Join-Path $script:TempRoot 'get-repo-root-repo'
            New-Item -ItemType Directory -Path $repoRoot -Force | Out-Null
            'REPO_ROOT_VAR=detected' | Set-Content -LiteralPath (Join-Path $repoRoot '.env') -Encoding UTF8

            function global:Get-RepoRoot {
                param([string]$ScriptPath)
                return $repoRoot
            }

            try {
                Initialize-EnvFiles
                $env:REPO_ROOT_VAR | Should -Be 'detected'
            }
            finally {
                Remove-Item Env:\REPO_ROOT_VAR -ErrorAction SilentlyContinue
                Remove-Item Function:\Get-RepoRoot -ErrorAction SilentlyContinue
            }
        }

        It 'Reports successful initialization at debug level 2 when files are loaded' {
            $repoRoot = Join-Path $script:TempRoot 'success-init-repo'
            New-Item -ItemType Directory -Path $repoRoot -Force | Out-Null
            'SUCCESS_INIT_VAR=loaded' | Set-Content -LiteralPath (Join-Path $repoRoot '.env') -Encoding UTF8
            'SUCCESS_LOCAL_VAR=local' | Set-Content -LiteralPath (Join-Path $repoRoot '.env.local') -Encoding UTF8
            $originalDebug = $env:PS_PROFILE_DEBUG
            $env:PS_PROFILE_DEBUG = '2'

            try {
                Initialize-EnvFiles -RepoRoot $repoRoot
                $env:SUCCESS_INIT_VAR | Should -Be 'loaded'
                $env:SUCCESS_LOCAL_VAR | Should -Be 'local'
            }
            finally {
                Remove-Item Env:\SUCCESS_INIT_VAR, Env:\SUCCESS_LOCAL_VAR -ErrorAction SilentlyContinue
                if ($null -eq $originalDebug) {
                    Remove-Item Env:PS_PROFILE_DEBUG -ErrorAction SilentlyContinue
                }
                else {
                    $env:PS_PROFILE_DEBUG = $originalDebug
                }
            }
        }
    }
}
