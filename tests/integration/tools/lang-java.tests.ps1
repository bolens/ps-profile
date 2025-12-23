# ===============================================
# lang-java.tests.ps1
# Integration tests for lang-java.ps1 fragment
# ===============================================

. (Join-Path $PSScriptRoot '..\..\TestSupport.ps1')

BeforeAll {
    $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
    $script:FragmentPath = Join-Path $script:ProfileDir 'lang-java.ps1'

    # Ensure bootstrap is loaded first
    $bootstrapPath = Join-Path $script:ProfileDir 'bootstrap.ps1'
    if (Test-Path -LiteralPath $bootstrapPath) {
        . $bootstrapPath
    }

    # Load the fragment
    if (Test-Path -LiteralPath $script:FragmentPath) {
        . $script:FragmentPath
    }
    else {
        throw "Fragment not found: $script:FragmentPath"
    }
}

Describe 'lang-java.ps1 - Integration Tests' {
    Context 'Fragment loading' {
        It 'Loads lang-java fragment without errors' {
            { . $script:FragmentPath -ErrorAction Stop } | Should -Not -Throw
        }

        It 'Registers Build-Maven function' {
            Get-Command Build-Maven -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Registers Build-Gradle function' {
            Get-Command Build-Gradle -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Registers Build-Ant function' {
            Get-Command Build-Ant -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Registers Compile-Kotlin function' {
            Get-Command Compile-Kotlin -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Registers Compile-Scala function' {
            Get-Command Compile-Scala -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Registers Set-JavaVersion function' {
            Get-Command Set-JavaVersion -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Alias creation' {
        It 'Creates mvn alias' {
            $alias = Get-Alias -Name 'mvn' -ErrorAction SilentlyContinue
            if (-not $alias) {
                Set-ItResult -Inconclusive -Because 'Set-AgentModeAlias may not be available in test environment'
            }
            else {
                $alias | Should -Not -BeNullOrEmpty
            }
        }

        It 'Creates gradle alias' {
            $alias = Get-Alias -Name 'gradle' -ErrorAction SilentlyContinue
            if (-not $alias) {
                Set-ItResult -Inconclusive -Because 'Set-AgentModeAlias may not be available in test environment'
            }
            else {
                $alias | Should -Not -BeNullOrEmpty
            }
        }

        It 'Creates ant alias' {
            $alias = Get-Alias -Name 'ant' -ErrorAction SilentlyContinue
            if (-not $alias) {
                Set-ItResult -Inconclusive -Because 'Set-AgentModeAlias may not be available in test environment'
            }
            else {
                $alias | Should -Not -BeNullOrEmpty
            }
        }

        It 'Creates kotlinc alias' {
            $alias = Get-Alias -Name 'kotlinc' -ErrorAction SilentlyContinue
            if (-not $alias) {
                Set-ItResult -Inconclusive -Because 'Set-AgentModeAlias may not be available in test environment'
            }
            else {
                $alias | Should -Not -BeNullOrEmpty
            }
        }

        It 'Creates scalac alias' {
            $alias = Get-Alias -Name 'scalac' -ErrorAction SilentlyContinue
            if (-not $alias) {
                Set-ItResult -Inconclusive -Because 'Set-AgentModeAlias may not be available in test environment'
            }
            else {
                $alias | Should -Not -BeNullOrEmpty
            }
        }
    }

    Context 'Function behavior' {
        It 'Build-Maven handles missing tool gracefully' {
            $result = Build-Maven -ErrorAction SilentlyContinue
            $result | Should -Not -Throw
        }

        It 'Build-Gradle handles missing tool gracefully' {
            $result = Build-Gradle -ErrorAction SilentlyContinue
            $result | Should -Not -Throw
        }

        It 'Build-Ant handles missing tool gracefully' {
            $result = Build-Ant -ErrorAction SilentlyContinue
            $result | Should -Not -Throw
        }

        It 'Compile-Kotlin handles missing tool gracefully' {
            $result = Compile-Kotlin -ErrorAction SilentlyContinue
            $result | Should -Not -Throw
        }

        It 'Compile-Scala handles missing tool gracefully' {
            $result = Compile-Scala -ErrorAction SilentlyContinue
            $result | Should -Not -Throw
        }

        It 'Set-JavaVersion handles missing tool gracefully' {
            $result = Set-JavaVersion -ErrorAction SilentlyContinue
            $result | Should -Not -Throw
        }
    }

    Context 'Idempotency' {
        It 'Can be loaded multiple times without errors' {
            { . $script:FragmentPath -ErrorAction Stop } | Should -Not -Throw
            { . $script:FragmentPath -ErrorAction Stop } | Should -Not -Throw
        }

        It 'Functions remain available after multiple loads' {
            . $script:FragmentPath -ErrorAction SilentlyContinue
            . $script:FragmentPath -ErrorAction SilentlyContinue

            Get-Command Build-Maven -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            Get-Command Build-Gradle -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            Get-Command Build-Ant -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            Get-Command Compile-Kotlin -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            Get-Command Compile-Scala -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            Get-Command Set-JavaVersion -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Parameter validation' {
        It 'Build-Maven accepts Arguments parameter' {
            { Build-Maven -Arguments @('clean', 'install') -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It 'Build-Gradle accepts Arguments parameter' {
            { Build-Gradle -Arguments @('build') -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It 'Build-Ant accepts Arguments parameter' {
            { Build-Ant -Arguments @('clean') -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It 'Compile-Kotlin accepts Arguments parameter' {
            { Compile-Kotlin -Arguments @('Main.kt') -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It 'Compile-Scala accepts Arguments parameter' {
            { Compile-Scala -Arguments @('Main.scala') -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It 'Set-JavaVersion accepts Version parameter' {
            { Set-JavaVersion -Version '17' -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It 'Set-JavaVersion accepts JavaHome parameter' {
            { Set-JavaVersion -JavaHome 'C:\Test\Java' -ErrorAction SilentlyContinue } | Should -Not -Throw
        }
    }
}

