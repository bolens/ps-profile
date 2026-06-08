# ===============================================
# profile-pixi-fragment-extended.tests.ps1
# Execution tests for pixi.ps1 fragment behavior
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
    . (Join-Path $script:ProfileDir 'bootstrap.ps1')
}

Describe 'profile.d/pixi.ps1 extended scenarios' {
    It 'Registers pixi helpers when pixi is available' {
        Set-TestCommandAvailabilityState -CommandName 'pixi' -Available $true
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }

        . (Join-Path $script:ProfileDir 'pixi.ps1')

        Get-Command Add-PixiPackage -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Invoke-PixiRun -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command pixi-add -ErrorAction Stop | Should -Not -BeNullOrEmpty
    }

    It 'Skips pixi helper registration when pixi is unavailable' {
        Set-TestCommandAvailabilityState -CommandName 'pixi' -Available $false
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }

        . (Join-Path $script:ProfileDir 'pixi.ps1')

        Get-Command Add-PixiPackage -ErrorAction SilentlyContinue | Should -BeNullOrEmpty
    }

    It 'Emits missing-tool warning when pixi is unavailable at load time' {
        Set-TestCommandAvailabilityState -CommandName 'pixi' -Available $false
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }
        if ($global:MissingToolWarnings) {
            $null = $global:MissingToolWarnings.TryRemove('pixi', [ref]$null)
        }

        $output = & { . (Join-Path $script:ProfileDir 'pixi.ps1') } 2>&1 3>&1 | Out-String
        Assert-TestMissingToolWarning -Output $output -Pattern 'pixi not found'
    }
}
