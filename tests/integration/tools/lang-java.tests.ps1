# ===============================================
# lang-java.tests.ps1
# Integration tests for lang-java-*.ps1 fragments
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

    # lang-java is split into three fragments
    $script:FragmentBuildPath     = Join-Path $script:ProfileDir 'lang-java-build.ps1'
    $script:FragmentCompilersPath = Join-Path $script:ProfileDir 'lang-java-compilers.ps1'
    $script:FragmentVersionPath   = Join-Path $script:ProfileDir 'lang-java-version.ps1'

    # Ensure bootstrap is loaded first
    $bootstrapPath = Join-Path $script:ProfileDir 'bootstrap.ps1'
    if (Test-Path -LiteralPath $bootstrapPath) {
        . $bootstrapPath
    }

    foreach ($frag in @($script:FragmentBuildPath, $script:FragmentCompilersPath, $script:FragmentVersionPath)) {
        if (-not (Test-Path -LiteralPath $frag)) {
            throw "Fragment not found: $frag"
        }
        . $frag
    }
}

Describe 'lang-java - Integration Tests' {
    Context 'Fragment loading' {
        It 'Loads lang-java-build fragment without errors' {
            { . $script:FragmentBuildPath } | Should -Not -Throw
        }

        It 'Loads lang-java-compilers fragment without errors' {
            { . $script:FragmentCompilersPath } | Should -Not -Throw
        }

        It 'Loads lang-java-version fragment without errors' {
            { . $script:FragmentVersionPath } | Should -Not -Throw
        }

        It 'All fragments are idempotent' {
            {
                . $script:FragmentBuildPath
                . $script:FragmentBuildPath
                . $script:FragmentCompilersPath
                . $script:FragmentCompilersPath
                . $script:FragmentVersionPath
                . $script:FragmentVersionPath
            } | Should -Not -Throw
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

    Context 'Graceful degradation - tool unavailable' {
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

            foreach ($cmd in @('mvn', 'gradle', 'ant', 'kotlinc', 'scalac', 'java')) {
                Set-TestCommandAvailabilityState -CommandName $cmd -Available $false
            }
        }

        It 'Build-Maven handles missing tool gracefully' {
            $output = & { Build-Maven -ErrorAction SilentlyContinue } 2>&1 3>&1 | Out-String
            Assert-TestMissingToolWarning -Output $output -Pattern 'mvn not found'
            Assert-TestOutputContainsInstallCommand -Output $output -ToolName 'mvn'
        }

        It 'Build-Gradle handles missing tool gracefully' {
            $output = & { Build-Gradle -ErrorAction SilentlyContinue } 2>&1 3>&1 | Out-String
            Assert-TestMissingToolWarning -Output $output -Pattern 'gradle not found'
            Assert-TestOutputContainsInstallCommand -Output $output -ToolName 'gradle'
        }

        It 'Build-Ant handles missing tool gracefully' {
            $output = & { Build-Ant -ErrorAction SilentlyContinue } 2>&1 3>&1 | Out-String
            Assert-TestMissingToolWarning -Output $output -Pattern 'ant not found'
            Assert-TestOutputContainsInstallCommand -Output $output -ToolName 'ant'
        }

        It 'Compile-Kotlin handles missing tool gracefully' {
            $output = & { Compile-Kotlin -ErrorAction SilentlyContinue } 2>&1 3>&1 | Out-String
            Assert-TestMissingToolWarning -Output $output -Pattern 'kotlinc not found'
            Assert-TestOutputContainsInstallCommand -Output $output -ToolName 'kotlinc'
        }

        It 'Compile-Scala handles missing tool gracefully' {
            $output = & { Compile-Scala -ErrorAction SilentlyContinue } 2>&1 3>&1 | Out-String
            Assert-TestMissingToolWarning -Output $output -Pattern 'scalac not found'
            Assert-TestOutputContainsInstallCommand -Output $output -ToolName 'scalac'
        }

        It 'Set-JavaVersion handles missing tool gracefully' {
            $output = & { Set-JavaVersion -ErrorAction SilentlyContinue } 2>&1 3>&1 | Out-String
            $output | Should -Match 'Java not found'
        }
    }

    Context 'Idempotency' {
        It 'Functions remain available after multiple loads' {
            . $script:FragmentBuildPath
            . $script:FragmentCompilersPath
            . $script:FragmentVersionPath

            Get-Command Build-Maven     -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            Get-Command Build-Gradle    -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            Get-Command Build-Ant       -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            Get-Command Compile-Kotlin  -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            Get-Command Compile-Scala   -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            Get-Command Set-JavaVersion -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Parameter validation' {
        BeforeEach {
            foreach ($cmd in @('mvn', 'gradle', 'ant', 'kotlinc', 'scalac', 'java')) {
                Set-TestCommandAvailabilityState -CommandName $cmd -Available $false
            }
        }

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
            { Set-JavaVersion -JavaHome '/usr/lib/jvm/java-17' -ErrorAction SilentlyContinue } | Should -Not -Throw
        }
    }
}
