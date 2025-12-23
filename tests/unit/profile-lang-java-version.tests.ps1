# ===============================================
# profile-lang-java-version.tests.ps1
# Unit tests for Set-JavaVersion function
# ===============================================

. (Join-Path $PSScriptRoot '..\TestSupport.ps1')

# Import mocking utilities
$mockingDir = Join-Path (Split-Path $PSScriptRoot -Parent) 'TestSupport' 'Mocking'
Import-Module (Join-Path $mockingDir 'PesterMocks.psm1') -DisableNameChecking -ErrorAction SilentlyContinue

BeforeAll {
    $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
    . (Join-Path $script:ProfileDir 'bootstrap.ps1')
    . (Join-Path $script:ProfileDir 'lang-java.ps1')
}

Describe 'lang-java.ps1 - Set-JavaVersion' {
    BeforeEach {
        # Clear command cache
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }

        if (Get-Variable -Name 'TestCachedCommandCache' -Scope Global -ErrorAction SilentlyContinue) {
            $null = $global:TestCachedCommandCache.TryRemove('java', [ref]$null)
        }

        if (Get-Variable -Name 'AssumedAvailableCommands' -Scope Global -ErrorAction SilentlyContinue) {
            $null = $global:AssumedAvailableCommands.TryRemove('java', [ref]$null)
        }

        # Save original JAVA_HOME
        $script:originalJavaHome = $env:JAVA_HOME
        $script:originalPath = $env:PATH
    }

    AfterEach {
        # Restore original JAVA_HOME
        if ($script:originalJavaHome) {
            $env:JAVA_HOME = $script:originalJavaHome
        }
        else {
            Remove-Item -Path Env:JAVA_HOME -ErrorAction SilentlyContinue
        }
        $env:PATH = $script:originalPath
    }

    Context 'No parameters' {
        It 'Shows current Java version when java is available' {
            Setup-AvailableCommandMock -CommandName 'java'

            Mock -CommandName 'java' -MockWith {
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                if ($Arguments -contains '-version') {
                    return 'openjdk version "17.0.1"'
                }
                return $null
            }

            $result = Set-JavaVersion

            $result | Should -Not -BeNullOrEmpty
            Should -Invoke 'java' -Times 1 -ParameterFilter { $Arguments -contains '-version' }
        }

        It 'Shows warning when java is not available' {
            Mock-CommandAvailabilityPester -CommandName 'java' -Available $false
            Mock Get-Command -ParameterFilter { $Name -eq 'java' } -MockWith { return $null }

            $result = Set-JavaVersion -ErrorAction SilentlyContinue

            $result | Should -BeNullOrEmpty
        }
    }

    Context 'JavaHome parameter' {
        It 'Sets JAVA_HOME when path exists' {
            $testPath = 'C:\Test\Java\jdk-17'
            Mock Test-Path -ParameterFilter { $LiteralPath -eq $testPath -and $PathType -eq 'Container' } -MockWith { return $true }

            $result = Set-JavaVersion -JavaHome $testPath

            $result | Should -Not -BeNullOrEmpty
            $env:JAVA_HOME | Should -Be $testPath
        }

        It 'Shows error when path does not exist' {
            $testPath = 'C:\Test\Java\jdk-17'
            Mock Test-Path -ParameterFilter { $LiteralPath -eq $testPath -and $PathType -eq 'Container' } -MockWith { return $false }
            Mock Write-Error { }

            $result = Set-JavaVersion -JavaHome $testPath -ErrorAction SilentlyContinue

            $result | Should -BeNullOrEmpty
            Should -Invoke Write-Error -Times 1
        }
    }

    Context 'Version parameter' {
        It 'Finds and sets Java version when found' {
            $testPath = "$env:ProgramFiles\Java\jdk-17"
            Mock Test-Path -ParameterFilter { $LiteralPath -like "*\jdk-17" -and $PathType -eq 'Container' } -MockWith { return $true }
            Mock Get-ChildItem { return @{ FullName = $testPath; PSIsContainer = $true } }

            $result = Set-JavaVersion -Version '17'

            $result | Should -Not -BeNullOrEmpty
            $env:JAVA_HOME | Should -Be $testPath
        }

        It 'Shows warning when version not found' {
            Mock Test-Path -MockWith { return $false }
            Mock Get-ChildItem { return @() }

            $result = Set-JavaVersion -Version '99' -ErrorAction SilentlyContinue

            $result | Should -BeNullOrEmpty
        }
    }
}

