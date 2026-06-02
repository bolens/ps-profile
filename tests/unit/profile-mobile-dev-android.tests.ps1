# ===============================================
# profile-mobile-dev-android.tests.ps1
# Unit tests for Android functions
# ===============================================

BeforeAll {
    . (Join-Path $PSScriptRoot '..\TestSupport.ps1')
    $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
    . (Join-Path $script:ProfileDir 'bootstrap.ps1')
    . (Join-Path $script:ProfileDir 'mobile-dev.ps1')
    $script:TestApkPath = Join-Path (New-TestTempDirectory -Prefix 'AndroidApk') 'test.apk'
    Set-Content -Path $script:TestApkPath -Value 'fake apk' -Encoding utf8
}

Describe 'mobile-dev.ps1 - Android Functions' {
    BeforeEach {
        Clear-TestCommandInvocationCapture
        Clear-TestStartProcessCapture
        Reset-TestStartProcessMock

        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }

        Mark-TestCommandsUnavailable -CommandNames @('adb', 'scrcpy', 'pixelflasher', 'android-studio-canary', 'android-studio')
    }

    Context 'Connect-AndroidDevice' {
        It 'Returns empty array when adb is not available' {
            $result = Connect-AndroidDevice -ErrorAction SilentlyContinue

            $result | Should -BeNullOrEmpty
        }

        It 'Lists devices when ListDevices is specified' {
            Setup-CapturingCommandMock -CommandName 'adb' -OnInvoke {
                return @(
                    'List of devices attached',
                    'device123    device',
                    'device456    device'
                )
            }

            $result = Connect-AndroidDevice -ListDevices -ErrorAction SilentlyContinue

            $result | Should -Not -BeNullOrEmpty
            @($result).Count | Should -BeGreaterThan 0
        }

        It 'Connects to device via network when DeviceIp is provided' {
            Setup-CapturingCommandMock -CommandName 'adb' -Output 'connected to 192.168.1.100:5555'

            $result = Connect-AndroidDevice -DeviceIp '192.168.1.100' -ErrorAction SilentlyContinue

            $global:TestCommandInvocationCaptures.Count | Should -Be 1
            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain 'connect'
            $result | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Mirror-AndroidScreen' {
        It 'Returns null when scrcpy is not available' {
            $result = Mirror-AndroidScreen -ErrorAction SilentlyContinue

            $result | Should -BeNullOrEmpty
        }

        It 'Calls scrcpy with fullscreen flag' {
            Setup-AvailableCommandMock -CommandName 'scrcpy'

            Mirror-AndroidScreen -Fullscreen -ErrorAction SilentlyContinue | Out-Null

            $capture = Get-TestStartProcessCapture
            $capture | Should -Not -BeNullOrEmpty
            $capture.FilePath | Should -Be 'scrcpy'
            $capture.ArgumentList | Should -Contain '--fullscreen'
        }

        It 'Calls scrcpy with device ID when provided' {
            Setup-AvailableCommandMock -CommandName 'scrcpy'

            Mirror-AndroidScreen -DeviceId 'device123' -ErrorAction SilentlyContinue | Out-Null

            $capture = Get-TestStartProcessCapture
            $capture.ArgumentList | Should -Contain '-s'
            $capture.ArgumentList | Should -Contain 'device123'
        }
    }

    Context 'Install-Apk' {
        It 'Returns false when adb is not available' {
            $result = Install-Apk -ApkPath $script:TestApkPath -ErrorAction SilentlyContinue

            $result | Should -Be $false
        }

        It 'Returns false when APK file does not exist' {
            Setup-AvailableCommandMock -CommandName 'adb'
            $missingApk = Join-Path (New-TestTempDirectory -Prefix 'MissingApkParent') 'nonexistent.apk'

            $result = Install-Apk -ApkPath $missingApk -ErrorAction SilentlyContinue

            $result | Should -Be $false
        }

        It 'Calls adb install with APK path' {
            Setup-CapturingCommandMock -CommandName 'adb' -Output 'Success'

            $result = Install-Apk -ApkPath $script:TestApkPath -ErrorAction SilentlyContinue

            $global:TestCommandInvocationCaptures.Count | Should -Be 1
            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain 'install'
            $args | Should -Contain $script:TestApkPath
            $result | Should -Be $true
        }

        It 'Calls adb install with ReplaceExisting flag' {
            Setup-CapturingCommandMock -CommandName 'adb' -Output 'Success'

            Install-Apk -ApkPath $script:TestApkPath -ReplaceExisting -ErrorAction SilentlyContinue | Out-Null

            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain '-r'
        }
    }

    Context 'Flash-Android' {
        It 'Returns null when pixelflasher is not available' {
            $result = Flash-Android -ErrorAction SilentlyContinue

            $result | Should -BeNullOrEmpty
        }

        It 'Calls pixelflasher when available' {
            Setup-AvailableCommandMock -CommandName 'pixelflasher'

            Flash-Android -ErrorAction SilentlyContinue | Out-Null

            $capture = Get-TestStartProcessCapture
            $capture | Should -Not -BeNullOrEmpty
            $capture.FilePath | Should -Be 'pixelflasher'
        }
    }

    Context 'Start-AndroidStudio' {
        It 'Returns null when Android Studio is not available' {
            $result = Start-AndroidStudio -ErrorAction SilentlyContinue

            $result | Should -BeNullOrEmpty
        }

        It 'Calls android-studio-canary when available' {
            Setup-AvailableCommandMock -CommandName 'android-studio-canary'

            Start-AndroidStudio -ErrorAction SilentlyContinue | Out-Null

            $capture = Get-TestStartProcessCapture
            $capture | Should -Not -BeNullOrEmpty
            $capture.FilePath | Should -Be 'android-studio-canary'
        }

        It 'Falls back to android-studio when canary not available' {
            Setup-AvailableCommandMock -CommandName 'android-studio'
            Mark-TestCommandsUnavailable -CommandNames 'android-studio-canary'

            Start-AndroidStudio -ErrorAction SilentlyContinue | Out-Null

            $capture = Get-TestStartProcessCapture
            $capture.FilePath | Should -Be 'android-studio'
        }
    }
}
