# ===============================================
# profile-re-tools-il2cpp.tests.ps1
# Unit tests for Dump-IL2CPP function
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
    $script:TestWorkDir = New-TestTempDirectory -Prefix 'DumpIL2CPP'
    $script:MetadataFile = Join-Path $script:TestWorkDir 'metadata.dat'
    $script:BinaryFile = Join-Path $script:TestWorkDir 'GameAssembly.dll'
    Set-Content -Path $script:MetadataFile -Value 'fake metadata' -Encoding utf8
    Set-Content -Path $script:BinaryFile -Value 'fake binary' -Encoding utf8
}

Describe 're-tools.ps1 - Dump-IL2CPP' {
    BeforeEach {
        Clear-TestCommandInvocationCapture

        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }

        Mark-TestCommandsUnavailable -CommandNames 'il2cppdumper'
    }

    Context 'Tool not available' {
        It 'Returns null when il2cppdumper is not available' {
            $result = Dump-IL2CPP -MetadataFile $script:MetadataFile -BinaryFile $script:BinaryFile -ErrorAction SilentlyContinue

            $result | Should -BeNullOrEmpty
        }
    }

    Context 'Tool available' {
        It 'Calls il2cppdumper with metadata and binary files' {
            Setup-CapturingCommandMock -CommandName 'il2cppdumper' -Output 'Dump complete'

            Dump-IL2CPP -MetadataFile $script:MetadataFile -BinaryFile $script:BinaryFile -OutputPath $script:TestWorkDir -ErrorAction SilentlyContinue | Out-Null

            $global:TestCommandInvocationCaptures.Count | Should -Be 1
            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain $script:BinaryFile
            $args | Should -Contain $script:MetadataFile
            $args | Should -Contain $script:TestWorkDir
        }

        It 'Calls il2cppdumper with Unity version when specified' {
            Setup-CapturingCommandMock -CommandName 'il2cppdumper' -Output 'Dump complete'

            Dump-IL2CPP -MetadataFile $script:MetadataFile -BinaryFile $script:BinaryFile -OutputPath $script:TestWorkDir -UnityVersion '2021.3.0' -ErrorAction SilentlyContinue | Out-Null

            $global:TestCommandInvocationCaptures.Count | Should -Be 1
            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain '-v'
            $args | Should -Contain '2021.3.0'
        }

        It 'Returns output path on success' {
            Setup-CapturingCommandMock -CommandName 'il2cppdumper' -ExitCode 0

            $result = Dump-IL2CPP -MetadataFile $script:MetadataFile -BinaryFile $script:BinaryFile -OutputPath $script:TestWorkDir -ErrorAction SilentlyContinue

            $result | Should -Be $script:TestWorkDir
        }

        It 'Handles missing metadata file' {
            Setup-CapturingCommandMock -CommandName 'il2cppdumper'
            $missingFile = Join-Path $script:TestWorkDir 'missing.dat'

            $result = Dump-IL2CPP -MetadataFile $missingFile -BinaryFile $script:BinaryFile -ErrorAction SilentlyContinue

            $result | Should -BeNullOrEmpty
        }

        It 'Handles missing binary file' {
            Setup-CapturingCommandMock -CommandName 'il2cppdumper'
            $missingFile = Join-Path $script:TestWorkDir 'missing.dll'

            $result = Dump-IL2CPP -MetadataFile $script:MetadataFile -BinaryFile $missingFile -ErrorAction SilentlyContinue

            $result | Should -BeNullOrEmpty
        }

        It 'Handles command failure' {
            Setup-CapturingCommandMock -CommandName 'il2cppdumper' -ExitCode 1 -Output 'Error: Failed to dump'

            { Dump-IL2CPP -MetadataFile $script:MetadataFile -BinaryFile $script:BinaryFile -OutputPath $script:TestWorkDir -ErrorAction Stop } | Should -Throw
        }
    }
}
