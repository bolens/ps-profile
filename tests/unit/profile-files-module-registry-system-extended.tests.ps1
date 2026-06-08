<#
tests/unit/profile-files-module-registry-system-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/files-module-registry.ps1'
}
Describe 'profile.d/files-module-registry.ps1 Ensure-System registry extended scenarios' {
    It 'Maps Ensure-System to system subdirectory modules' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match '''Ensure-System'''
        $c | Should -Match 'Dir = ''system'''
    }
    It 'Includes file and system info modules' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'FileOperations.ps1'
        $c | Should -Match 'SystemInfo.ps1'
        $c | Should -Match 'NetworkOperations.ps1'
    }
    It 'Includes archive editor and text search modules' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'ArchiveOperations.ps1'
        $c | Should -Match 'EditorAliases.ps1'
        $c | Should -Match 'TextSearch.ps1'
    }
}

