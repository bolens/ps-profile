# ===============================================
# game-dev.tests.ps1
# Integration tests for game-dev.ps1 module
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

Describe 'game-dev.ps1 - Integration Tests' {
    Context 'Module Loading' {
        It 'Loads fragment without errors' {
            { . (Join-Path $script:ProfileDir 'game-dev.ps1') } | Should -Not -Throw
        }
        
        It 'Is idempotent (can be loaded multiple times)' {
            { 
                . (Join-Path $script:ProfileDir 'game-dev.ps1')
                . (Join-Path $script:ProfileDir 'game-dev.ps1')
            } | Should -Not -Throw
        }
    }
    
    Context 'Function Registration' {
        BeforeAll {
            . (Join-Path $script:ProfileDir 'game-dev.ps1')
        }
        
        It 'Registers Launch-Blockbench function' {
            Get-Command -Name 'Launch-Blockbench' -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
        
        It 'Registers Launch-Tiled function' {
            Get-Command -Name 'Launch-Tiled' -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
        
        It 'Registers Launch-Godot function' {
            Get-Command -Name 'Launch-Godot' -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
        
        It 'Registers Build-GodotProject function' {
            Get-Command -Name 'Build-GodotProject' -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
        
        It 'Registers Launch-Unity function' {
            Get-Command -Name 'Launch-Unity' -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
    }
    
    Context 'Graceful Degradation' {
        BeforeEach {
            if ($global:CollectedMissingToolWarnings) {
                $global:CollectedMissingToolWarnings.Clear()
            }
            if ($global:MissingToolWarnings) {
                $global:MissingToolWarnings.Clear()
            }
            if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
                Clear-TestCachedCommandCache | Out-Null
            }
        }

        BeforeAll {
            . (Join-Path $script:ProfileDir 'game-dev.ps1')
        }

        It 'Launch-Blockbench handles missing tool gracefully' {
            Set-TestCommandAvailabilityState -CommandName 'blockbench' -Available $false

            $output = & { Launch-Blockbench -ErrorAction SilentlyContinue } 2>&1 3>&1 | Out-String
            Assert-TestMissingToolWarning -Output $output -Pattern 'blockbench not found'
            Assert-TestOutputContainsInstallCommand -Output $output -ToolName 'blockbench'
        }

        It 'Launch-Tiled handles missing tool gracefully' {
            Set-TestCommandAvailabilityState -CommandName 'tiled' -Available $false

            $output = & { Launch-Tiled -ErrorAction SilentlyContinue } 2>&1 3>&1 | Out-String
            Assert-TestMissingToolWarning -Output $output -Pattern 'tiled not found'
            Assert-TestOutputContainsInstallCommand -Output $output -ToolName 'tiled'
        }

        It 'Launch-Godot handles missing tool gracefully' {
            Set-TestCommandAvailabilityState -CommandName 'godot' -Available $false

            $output = & { Launch-Godot -ErrorAction SilentlyContinue } 2>&1 3>&1 | Out-String
            Assert-TestMissingToolWarning -Output $output -Pattern 'godot not found'
            Assert-TestOutputContainsInstallCommand -Output $output -ToolName 'godot'
        }

        It 'Build-GodotProject handles missing tool gracefully' {
            Set-TestCommandAvailabilityState -CommandName 'godot' -Available $false

            $output = & {
                Build-GodotProject -ProjectPath 'C:\Projects\MyGame' -ExportPreset 'Windows Desktop' -ErrorAction SilentlyContinue
            } 2>&1 3>&1 | Out-String
            Assert-TestMissingToolWarning -Output $output -Pattern 'godot not found'
            Assert-TestOutputContainsInstallCommand -Output $output -ToolName 'godot'
        }

        It 'Launch-Unity handles missing tools gracefully' {
            Set-TestCommandAvailabilityState -CommandName 'unity-hub' -Available $false
            Set-TestCommandAvailabilityState -CommandName 'unity' -Available $false

            $output = & { Launch-Unity -ErrorAction SilentlyContinue } 2>&1 3>&1 | Out-String
            Assert-TestMissingToolWarning -Output $output -Pattern 'unity-hub not found'
            Assert-TestOutputContainsInstallCommand -Output $output -ToolName 'unity-hub'
        }
    }
}

