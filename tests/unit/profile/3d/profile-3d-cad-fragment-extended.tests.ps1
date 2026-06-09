# ===============================================
# profile-3d-cad-fragment-extended.tests.ps1
# Execution tests for 3d-cad.ps1 fragment behavior
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
    $fragmentIdempotencyPath = Get-TestPath -RelativePath 'scripts/lib/fragment/FragmentIdempotency.psm1' -StartPath $PSScriptRoot -EnsureExists
    Import-Module $fragmentIdempotencyPath -DisableNameChecking -ErrorAction Stop -Force
    . (Join-Path $script:ProfileDir 'bootstrap.ps1')
}

function script:Reset-3dCadFragmentState {
    Clear-FragmentLoaded -FragmentName '3d-cad' -ErrorAction SilentlyContinue
}

Describe 'profile.d/3d-cad.ps1 extended scenarios' {
    BeforeEach {
        Reset-3dCadFragmentState
    }

    It 'Registers Blender launch helpers and marks the fragment loaded' {
        . (Join-Path $script:ProfileDir '3d-cad.ps1')

        Get-Command Launch-Blender -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Launch-FreeCAD -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Test-FragmentLoaded -FragmentName '3d-cad' | Should -Be $true
    }

    It 'Launch-Blender warns when blender is unavailable' {
        . (Join-Path $script:ProfileDir '3d-cad.ps1')

        Set-TestCommandAvailabilityState -CommandName 'blender' -Available $false
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }
        if ($global:MissingToolWarnings) {
            $null = $global:MissingToolWarnings.TryRemove('blender', [ref]$null)
        }

        $output = & { Launch-Blender } 2>&1 3>&1 | Out-String
        Assert-TestMissingToolWarning -Output $output -Pattern 'blender not found'
    }

    It 'Skips re-initialization when 3d-cad is already loaded' {
        . (Join-Path $script:ProfileDir '3d-cad.ps1')
        $firstBlender = Get-Command Launch-Blender -ErrorAction Stop

        . (Join-Path $script:ProfileDir '3d-cad.ps1')

        (Get-Command Launch-Blender -ErrorAction Stop).ScriptBlock.ToString() |
            Should -Be $firstBlender.ScriptBlock.ToString()
    }
}
