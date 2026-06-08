# ===============================================
# profile-re-tools-android.tests.ps1
# Unit tests for Extract-AndroidApk function
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
    $script:TestWorkDir = New-TestTempDirectory -Prefix 'ExtractAndroidApk'
    $script:TestApkFile = Join-Path $script:TestWorkDir 'test.apk'
    Set-Content -Path $script:TestApkFile -Value 'fake apk' -Encoding utf8
}

Describe 're-tools.ps1 - Extract-AndroidApk' {
    BeforeEach {
        Clear-TestCommandInvocationCapture

        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }

        Mark-TestCommandsUnavailable -CommandNames 'apktool'
    }

    Context 'Tool not available' {
        It 'Returns null when apktool is not available' {
            $result = Extract-AndroidApk -InputFile $script:TestApkFile -ErrorAction SilentlyContinue

            $result | Should -BeNullOrEmpty
        }
    }

    Context 'Tool available' {
        It 'Calls apktool with input file and output path' {
            Setup-CapturingCommandMock -CommandName 'apktool' -Output 'Extraction complete'

            Extract-AndroidApk -InputFile $script:TestApkFile -OutputPath $script:TestWorkDir -ErrorAction SilentlyContinue | Out-Null

            $global:TestCommandInvocationCaptures.Count | Should -Be 1
            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain 'd'
            $args | Should -Contain '-o'
            $args | Should -Contain $script:TestApkFile
        }

        It 'Calls apktool with Decompile flag' {
            Setup-CapturingCommandMock -CommandName 'apktool' -Output 'Extraction complete'

            Extract-AndroidApk -InputFile $script:TestApkFile -OutputPath $script:TestWorkDir -Decompile -ErrorAction SilentlyContinue | Out-Null

            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Not -Contain '--no-src'
        }

        It 'Calls apktool with NoResources flag' {
            Setup-CapturingCommandMock -CommandName 'apktool' -Output 'Extraction complete'

            Extract-AndroidApk -InputFile $script:TestApkFile -OutputPath $script:TestWorkDir -NoResources -ErrorAction SilentlyContinue | Out-Null

            $global:TestCommandInvocationCaptures.Count | Should -Be 1
            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain '--no-res'
            $args | Should -Contain '--no-src'
        }

        It 'Returns output path on success' {
            Setup-CapturingCommandMock -CommandName 'apktool' -ExitCode 0

            $result = Extract-AndroidApk -InputFile $script:TestApkFile -OutputPath $script:TestWorkDir -ErrorAction SilentlyContinue

            $result | Should -Be (Join-Path $script:TestWorkDir 'test')
        }

        It 'Handles missing input file' {
            Setup-CapturingCommandMock -CommandName 'apktool'
            $missingFile = Join-Path $script:TestWorkDir 'missing.apk'

            $result = Extract-AndroidApk -InputFile $missingFile -ErrorAction SilentlyContinue

            $result | Should -BeNullOrEmpty
        }

        It 'Handles command failure' {
            Setup-CapturingCommandMock -CommandName 'apktool' -ExitCode 1 -Output 'Error: Failed to extract'

            { Extract-AndroidApk -InputFile $script:TestApkFile -OutputPath $script:TestWorkDir -ErrorAction Stop } | Should -Throw
        }
    }
}
