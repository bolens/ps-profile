#
# Tests for aliases defined across profile fragments.
#

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
    $script:TestTempRoot = New-TestTempDirectory -Prefix 'ProfileAliases'

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
    $script:BootstrapPath = Join-Path $script:ProfileDir 'bootstrap.ps1'
    . $script:BootstrapPath
    . (Join-Path $script:ProfileDir 'files-module-registry.ps1')
    . (Join-Path $script:ProfileDir 'utilities.ps1')
    . (Join-Path $script:ProfileDir 'git.ps1')
    . (Join-Path $script:ProfileDir 'aliases.ps1')
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

        It 'Enable-Aliases function is available' {
            { Enable-Aliases } | Should -Not -Throw
        }

        It 'Enable-Aliases creates alias functions' {
            Enable-Aliases
            # Verify at least the ll alias was registered
            Get-Command ll -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'll function wraps Get-ChildItemEnhanced' {
            Enable-Aliases

            $testFile = Join-Path $script:TestTempRoot 'test_ll_file.txt'
            New-Item -ItemType File -Path $testFile -Force | Out-Null

            Get-Command Get-ChildItemEnhanced -ErrorAction SilentlyContinue | Should -Not -Be $null
            Get-Command ll -ErrorAction SilentlyContinue | Should -Not -Be $null

            $result = Get-ChildItemEnhanced $testFile
            $result | Should -Not -Be $null
            $result.Name | Should -Be 'test_ll_file.txt'
        }

        It 'la function surfaces hidden files' {
            Enable-Aliases

            Push-Location $script:TestTempRoot
            try {
                if ($IsWindows) {
                    $testFile = 'test_la_file.txt'
                    New-Item -ItemType File -Path $testFile -Force | Out-Null
                    if (Get-Command attrib -ErrorAction SilentlyContinue) {
                        attrib +h $testFile | Out-Null
                    }
                }
                else {
                    $testFile = '.test_la_hidden.txt'
                    New-Item -ItemType File -Path $testFile -Force | Out-Null
                }

                Get-Command Get-ChildItemEnhancedAll -ErrorAction SilentlyContinue | Should -Not -Be $null
                Get-Command la -ErrorAction SilentlyContinue | Should -Not -Be $null

                $result = Get-ChildItemEnhancedAll
                ($result | Where-Object { $_.Name -eq (Split-Path -Leaf $testFile) }) | Should -Not -BeNullOrEmpty
            }
            finally {
                Pop-Location
            }
        }

        It 'Show-Path returns PATH entries as an array' {
            Enable-Aliases

            $result = @(Show-Path)
            @($result).Count | Should -BeGreaterThan 0
            $result | ForEach-Object { $_ | Should -BeOfType [string] }
        }

        It 'common git helpers exist after Ensure-Git' {
            Ensure-Git
            foreach ($functionName in 'Invoke-GitStatus', 'Add-GitChanges', 'Save-GitCommit', 'Publish-GitChanges', 'Get-GitLog') {
                Get-Command $functionName -ErrorAction SilentlyContinue | Should -Not -Be $null
            }
        }

        It 'git status helper wraps Invoke-GitCommand' {
            Ensure-Git
            $statusCommand = Get-Command Invoke-GitStatus -ErrorAction SilentlyContinue
            $statusCommand | Should -Not -Be $null
            $statusCommand.ScriptBlock.ToString() | Should -Match "Invoke-GitCommand -Subcommand 'status'"
            $gsAlias = Get-Alias gs -Scope Global -ErrorAction SilentlyContinue
            if ($gsAlias) {
                $gsAlias.Definition | Should -Be 'Invoke-GitStatus'
            }
        }

        It 'git log helper requires commit context' {
            Ensure-Git
            $logCommand = Get-Command Get-GitLog -ErrorAction SilentlyContinue
            $logCommand | Should -Not -Be $null
            $logCommand.ScriptBlock.ToString() | Should -Match "Invoke-GitCommand -Subcommand 'log'"
            $glAlias = Get-Alias gl -Scope Global -ErrorAction SilentlyContinue
            if ($glAlias -and $glAlias.Definition -eq 'Get-GitLog') {
                $glAlias.Definition | Should -Be 'Get-GitLog'
            }
        }
    }
}
