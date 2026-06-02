# ===============================================
# profile-lang-java-version.tests.ps1
# Unit tests for Set-JavaVersion function
# ===============================================

BeforeAll {
    . (Join-Path $PSScriptRoot '..\TestSupport.ps1')
    $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
    . (Join-Path $script:ProfileDir 'bootstrap.ps1')
    . (Join-Path $script:ProfileDir 'lang-java-version.ps1')

    $script:TestRoot = New-TestTempDirectory -Prefix 'JavaVersion'
}

function global:New-TestJavaInstallation {
    param(
        [string]$Version = '17'
    )

    $jdkHome = Join-Path $script:TestRoot "jdk-$Version"
    $binDir = Join-Path $jdkHome 'bin'
    New-Item -ItemType Directory -Path $binDir -Force | Out-Null

    if ($IsWindows -or $PSVersionTable.Platform -eq 'Win32NT') {
        $javaPath = Join-Path $binDir 'java.exe'
        Set-Content -Path $javaPath -Value "@echo openjdk version `"$Version.0.1`""
    }
    else {
        $javaPath = Join-Path $binDir 'java'
        Set-Content -Path $javaPath -Value @(
            '#!/bin/sh'
            "echo 'openjdk version `"$Version.0.1`"' >&2"
        )
        & chmod +x $javaPath
    }

    return $jdkHome
}

Describe 'lang-java.ps1 - Set-JavaVersion' {
    BeforeEach {
        Clear-TestCommandInvocationCapture

        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }

        Mark-TestCommandsUnavailable -CommandNames 'java'

        $script:originalJavaHome = $env:JAVA_HOME
        $script:originalJreHome = $env:JRE_HOME
        $script:originalJdkHome = $env:JDK_HOME
        $script:originalPath = $env:PATH

        Remove-Item Env:JAVA_HOME -ErrorAction SilentlyContinue
        Remove-Item Env:JRE_HOME -ErrorAction SilentlyContinue
        Remove-Item Env:JDK_HOME -ErrorAction SilentlyContinue
    }

    AfterEach {
        if ($script:originalJavaHome) {
            $env:JAVA_HOME = $script:originalJavaHome
        }
        else {
            Remove-Item Env:JAVA_HOME -ErrorAction SilentlyContinue
        }

        if ($script:originalJreHome) {
            $env:JRE_HOME = $script:originalJreHome
        }
        else {
            Remove-Item Env:JRE_HOME -ErrorAction SilentlyContinue
        }

        if ($script:originalJdkHome) {
            $env:JDK_HOME = $script:originalJdkHome
        }
        else {
            Remove-Item Env:JDK_HOME -ErrorAction SilentlyContinue
        }

        $env:PATH = $script:originalPath
    }

    Context 'No parameters' {
        It 'Shows current Java version when java is available' {
            Setup-CapturingCommandMock -CommandName 'java' -Output 'openjdk version "17.0.1"'

            $result = Set-JavaVersion -ErrorAction SilentlyContinue

            $result | Should -Not -BeNullOrEmpty
            $global:TestCommandInvocationCaptures.Count | Should -Be 1
            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain '-version'
        }

        It 'Shows warning when java is not available' {
            $result = Set-JavaVersion -ErrorAction SilentlyContinue

            $result | Should -BeNullOrEmpty
        }
    }

    Context 'JavaHome parameter' {
        It 'Sets JAVA_HOME when path exists' {
            $jdkHome = New-TestJavaInstallation -Version '17'

            $result = Set-JavaVersion -JavaHome $jdkHome -ErrorAction SilentlyContinue

            $result | Should -Not -BeNullOrEmpty
            $env:JAVA_HOME | Should -Be $jdkHome
        }

        It 'Returns null when path does not exist' {
            $missingHome = Join-Path $script:TestRoot 'missing-jdk'

            $result = Set-JavaVersion -JavaHome $missingHome -ErrorAction SilentlyContinue

            $result | Should -BeNullOrEmpty
        }
    }

    Context 'Version parameter' {
        It 'Recognizes Java version already configured via JAVA_HOME' {
            $jdkHome = New-TestJavaInstallation -Version '17'
            $env:JAVA_HOME = $jdkHome

            $result = Set-JavaVersion -Version '17' -ErrorAction SilentlyContinue

            $result | Should -Not -BeNullOrEmpty
            $result | Should -Match '17'
            $env:JAVA_HOME | Should -Be $jdkHome
        }

        It 'Returns null when version is not found' {
            $result = Set-JavaVersion -Version '99' -ErrorAction SilentlyContinue

            $result | Should -BeNullOrEmpty
        }
    }
}
