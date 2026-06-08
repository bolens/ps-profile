# ===============================================
# profile-lang-java-maven.tests.ps1
# Unit tests for Build-Maven function
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

Describe 'lang-java.ps1 - Build-Maven' {
    BeforeEach {
        Clear-TestCommandInvocationCapture

        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }

        Set-TestCommandAvailabilityState -CommandName 'mvn' -Available $false
        Remove-Item -Path 'Function:\mvn' -Force -ErrorAction SilentlyContinue
        Remove-Item -Path 'Function:\global:mvn' -Force -ErrorAction SilentlyContinue
    }

    Context 'Tool not available' {
        It 'Returns null when mvn is not available' {
            $result = Build-Maven -ErrorAction SilentlyContinue

            $result | Should -BeNullOrEmpty
        }
    }

    Context 'Tool available' {
        It 'Calls mvn without arguments' {
            Setup-CapturingCommandMock -CommandName 'mvn' -Output 'Build complete'

            $result = Build-Maven -ErrorAction SilentlyContinue

            $global:TestCommandInvocationCaptures.Count | Should -Be 1
            @((Get-TestCommandInvocationArgsFlat | Where-Object { $null -ne $_ -and $_ -ne '' })).Count | Should -Be 0
            $result | Should -Be 'Build complete'
        }

        It 'Calls mvn with additional arguments' {
            Setup-CapturingCommandMock -CommandName 'mvn' -Output 'Build complete'

            Build-Maven 'clean', 'install' -ErrorAction SilentlyContinue | Out-Null

            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain 'clean'
            $args | Should -Contain 'install'
        }
    }

    Context 'Error handling' {
        It 'Handles mvn execution errors' {
            Set-TestCommandThrowingMock -CommandName 'mvn' -Message 'mvn: command failed'

            { Build-Maven -ErrorAction Stop } | Should -Throw
        }
    }
}
