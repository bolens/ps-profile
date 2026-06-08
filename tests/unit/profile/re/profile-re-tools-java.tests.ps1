# ===============================================
# profile-re-tools-java.tests.ps1
# Unit tests for Decompile-Java function
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
    . (Join-Path $script:ProfileDir 're-tools.ps1')
    $script:TestWorkDir = New-TestTempDirectory -Prefix 'DecompileJava'
    $script:TestDexFile = Join-Path $script:TestWorkDir 'test.dex'
    $script:TestApkFile = Join-Path $script:TestWorkDir 'test.apk'
    Set-Content -Path $script:TestDexFile -Value 'fake dex' -Encoding utf8
    Set-Content -Path $script:TestApkFile -Value 'fake apk' -Encoding utf8
}

Describe 're-tools.ps1 - Decompile-Java' {
    BeforeEach {
        Clear-TestCommandInvocationCapture

        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }

        Set-TestCommandAvailabilityState -CommandName 'jadx' -Available $false
        Remove-Item -Path 'Function:\jadx' -Force -ErrorAction SilentlyContinue
        Remove-Item -Path 'Function:\global:jadx' -Force -ErrorAction SilentlyContinue
    }

    Context 'Tool not available' {
        It 'Returns null when jadx is not available' {
            $result = Decompile-Java -InputFile $script:TestDexFile -ErrorAction SilentlyContinue

            $result | Should -BeNullOrEmpty
        }
    }

    Context 'Tool available' {
        It 'Calls jadx with input file and output path' {
            Setup-CapturingCommandMock -CommandName 'jadx' -Output 'Decompilation complete'

            $result = Decompile-Java -InputFile $script:TestDexFile -OutputPath $script:TestWorkDir -ErrorAction SilentlyContinue

            $global:TestCommandInvocationCaptures.Count | Should -Be 1
            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain '-d'
            $args | Should -Contain $script:TestWorkDir
            $args | Should -Contain $script:TestDexFile
            $result | Should -Be $script:TestWorkDir
        }

        It 'Calls jadx with DecompileResources flag' {
            Setup-CapturingCommandMock -CommandName 'jadx' -Output 'Decompilation complete'

            Decompile-Java -InputFile $script:TestApkFile -DecompileResources -OutputPath $script:TestWorkDir -ErrorAction SilentlyContinue | Out-Null

            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain '--no-res'
        }

        It 'Returns output path on success' {
            Setup-CapturingCommandMock -CommandName 'jadx' -ExitCode 0

            $result = Decompile-Java -InputFile $script:TestDexFile -OutputPath $script:TestWorkDir -ErrorAction SilentlyContinue

            $result | Should -Be $script:TestWorkDir
        }

        It 'Handles missing input file' {
            Set-TestCommandAvailabilityState -CommandName 'jadx'
            $missingFile = Join-Path $script:TestWorkDir 'missing.dex'

            $result = Decompile-Java -InputFile $missingFile -ErrorAction SilentlyContinue

            $result | Should -BeNullOrEmpty
        }

        It 'Handles command failure' {
            Setup-CapturingCommandMock -CommandName 'jadx' -ExitCode 1 -Output 'Error: Failed to decompile'

            { Decompile-Java -InputFile $script:TestDexFile -OutputPath $script:TestWorkDir -ErrorAction Stop } | Should -Throw
        }
    }
}
