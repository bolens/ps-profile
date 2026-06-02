# ===============================================
# game-emulators.tests.ps1
# Integration tests for game-emulators.ps1 module
# ===============================================

. (Join-Path $PSScriptRoot '..\..\TestSupport.ps1')

BeforeAll {
    $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
    . (Join-Path $script:ProfileDir 'bootstrap.ps1')
}

Describe 'game-emulators.ps1 - Integration Tests' {
    Context 'Module Loading' {
        It 'Loads fragment without errors' {
            { . (Join-Path $script:ProfileDir 'game-emulators.ps1') } | Should -Not -Throw
        }
        
        It 'Is idempotent (can be loaded multiple times)' {
            { 
                . (Join-Path $script:ProfileDir 'game-emulators.ps1')
                . (Join-Path $script:ProfileDir 'game-emulators.ps1')
            } | Should -Not -Throw
        }
    }
    
    Context 'Function Registration' {
        BeforeAll {
            . (Join-Path $script:ProfileDir 'game-emulators.ps1')
        }
        
        It 'Registers Start-Dolphin function' {
            Get-Command -Name 'Start-Dolphin' -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
        
        It 'Registers Start-Ryujinx function' {
            Get-Command -Name 'Start-Ryujinx' -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
        
        It 'Registers Start-RetroArch function' {
            Get-Command -Name 'Start-RetroArch' -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
        
        It 'Registers Get-EmulatorList function' {
            Get-Command -Name 'Get-EmulatorList' -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
        
        It 'Registers Launch-Game function' {
            Get-Command -Name 'Launch-Game' -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
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
            . (Join-Path $script:ProfileDir 'game-emulators.ps1')
        }

        It 'Start-Dolphin handles missing tool gracefully' {
            foreach ($cmd in @('dolphin-dev', 'dolphin-nightly', 'dolphin')) {
                Mock-CommandAvailabilityPester -CommandName $cmd -Available $false
            }

            $output = & { Start-Dolphin -ErrorAction SilentlyContinue } 2>&1 3>&1 | Out-String
            Assert-TestMissingToolWarning -Output $output -Pattern 'dolphin-dev not found'
            Assert-TestOutputContainsInstallCommand -Output $output -ToolName 'dolphin-dev'
        }

        It 'Start-Ryujinx handles missing tool gracefully' {
            Mock-CommandAvailabilityPester -CommandName 'ryujinx-canary' -Available $false
            Mock-CommandAvailabilityPester -CommandName 'ryujinx' -Available $false

            $output = & { Start-Ryujinx -ErrorAction SilentlyContinue } 2>&1 3>&1 | Out-String
            Assert-TestMissingToolWarning -Output $output -Pattern 'ryujinx-canary not found'
            Assert-TestOutputContainsInstallCommand -Output $output -ToolName 'ryujinx-canary'
        }

        It 'Start-RetroArch handles missing tool gracefully' {
            Mock-CommandAvailabilityPester -CommandName 'retroarch-nightly' -Available $false
            Mock-CommandAvailabilityPester -CommandName 'retroarch' -Available $false

            $output = & { Start-RetroArch -ErrorAction SilentlyContinue } 2>&1 3>&1 | Out-String
            Assert-TestMissingToolWarning -Output $output -Pattern 'retroarch-nightly not found'
            Assert-TestOutputContainsInstallCommand -Output $output -ToolName 'retroarch-nightly'
        }

        It 'Get-EmulatorList returns empty list when no emulators available' {
            Mock Test-CachedCommand -MockWith { return $false }

            $result = Get-EmulatorList

            @($result) | Should -BeNullOrEmpty
        }

        It 'Launch-Game handles missing ROM file gracefully' {
            Mock Test-Path -ParameterFilter { $LiteralPath -eq 'nonexistent.iso' } -MockWith { return $false }

            { Launch-Game -RomPath 'nonexistent.iso' -ErrorAction SilentlyContinue } | Should -Not -Throw
        }
    }
    
    Context 'Function Behavior' {
        BeforeAll {
            . (Join-Path $script:ProfileDir 'game-emulators.ps1')
        }
        
        It 'Get-EmulatorList returns array of emulator objects' {
            $result = Get-EmulatorList
            
            $result | Should -Not -BeNullOrEmpty

            $first = @($result)[0]
            $first.PSObject.Properties.Name | Should -Contain 'Name'
            $first.PSObject.Properties.Name | Should -Contain 'Category'
            $first.PSObject.Properties.Name | Should -Contain 'Command'
            $first.PSObject.Properties.Name | Should -Contain 'Available'
        }
    }
}

