# ===============================================
# profile-dart-fragment-extended.tests.ps1
# Execution tests for dart.ps1 fragment behavior
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

Describe 'profile.d/dart.ps1 extended scenarios' {
    It 'Registers Dart helpers when dart is available' {
        Set-TestCommandAvailabilityState -CommandName 'dart' -Available $true
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }

        . (Join-Path $script:ProfileDir 'dart.ps1')

        Get-Command Test-DartOutdated -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Add-DartPackage -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command dart-outdated -ErrorAction Stop | Should -Not -BeNullOrEmpty
    }

    It 'Skips Dart helper registration when dart and flutter are unavailable' {
        Set-TestCommandAvailabilityState -CommandName 'dart' -Available $false
        Set-TestCommandAvailabilityState -CommandName 'flutter' -Available $false
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }

        . (Join-Path $script:ProfileDir 'dart.ps1')

        Get-Command Test-DartOutdated -ErrorAction SilentlyContinue | Should -BeNullOrEmpty
        Get-Command Test-FlutterOutdated -ErrorAction SilentlyContinue | Should -BeNullOrEmpty
    }

    It 'Emits missing-tool warning when dart is unavailable at load time' {
        Set-TestCommandAvailabilityState -CommandName 'dart' -Available $false
        Set-TestCommandAvailabilityState -CommandName 'flutter' -Available $false
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }
        if ($global:MissingToolWarnings) {
            $null = $global:MissingToolWarnings.TryRemove('dart', [ref]$null)
            $null = $global:MissingToolWarnings.TryRemove('flutter', [ref]$null)
        }

        $output = & { . (Join-Path $script:ProfileDir 'dart.ps1') } 2>&1 3>&1 | Out-String
        Assert-TestMissingToolWarning -Output $output -Pattern 'dart not found'
    }
}
