# ===============================================
# profile-bootstrap-loader.tests.ps1
# Unit tests for bootstrap.ps1 orchestrator load behavior
# ===============================================

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
    $script:BootstrapPath = Join-Path $script:ProfileDir 'bootstrap.ps1'
    $script:BootstrapModulesDir = Join-Path $script:ProfileDir 'bootstrap'

    . $script:BootstrapPath
}

function script:Invoke-BootstrapReloadWithCorruptModule {
    param(
        [Parameter(Mandatory)]
        [string]$ModuleName
    )

    $resolvedPath = Join-Path $script:BootstrapModulesDir $ModuleName

    $originalBytes = Backup-TestFileBytes -Path $resolvedPath
    $global:TestBootstrapCapturedErrors = [System.Collections.Generic.List[object]]::new()
    $previousDebug = $env:PS_PROFILE_DEBUG
    $profileError = Get-Command Write-ProfileError -ErrorAction SilentlyContinue
    $profileErrorBody = if ($profileError) { $profileError.ScriptBlock } else { $null }

    function global:Write-ProfileError {
        param(
            $ErrorRecord,
            $Context,
            $Category
        )

        if ($ErrorRecord -is [System.Management.Automation.ErrorRecord]) {
            [void]$global:TestBootstrapCapturedErrors.Add($ErrorRecord)
        }
    }

    Set-Item -Path Function:\global:Write-ProfileError -Value ${function:global:Write-ProfileError} -Force

    if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
        Clear-TestCachedCommandCache | Out-Null
    }

    if (Get-Command Remove-TestCachedCommandCacheEntry -ErrorAction SilentlyContinue) {
        Remove-TestCachedCommandCacheEntry -Name 'Write-ProfileError' | Out-Null
    }

    try {
        Write-TestFileLiteralContent -Path $resolvedPath -Content 'throw "bootstrap loader failure"'

        $env:PS_PROFILE_DEBUG = '1'
        . $script:BootstrapPath

        return $global:TestBootstrapCapturedErrors
    }
    finally {
        Restore-TestFileBytes -Path $resolvedPath -Bytes $originalBytes
        Remove-Item -Path Function:\Write-ProfileError -Force -ErrorAction SilentlyContinue
        Remove-Item -Path Function:\global:Write-ProfileError -Force -ErrorAction SilentlyContinue
        if ($profileErrorBody) {
            Set-Item -Path Function:\global:Write-ProfileError -Value $profileErrorBody -Force
        }

        if ($null -eq $previousDebug) {
            Remove-Item Env:\PS_PROFILE_DEBUG -ErrorAction SilentlyContinue
        }
        else {
            $env:PS_PROFILE_DEBUG = $previousDebug
        }
    }
}

Describe 'bootstrap.ps1 - successful load' {
    It 'Registers core bootstrap helpers after load' {
        Get-Command Set-AgentModeFunction -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Test-CachedCommand -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Import-FragmentModules -ErrorAction Stop | Should -Not -BeNullOrEmpty
        $global:AssumedAvailableCommands | Should -Not -BeNullOrEmpty
    }

    It 'Allows a second bootstrap load without throwing' {
        . $script:BootstrapPath
        Get-Command Set-AgentModeFunction -ErrorAction Stop | Should -Not -BeNullOrEmpty
    }
}

Describe 'bootstrap.ps1 - module failure handling' {
    It 'Falls back to Write-Warning for early bootstrap modules that fail before error handling is loaded' -TestCases @(
        @{ ModuleName = 'GlobalState.ps1' }
        @{ ModuleName = 'ErrorHandlingStandard.ps1' }
        @{ ModuleName = 'CommandCache.ps1' }
    ) {
        param($ModuleName)

        $modulePath = Join-Path $script:BootstrapModulesDir $ModuleName
        $originalBytes = Backup-TestFileBytes -Path $modulePath
        $previousDebug = $env:PS_PROFILE_DEBUG

        try {
            Write-TestFileLiteralContent -Path $modulePath -Content 'throw "bootstrap loader failure"'
            $env:PS_PROFILE_DEBUG = '1'

            $output = $(
                . $script:BootstrapPath 3>&1 2>&1
            ) | Out-String

            $output | Should -Match "Failed to load bootstrap module $ModuleName"
            $output | Should -Match 'bootstrap loader failure'
        }
        finally {
            Restore-TestFileBytes -Path $modulePath -Bytes $originalBytes
            if ($null -eq $previousDebug) {
                Remove-Item Env:\PS_PROFILE_DEBUG -ErrorAction SilentlyContinue
            }
            else {
                $env:PS_PROFILE_DEBUG = $previousDebug
            }
        }
    }

    It 'Reports bootstrap module load failures through Write-ProfileError when PS_PROFILE_DEBUG is set' -TestCases @(
        @{ ModuleName = 'GlobalState.ps1' }
        @{ ModuleName = 'ErrorHandlingStandard.ps1' }
        @{ ModuleName = 'CommandCache.ps1' }
        @{ ModuleName = 'FunctionRegistration.ps1' }
        @{ ModuleName = 'ModulePathCache.ps1' }
        @{ ModuleName = 'ModuleLoading.ps1' }
        @{ ModuleName = 'UserHome.ps1' }
        @{ ModuleName = 'PlatformPaths.ps1' }
        @{ ModuleName = 'MissingToolWarnings.ps1' }
        @{ ModuleName = 'ToolInstallRegistry.ps1' }
        @{ ModuleName = 'InstallHintResolver.ps1' }
        @{ ModuleName = 'EmbeddedInstallHints.ps1' }
        @{ ModuleName = 'BatchLoadingSummary.ps1' }
        @{ ModuleName = 'SafeTestPath.ps1' }
        @{ ModuleName = 'FragmentWarnings.ps1' }
        @{ ModuleName = 'CloudProviderBase.ps1' }
        @{ ModuleName = 'PromptBase.ps1' }
        @{ ModuleName = 'PackageManagerBase.ps1' }
        @{ ModuleName = 'AssumedCommands.ps1' }
    ) {
        param($ModuleName)

        $capturedProfileErrors = @(Invoke-BootstrapReloadWithCorruptModule -ModuleName $ModuleName |
                Where-Object { $_ -is [System.Management.Automation.ErrorRecord] })

        $capturedProfileErrors.Count | Should -BeGreaterThan 0
        ($capturedProfileErrors | ForEach-Object { $_.ToString() }) -join "`n" | Should -Match 'bootstrap loader failure'
        Get-Command Set-AgentModeFunction -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
    }

    It 'Falls back to Write-Warning when Write-ProfileError is unavailable during module load failures' -TestCases @(
        @{ ModuleName = 'CloudProviderBase.ps1' }
        @{ ModuleName = 'PromptBase.ps1' }
        @{ ModuleName = 'PackageManagerBase.ps1' }
        @{ ModuleName = 'AssumedCommands.ps1' }
        @{ ModuleName = 'BatchLoadingSummary.ps1' }
        @{ ModuleName = 'EmbeddedInstallHints.ps1' }
        @{ ModuleName = 'FragmentWarnings.ps1' }
        @{ ModuleName = 'FunctionRegistration.ps1' }
        @{ ModuleName = 'InstallHintResolver.ps1' }
        @{ ModuleName = 'MissingToolWarnings.ps1' }
        @{ ModuleName = 'ModuleLoading.ps1' }
        @{ ModuleName = 'ModulePathCache.ps1' }
        @{ ModuleName = 'PlatformPaths.ps1' }
        @{ ModuleName = 'SafeTestPath.ps1' }
        @{ ModuleName = 'ToolInstallRegistry.ps1' }
        @{ ModuleName = 'UserHome.ps1' }
    ) {
        param($ModuleName)

        $modulePath = Join-Path $script:BootstrapModulesDir $ModuleName
        $originalBytes = Backup-TestFileBytes -Path $modulePath
        $previousDebug = $env:PS_PROFILE_DEBUG
        $profileError = Get-Command Write-ProfileError -ErrorAction SilentlyContinue
        $profileErrorBody = if ($profileError) { $profileError.ScriptBlock } else { $null }

        Remove-Item -Path Function:\Write-ProfileError -Force -ErrorAction SilentlyContinue
        Remove-Item -Path Function:\global:Write-ProfileError -Force -ErrorAction SilentlyContinue

        if (Get-Command Remove-TestCachedCommandCacheEntry -ErrorAction SilentlyContinue) {
            Remove-TestCachedCommandCacheEntry -Name 'Write-ProfileError' | Out-Null
        }

        try {
            Write-TestFileLiteralContent -Path $modulePath -Content 'throw "bootstrap loader failure"'
            $env:PS_PROFILE_DEBUG = '1'

            $output = $(
                . $script:BootstrapPath 3>&1 2>&1
            ) | Out-String

            $output | Should -Match "Failed to load bootstrap module $ModuleName"
            $output | Should -Match 'bootstrap loader failure'
        }
        finally {
            Restore-TestFileBytes -Path $modulePath -Bytes $originalBytes
            Remove-Item -Path Function:\Write-ProfileError -Force -ErrorAction SilentlyContinue
            Remove-Item -Path Function:\global:Write-ProfileError -Force -ErrorAction SilentlyContinue
            if ($profileErrorBody) {
                Set-Item -Path Function:\global:Write-ProfileError -Value $profileErrorBody -Force
            }
            if ($null -eq $previousDebug) {
                Remove-Item Env:\PS_PROFILE_DEBUG -ErrorAction SilentlyContinue
            }
            else {
                $env:PS_PROFILE_DEBUG = $previousDebug
            }
        }
    }
}
