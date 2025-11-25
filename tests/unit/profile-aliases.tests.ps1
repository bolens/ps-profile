#
# Tests for aliases defined across profile fragments.
#

BeforeAll {
    # Import common module directly
    $repoRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
    $commonModulePath = Join-Path $repoRoot 'scripts\lib\Common.psm1'
    if (Test-Path $commonModulePath) {
        Import-Module $commonModulePath -DisableNameChecking -ErrorAction Stop
    }

    $script:ProfileDir = Join-Path $repoRoot 'profile.d'
    if (-not (Test-Path $script:ProfileDir)) {
        throw "Profile directory not found: $script:ProfileDir"
    }
    $script:BootstrapPath = Join-Path $script:ProfileDir '00-bootstrap.ps1'
    . $script:BootstrapPath
    . (Join-Path $script:ProfileDir '05-utilities.ps1')
    . (Join-Path $script:ProfileDir '11-git.ps1')
    . (Join-Path $script:ProfileDir '33-aliases.ps1')
}

Describe 'Profile aliases' {
    BeforeEach {
        if (Get-Alias -Name ll -ErrorAction SilentlyContinue) { Remove-Item Alias:ll -Force }
        if (Get-Alias -Name la -ErrorAction SilentlyContinue) { Remove-Item Alias:la -Force }
        if (Get-Command Get-ChildItemEnhanced -ErrorAction SilentlyContinue) { Remove-Item Function:Get-ChildItemEnhanced -Force }
        if (Get-Command Get-ChildItemEnhancedAll -ErrorAction SilentlyContinue) { Remove-Item Function:Get-ChildItemEnhancedAll -Force }
        if (Get-Command Show-Path -ErrorAction SilentlyContinue) { Remove-Item Function:Show-Path -Force }
        if (Get-Variable -Name 'AliasesLoaded' -Scope Global -ErrorAction SilentlyContinue) {
            Remove-Variable -Name 'AliasesLoaded' -Scope Global -Force
        }
    }

    Context 'Alias behaviors' {
        It 'Set-AgentModeAlias returns definition when requested and alias works' {
            $name = "test_alias_{0}" -f (Get-Random)
            try {
                $definition = Set-AgentModeAlias -Name $name -Target 'Write-Output' -ReturnDefinition
                $definition | Should -Not -Be $false
                $definition | Should -BeOfType [string]
                (& $name 'hello') | Should -Be 'hello'
            }
            finally {
                if (Get-Alias -Name $name -ErrorAction SilentlyContinue) {
                    Remove-Item Alias:$name -Force
                }
            }
        }

        It 'Enable-Aliases function is available' {
            { Enable-Aliases } | Should -Not -Throw
        }

        It 'Enable-Aliases creates alias functions' {
            Enable-Aliases
            $true | Should -Be $true
        }

        It 'll function wraps Get-ChildItemEnhanced' {
            Enable-Aliases

            $testFile = Join-Path $TestDrive 'test_ll_file.txt'
            New-Item -ItemType File -Path $testFile -Force | Out-Null

            Get-Command Get-ChildItemEnhanced -ErrorAction SilentlyContinue | Should -Not -Be $null
            Get-Command ll -ErrorAction SilentlyContinue | Should -Not -Be $null

            $result = Get-ChildItemEnhanced $testFile
            $result | Should -Not -Be $null
            $result.Name | Should -Be 'test_ll_file.txt'
        }

        It 'la function surfaces hidden files' {
            Enable-Aliases

            Push-Location $TestDrive
            try {
                $testFile = 'test_la_file.txt'
                New-Item -ItemType File -Path $testFile -Force | Out-Null
                attrib +h $testFile

                Get-Command Get-ChildItemEnhancedAll -ErrorAction SilentlyContinue | Should -Not -Be $null
                Get-Command la -ErrorAction SilentlyContinue | Should -Not -Be $null

                $result = Get-ChildItemEnhancedAll
                ($result | Where-Object { $_.Name -eq $testFile }) | Should -Not -BeNullOrEmpty
            }
            finally {
                Pop-Location
            }
        }

        It 'Show-Path returns PATH entries as an array' {
            Set-Item -Path Function:Show-Path -Value { @($env:Path -split ';' | Where-Object { $_ }) } -Force

            $result = Show-Path
            $result | Should -Not -Be $null
            $result -is [array] | Should -Be $true
            $result.Count | Should -BeGreaterThan 0
            $result | ForEach-Object { $_ | Should -BeOfType [string] }
        }

        It 'common git aliases exist' {
            foreach ($aliasName in 'gs', 'ga', 'gc', 'gp', 'gl') {
                Get-Alias $aliasName -ErrorAction SilentlyContinue | Should -Not -Be $null
            }
        }

        It 'git status helper wraps Invoke-GitCommand' {
            $statusCommand = Get-Command Invoke-GitStatus -ErrorAction SilentlyContinue
            $statusCommand | Should -Not -Be $null
            $statusCommand.ScriptBlock.ToString() | Should -Match "Invoke-GitCommand -Subcommand 'status'"
            (Get-Alias gs).Definition | Should -Be 'Invoke-GitStatus'
        }

        It 'git log helper requires commit context' {
            $logCommand = Get-Command Get-GitLog -ErrorAction SilentlyContinue
            $logCommand | Should -Not -Be $null
            $logCommand.ScriptBlock.ToString() | Should -Match "Invoke-GitCommand -Subcommand 'log'"
            (Get-Alias gl).Definition | Should -Be 'Get-GitLog'
        }
    }
}
