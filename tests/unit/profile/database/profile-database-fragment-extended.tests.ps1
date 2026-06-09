# ===============================================
# profile-database-fragment-extended.tests.ps1
# Execution tests for database.ps1 fragment behavior
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
    . (Join-Path $script:ProfileDir 'database.ps1')
}

Describe 'profile.d/database.ps1 extended scenarios' {
    It 'Registers universal database helper functions and aliases' {
        Get-Command Connect-Database -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Query-Database -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command db-connect -ErrorAction Stop | Should -Not -BeNullOrEmpty
    }

    It 'Connect-Database warns when sqlite3 is unavailable' {
        Set-TestCommandAvailabilityState -CommandName 'sqlite3' -Available $false
        Set-TestCommandAvailabilityState -CommandName 'dbeaver' -Available $false
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }
        if ($global:MissingToolWarnings) {
            $null = $global:MissingToolWarnings.TryRemove('sqlite3', [ref]$null)
        }

        $output = Connect-Database -DatabaseType SQLite -Database 'test.db' -UseGui:$false 2>&1 3>&1 | Out-String
        Assert-TestMissingToolWarning -Output $output -Pattern 'sqlite3 not found'
    }

    It 'Preserves existing database helper bodies on repeated fragment loads' {
        $firstConnect = Get-Command Connect-Database -ErrorAction Stop

        . (Join-Path $script:ProfileDir 'database.ps1')

        (Get-Command Connect-Database -ErrorAction Stop).ScriptBlock.ToString() |
            Should -Be $firstConnect.ScriptBlock.ToString()
    }
}
