# ===============================================
# profile-lang-java-gradle.tests.ps1
# Unit tests for Build-Gradle function
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
    . (Join-Path $script:ProfileDir 'bootstrap.ps1')
    . (Join-Path $script:ProfileDir 'lang-java-build.ps1')
}

Describe 'lang-java.ps1 - Build-Gradle' {
    BeforeEach {
        Clear-TestCommandInvocationCapture

        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }

        Set-TestCommandAvailabilityState -CommandName 'gradle' -Available $false
        Remove-Item -Path 'Function:\gradle' -Force -ErrorAction SilentlyContinue
        Remove-Item -Path 'Function:\global:gradle' -Force -ErrorAction SilentlyContinue
    }

    Context 'Tool not available' {
        It 'Returns null when gradle is not available' {
            $result = Build-Gradle -ErrorAction SilentlyContinue

            $result | Should -BeNullOrEmpty
        }
    }

    Context 'Tool available' {
        It 'Calls gradle without arguments' {
            Setup-CapturingCommandMock -CommandName 'gradle' -Output 'Build complete'

            $result = Build-Gradle -ErrorAction SilentlyContinue

            $global:TestCommandInvocationCaptures.Count | Should -Be 1
            @((Get-TestCommandInvocationArgsFlat | Where-Object { $null -ne $_ -and $_ -ne '' })).Count | Should -Be 0
            $result | Should -Be 'Build complete'
        }

        It 'Calls gradle with additional arguments' {
            Setup-CapturingCommandMock -CommandName 'gradle' -Output 'Build complete'

            Build-Gradle 'build', 'test' -ErrorAction SilentlyContinue | Out-Null

            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain 'build'
            $args | Should -Contain 'test'
        }
    }

    Context 'Error handling' {
        It 'Handles gradle execution errors' {
            Set-TestCommandThrowingMock -CommandName 'gradle' -Message 'gradle: command failed'

            { Build-Gradle -ErrorAction Stop } | Should -Throw
        }
    }
}
