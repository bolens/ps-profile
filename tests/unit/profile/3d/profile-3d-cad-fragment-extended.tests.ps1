<#
tests/unit/profile-3d-cad-fragment-extended.tests.ps1
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
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/3d-cad.ps1'
}
Describe 'profile.d/3d-cad.ps1 extended scenarios' {
    It 'Declares optional tier for 3D modeling and CAD tooling' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Tier: optional'
        $c | Should -Match 'Blender'
        $c | Should -Match 'FreeCAD'
    }
    It 'Defines Launch-Blender with optional background script mode' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Launch-Blender'
        $c | Should -Match '\[switch\]\$Background'
    }
    It 'Marks 3d-cad fragment loaded after registration' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match "FragmentName '3d-cad'"
        $c | Should -Match "Set-FragmentLoaded -FragmentName '3d-cad'"
    }
}
