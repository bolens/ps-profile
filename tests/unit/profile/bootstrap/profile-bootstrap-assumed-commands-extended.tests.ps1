# ===============================================
# profile-bootstrap-assumed-commands-extended.tests.ps1
# Execution tests for bootstrap/AssumedCommands.ps1 behavior
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
    $script:BootstrapDir = Join-Path $script:ProfileDir 'bootstrap'
    . (Join-Path $script:ProfileDir 'bootstrap.ps1')
}

Describe 'profile.d/bootstrap/AssumedCommands.ps1 extended scenarios' {
    It 'Registers assumed command management helpers' {
        Get-Command Add-AssumedCommand -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Remove-AssumedCommand -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Get-AssumedCommands -ErrorAction Stop | Should -Not -BeNullOrEmpty
    }

    It 'Add-AssumedCommand marks commands as assumed available' {
        $commandName = "AssumedCmd_$([Guid]::NewGuid().ToString('N'))"
                Add-AssumedCommand -Name $commandName | Should -Be $true
        [string[]](Get-AssumedCommands) | Should -Contain $commandName
    }
    finally {
        Remove-AssumedCommand -Name $commandName | Out-Null
    }

    It 'Preserves assumed command helper bodies on repeated module loads' {
        $firstAdd = Get-Command Add-AssumedCommand -ErrorAction Stop

        . (Join-Path $script:BootstrapDir 'AssumedCommands.ps1')

        (Get-Command Add-AssumedCommand -ErrorAction Stop).ScriptBlock.ToString() |
            Should -Be $firstAdd.ScriptBlock.ToString()
    }
}
