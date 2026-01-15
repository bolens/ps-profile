# ===============================================
# game-dev.tests.ps1
# Integration tests for game-dev.ps1 module
# ===============================================

. (Join-Path $PSScriptRoot '..\..\TestSupport.ps1')

BeforeAll {
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
        BeforeAll {
            . (Join-Path $script:ProfileDir 'game-dev.ps1')
        }
        
        It 'Launch-Blockbench handles missing tool gracefully' {
            if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
                Clear-TestCachedCommandCache | Out-Null
            }
            
            Mock-CommandAvailabilityPester -CommandName 'blockbench' -Available $false
            
            { Launch-Blockbench -ErrorAction SilentlyContinue } | Should -Not -Throw
        }
        
        It 'Launch-Tiled handles missing tool gracefully' {
            if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
                Clear-TestCachedCommandCache | Out-Null
            }
            
            Mock-CommandAvailabilityPester -CommandName 'tiled' -Available $false
            
            { Launch-Tiled -ErrorAction SilentlyContinue } | Should -Not -Throw
        }
        
        It 'Launch-Godot handles missing tool gracefully' {
            if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
                Clear-TestCachedCommandCache | Out-Null
            }
            
            Mock-CommandAvailabilityPester -CommandName 'godot' -Available $false
            
            { Launch-Godot -ErrorAction SilentlyContinue } | Should -Not -Throw
        }
        
        It 'Build-GodotProject handles missing tool gracefully' {
            if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
                Clear-TestCachedCommandCache | Out-Null
            }
            
            Mock-CommandAvailabilityPester -CommandName 'godot' -Available $false
            
            $result = Build-GodotProject -ProjectPath 'C:\Projects\MyGame' -ExportPreset 'Windows Desktop' -ErrorAction SilentlyContinue
            $result | Should -BeNullOrEmpty
        }
        
        It 'Launch-Unity handles missing tools gracefully' {
            if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
                Clear-TestCachedCommandCache | Out-Null
            }
            
            Mock-CommandAvailabilityPester -CommandName 'unity-hub' -Available $false
            Mock-CommandAvailabilityPester -CommandName 'unity' -Available $false
            
            { Launch-Unity -ErrorAction SilentlyContinue } | Should -Not -Throw
        }
    }
}

