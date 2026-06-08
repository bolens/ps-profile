# ===============================================
# mobile-dev.tests.ps1
# Integration tests for mobile-dev.ps1 module
# ===============================================

BeforeAll {
    . (Join-Path $PSScriptRoot '..\..\TestSupport.ps1')
    $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
    . (Join-Path $script:ProfileDir 'bootstrap.ps1')
}

Describe 'mobile-dev.ps1 - Integration Tests' {
    Context 'Module Loading' {
        It 'Loads fragment without errors' {
            { . (Join-Path $script:ProfileDir 'mobile-dev.ps1') } | Should -Not -Throw
        }
        
        It 'Is idempotent (can be loaded multiple times)' {
            { 
                . (Join-Path $script:ProfileDir 'mobile-dev.ps1')
                . (Join-Path $script:ProfileDir 'mobile-dev.ps1')
            } | Should -Not -Throw
        }
    }
    
    Context 'Function Registration' {
        BeforeAll {
            . (Join-Path $script:ProfileDir 'mobile-dev.ps1')
        }
        
        It 'Registers Connect-AndroidDevice function' {
            Get-Command -Name 'Connect-AndroidDevice' -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
        
        It 'Registers Mirror-AndroidScreen function' {
            Get-Command -Name 'Mirror-AndroidScreen' -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
        
        It 'Registers Install-Apk function' {
            Get-Command -Name 'Install-Apk' -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
        
        It 'Registers Connect-IOSDevice function' {
            Get-Command -Name 'Connect-IOSDevice' -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
        
        It 'Registers Flash-Android function' {
            Get-Command -Name 'Flash-Android' -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
        
        It 'Registers Start-AndroidStudio function' {
            Get-Command -Name 'Start-AndroidStudio' -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
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
            . (Join-Path $script:ProfileDir 'mobile-dev.ps1')
        }

        It 'Connect-AndroidDevice handles missing adb gracefully' {
            Set-TestCommandAvailabilityState -CommandName 'adb' -Available $false

            $output = & { Connect-AndroidDevice -ErrorAction SilentlyContinue } 2>&1 3>&1 | Out-String
            Assert-TestMissingToolWarning -Output $output -Pattern 'adb not found'
            Assert-TestOutputContainsInstallCommand -Output $output -ToolName 'adb'
        }

        It 'Mirror-AndroidScreen handles missing scrcpy gracefully' {
            Set-TestCommandAvailabilityState -CommandName 'scrcpy' -Available $false

            $output = & { Mirror-AndroidScreen -ErrorAction SilentlyContinue } 2>&1 3>&1 | Out-String
            Assert-TestMissingToolWarning -Output $output -Pattern 'scrcpy not found'
            Assert-TestOutputContainsInstallCommand -Output $output -ToolName 'scrcpy'
        }

        It 'Install-Apk handles missing adb gracefully' {
            Set-TestCommandAvailabilityState -CommandName 'adb' -Available $false

            $output = & { Install-Apk -ApkPath 'test.apk' -ErrorAction SilentlyContinue } 2>&1 3>&1 | Out-String
            Assert-TestMissingToolWarning -Output $output -Pattern 'adb not found'
            Assert-TestOutputContainsInstallCommand -Output $output -ToolName 'adb'
        }

        It 'Connect-IOSDevice handles missing libimobiledevice gracefully' {
            Set-TestCommandAvailabilityState -CommandName 'idevice_id' -Available $false

            $output = & { Connect-IOSDevice -ErrorAction SilentlyContinue } 2>&1 3>&1 | Out-String
            Assert-TestMissingToolWarning -Output $output -Pattern 'libimobiledevice not found'
            Assert-TestOutputContainsInstallCommand -Output $output -ToolName 'libimobiledevice'
        }

        It 'Flash-Android handles missing pixelflasher gracefully' {
            Set-TestCommandAvailabilityState -CommandName 'pixelflasher' -Available $false

            $output = & { Flash-Android -ErrorAction SilentlyContinue } 2>&1 3>&1 | Out-String
            Assert-TestMissingToolWarning -Output $output -Pattern 'pixelflasher not found'
            Assert-TestOutputContainsInstallCommand -Output $output -ToolName 'pixelflasher'
        }

        It 'Start-AndroidStudio handles missing tools gracefully' {
            Set-TestCommandAvailabilityState -CommandName 'android-studio-canary' -Available $false
            Set-TestCommandAvailabilityState -CommandName 'android-studio' -Available $false

            $output = & { Start-AndroidStudio -ErrorAction SilentlyContinue } 2>&1 3>&1 | Out-String
            Assert-TestMissingToolWarning -Output $output -Pattern 'android-studio-canary not found'
            Assert-TestOutputContainsInstallCommand -Output $output -ToolName 'android-studio-canary'
        }
    }
}

