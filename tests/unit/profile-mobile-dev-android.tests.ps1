# ===============================================
# profile-mobile-dev-android.tests.ps1
# Unit tests for Android functions
# ===============================================

. (Join-Path $PSScriptRoot '..\TestSupport.ps1')

# Import mocking utilities
$mockingDir = Join-Path (Split-Path $PSScriptRoot -Parent) 'TestSupport' 'Mocking'
Import-Module (Join-Path $mockingDir 'PesterMocks.psm1') -DisableNameChecking -ErrorAction SilentlyContinue

BeforeAll {
    $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
    . (Join-Path $script:ProfileDir 'bootstrap.ps1')
    . (Join-Path $script:ProfileDir 'mobile-dev.ps1')
}

Describe 'mobile-dev.ps1 - Android Functions' {
    BeforeEach {
        # Clear command cache
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }
        
        if (Get-Variable -Name 'TestCachedCommandCache' -Scope Global -ErrorAction SilentlyContinue) {
            $null = $global:TestCachedCommandCache.TryRemove('adb', [ref]$null)
            $null = $global:TestCachedCommandCache.TryRemove('scrcpy', [ref]$null)
            $null = $global:TestCachedCommandCache.TryRemove('pixelflasher', [ref]$null)
            $null = $global:TestCachedCommandCache.TryRemove('android-studio-canary', [ref]$null)
            $null = $global:TestCachedCommandCache.TryRemove('android-studio', [ref]$null)
        }
    }
    
    Context 'Connect-AndroidDevice' {
        It 'Returns empty array when adb is not available' {
            Mock-CommandAvailabilityPester -CommandName 'adb' -Available $false
            Mock Get-Command -ParameterFilter { $Name -eq 'adb' } -MockWith { return $null }
            
            $result = Connect-AndroidDevice -ErrorAction SilentlyContinue
            
            $result | Should -BeNullOrEmpty
        }
        
        It 'Lists devices when ListDevices is specified' {
            Setup-AvailableCommandMock -CommandName 'adb'
            Mock -CommandName 'adb' -MockWith {
                $global:LASTEXITCODE = 0
                return @('List of devices attached', 'device123    device', 'device456    device')
            }
            
            $result = Connect-AndroidDevice -ListDevices -ErrorAction SilentlyContinue
            
            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -BeGreaterThan 0
        }
        
        It 'Connects to device via network when DeviceIp is provided' {
            Setup-AvailableCommandMock -CommandName 'adb'
            Mock -CommandName 'adb' -MockWith {
                $global:LASTEXITCODE = 0
                return 'connected to 192.168.1.100:5555'
            }
            
            $result = Connect-AndroidDevice -DeviceIp '192.168.1.100' -ErrorAction SilentlyContinue
            
            Should -Invoke 'adb' -Times 1 -Exactly
            $result | Should -Not -BeNullOrEmpty
        }
    }
    
    Context 'Mirror-AndroidScreen' {
        It 'Returns null when scrcpy is not available' {
            Mock-CommandAvailabilityPester -CommandName 'scrcpy' -Available $false
            
            $result = Mirror-AndroidScreen -ErrorAction SilentlyContinue
            
            $result | Should -BeNullOrEmpty
        }
        
        It 'Calls scrcpy with fullscreen flag' {
            Setup-AvailableCommandMock -CommandName 'scrcpy'
            
            $script:capturedProcess = $null
            Mock Start-Process -MockWith {
                $script:capturedProcess = @{
                    FilePath     = $FilePath
                    ArgumentList = $ArgumentList
                }
            }
            
            Mirror-AndroidScreen -Fullscreen -ErrorAction SilentlyContinue
            
            $script:capturedProcess | Should -Not -BeNullOrEmpty
            $script:capturedProcess.FilePath | Should -Be 'scrcpy'
            $script:capturedProcess.ArgumentList | Should -Contain '--fullscreen'
        }
        
        It 'Calls scrcpy with device ID when provided' {
            Setup-AvailableCommandMock -CommandName 'scrcpy'
            
            $script:capturedProcess = $null
            Mock Start-Process -MockWith {
                $script:capturedProcess = @{
                    FilePath     = $FilePath
                    ArgumentList = $ArgumentList
                }
            }
            
            Mirror-AndroidScreen -DeviceId 'device123' -ErrorAction SilentlyContinue
            
            $script:capturedProcess.ArgumentList | Should -Contain '-s'
            $script:capturedProcess.ArgumentList | Should -Contain 'device123'
        }
    }
    
    Context 'Install-Apk' {
        It 'Returns false when adb is not available' {
            Mock-CommandAvailabilityPester -CommandName 'adb' -Available $false
            
            $result = Install-Apk -ApkPath 'test.apk' -ErrorAction SilentlyContinue
            
            $result | Should -Be $false
        }
        
        It 'Returns false when APK file does not exist' {
            Setup-AvailableCommandMock -CommandName 'adb'
            Mock Test-Path -ParameterFilter { $LiteralPath -eq 'nonexistent.apk' } -MockWith { return $false }
            
            $result = Install-Apk -ApkPath 'nonexistent.apk' -ErrorAction SilentlyContinue
            
            $result | Should -Be $false
        }
        
        It 'Calls adb install with APK path' {
            Setup-AvailableCommandMock -CommandName 'adb'
            Mock Test-Path -ParameterFilter { $LiteralPath -eq 'test.apk' } -MockWith { return $true }
            
            $script:capturedArgs = @()
            Mock -CommandName 'adb' -MockWith {
                $script:capturedArgs = $args
                $global:LASTEXITCODE = 0
                return 'Success'
            }
            
            $result = Install-Apk -ApkPath 'test.apk' -ErrorAction SilentlyContinue
            
            Should -Invoke 'adb' -Times 1 -Exactly
            $script:capturedArgs | Should -Contain 'install'
            $script:capturedArgs | Should -Contain 'test.apk'
            $result | Should -Be $true
        }
        
        It 'Calls adb install with ReplaceExisting flag' {
            Setup-AvailableCommandMock -CommandName 'adb'
            Mock Test-Path -ParameterFilter { $LiteralPath -eq 'test.apk' } -MockWith { return $true }
            
            $script:capturedArgs = @()
            Mock -CommandName 'adb' -MockWith {
                $script:capturedArgs = $args
                $global:LASTEXITCODE = 0
                return 'Success'
            }
            
            Install-Apk -ApkPath 'test.apk' -ReplaceExisting -ErrorAction SilentlyContinue
            
            $script:capturedArgs | Should -Contain '-r'
        }
    }
    
    Context 'Flash-Android' {
        It 'Returns null when pixelflasher is not available' {
            Mock-CommandAvailabilityPester -CommandName 'pixelflasher' -Available $false
            
            $result = Flash-Android -ErrorAction SilentlyContinue
            
            $result | Should -BeNullOrEmpty
        }
        
        It 'Calls pixelflasher when available' {
            Setup-AvailableCommandMock -CommandName 'pixelflasher'
            
            $script:capturedProcess = $null
            Mock Start-Process -MockWith {
                $script:capturedProcess = @{
                    FilePath     = $FilePath
                    ArgumentList = $ArgumentList
                }
            }
            
            Flash-Android -ErrorAction SilentlyContinue
            
            $script:capturedProcess | Should -Not -BeNullOrEmpty
            $script:capturedProcess.FilePath | Should -Be 'pixelflasher'
        }
    }
    
    Context 'Start-AndroidStudio' {
        It 'Returns null when Android Studio is not available' {
            Mock-CommandAvailabilityPester -CommandName 'android-studio-canary' -Available $false
            Mock-CommandAvailabilityPester -CommandName 'android-studio' -Available $false
            
            $result = Start-AndroidStudio -ErrorAction SilentlyContinue
            
            $result | Should -BeNullOrEmpty
        }
        
        It 'Calls android-studio-canary when available' {
            Setup-AvailableCommandMock -CommandName 'android-studio-canary'
            
            $script:capturedProcess = $null
            Mock Start-Process -MockWith {
                $script:capturedProcess = @{
                    FilePath     = $FilePath
                    ArgumentList = $ArgumentList
                }
            }
            
            Start-AndroidStudio -ErrorAction SilentlyContinue
            
            $script:capturedProcess | Should -Not -BeNullOrEmpty
            $script:capturedProcess.FilePath | Should -Be 'android-studio-canary'
        }
        
        It 'Falls back to android-studio when canary not available' {
            Mock-CommandAvailabilityPester -CommandName 'android-studio-canary' -Available $false
            Setup-AvailableCommandMock -CommandName 'android-studio'
            
            $script:capturedProcess = $null
            Mock Start-Process -MockWith {
                $script:capturedProcess = @{
                    FilePath     = $FilePath
                    ArgumentList = $ArgumentList
                }
            }
            
            Start-AndroidStudio -ErrorAction SilentlyContinue
            
            $script:capturedProcess.FilePath | Should -Be 'android-studio'
        }
    }
}

