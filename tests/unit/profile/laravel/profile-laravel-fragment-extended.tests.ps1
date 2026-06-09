# ===============================================
# profile-laravel-fragment-extended.tests.ps1
# Execution tests for laravel.ps1 fragment behavior
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
    . (Join-Path $script:ProfileDir 'laravel.ps1')
}

Describe 'profile.d/laravel.ps1 extended scenarios' {
    It 'Registers Laravel helpers and aliases' {
        Get-Command Invoke-LaravelArtisan -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command New-LaravelApp -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command artisan -ErrorAction Stop | Should -Not -BeNullOrEmpty
    }

    It 'New-LaravelApp warns when composer is unavailable' {
        Set-TestCommandAvailabilityState -CommandName 'composer' -Available $false
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }
        if ($global:MissingToolWarnings) {
            $null = $global:MissingToolWarnings.TryRemove('composer', [ref]$null)
        }

        $output = New-LaravelApp 'test-app' 2>&1 3>&1 | Out-String
        Assert-TestMissingToolWarning -Output $output -Pattern 'composer not found'
    }

    It 'Preserves existing laravel helper bodies on repeated fragment loads' {
        $firstArtisan = Get-Command Invoke-LaravelArtisan -ErrorAction Stop

        . (Join-Path $script:ProfileDir 'laravel.ps1')

        (Get-Command Invoke-LaravelArtisan -ErrorAction Stop).ScriptBlock.ToString() |
            Should -Be $firstArtisan.ScriptBlock.ToString()
    }
}
