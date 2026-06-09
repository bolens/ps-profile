# ===============================================
# profile-files-listing-extended.tests.ps1
# Execution tests for files-modules/navigation/files-listing.ps1 behavior
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

    Set-TestCommandAvailabilityState -CommandName 'eza' -Available $false
    Set-TestCommandAvailabilityState -CommandName 'bat' -Available $false
    if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
        Clear-TestCachedCommandCache | Out-Null
    }
}

Describe 'profile.d/files-modules/navigation/files-listing.ps1 extended scenarios' {
    BeforeEach {
        . (Join-Path $script:ProfileDir 'files-modules/navigation/files-listing.ps1')
    }

    It 'Registers Ensure-FileListing and detailed listing helpers' {
        Get-Command Ensure-FileListing -ErrorAction Stop | Should -Not -BeNullOrEmpty

        Ensure-FileListing

        Get-Command Get-ChildItemDetailed -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Get-ChildItemAll -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Get-DirectoryTree -ErrorAction Stop | Should -Not -BeNullOrEmpty
    }

    It 'Registers ll alias targeting Get-ChildItemDetailed when available' {
        Ensure-FileListing

        $alias = Get-Alias ll -ErrorAction SilentlyContinue
        if ($alias) {
            $alias.ResolvedCommandName | Should -Be 'Get-ChildItemDetailed'
        }
    }

    It 'Get-ChildItemDetailed lists directory contents without error' {
        Ensure-FileListing

        { Get-ChildItemDetailed -Path $script:ProfileDir | Out-Null } | Should -Not -Throw
    }
}
