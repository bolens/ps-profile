<#
tests/unit/profile-files-listing-extended.tests.ps1
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
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/files-modules/navigation/files-listing.ps1'
}
Describe 'profile.d/files-modules/navigation/files-listing.ps1 extended scenarios' {
    It 'Documents directory listing utilities with eza support' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'File listing utility functions'
        $c | Should -Match 'Directory listing with eza support'
    }
    It 'Defines Ensure-FileListing lazy initializer preferring eza' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Ensure-FileListing'
        $c | Should -Match 'Get-ChildItemDetailed'
        $c | Should -Match 'Test-CachedCommand eza'
        $c | Should -Match 'Get-DirectoryTree'
    }
    It 'Registers ll, la, lx, tree, and bat-cat listing aliases' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match "Set-Alias -Name ll"
        $c | Should -Match "Set-Alias -Name la"
        $c | Should -Match "Set-Alias -Name tree"
        $c | Should -Match 'Show-FileContent'
    }
}
