# ===============================================
# mobile-dev.tests.ps1
# Integration tests for mobile-dev.ps1 module
# ===============================================

. (Join-Path $PSScriptRoot '..\..\TestSupport.ps1')

BeforeAll {
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
        BeforeAll {
            . (Join-Path $script:ProfileDir 'mobile-dev.ps1')
        }
        
        It 'Connect-AndroidDevice handles missing adb gracefully' {
            if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
                Clear-TestCachedCommandCache | Out-Null
            }
            
            Mock-CommandAvailabilityPester -CommandName 'adb' -Available $false
            
            { Connect-AndroidDevice -ErrorAction SilentlyContinue } | Should -Not -Throw
        }
        
        It 'Mirror-AndroidScreen handles missing scrcpy gracefully' {
            if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
                Clear-TestCachedCommandCache | Out-Null
            }
            
            Mock-CommandAvailabilityPester -CommandName 'scrcpy' -Available $false
            
            { Mirror-AndroidScreen -ErrorAction SilentlyContinue } | Should -Not -Throw
        }
        
        It 'Install-Apk handles missing adb gracefully' {
            if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
                Clear-TestCachedCommandCache | Out-Null
            }
            
            Mock-CommandAvailabilityPester -CommandName 'adb' -Available $false
            
            $result = Install-Apk -ApkPath 'test.apk' -ErrorAction SilentlyContinue
            $result | Should -Be $false
        }
        
        It 'Connect-IOSDevice handles missing libimobiledevice gracefully' {
            if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
                Clear-TestCachedCommandCache | Out-Null
            }
            
            Mock-CommandAvailabilityPester -CommandName 'idevice_id' -Available $false
            
            { Connect-IOSDevice -ErrorAction SilentlyContinue } | Should -Not -Throw
        }
        
        It 'Flash-Android handles missing pixelflasher gracefully' {
            if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
                Clear-TestCachedCommandCache | Out-Null
            }
            
            Mock-CommandAvailabilityPester -CommandName 'pixelflasher' -Available $false
            
            { Flash-Android -ErrorAction SilentlyContinue } | Should -Not -Throw
        }
        
        It 'Start-AndroidStudio handles missing tools gracefully' {
            if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
                Clear-TestCachedCommandCache | Out-Null
            }
            
            Mock-CommandAvailabilityPester -CommandName 'android-studio-canary' -Available $false
            Mock-CommandAvailabilityPester -CommandName 'android-studio' -Available $false
            
            { Start-AndroidStudio -ErrorAction SilentlyContinue } | Should -Not -Throw
        }
    }
}

