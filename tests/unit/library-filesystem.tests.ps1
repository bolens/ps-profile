. (Join-Path $PSScriptRoot '..\TestSupport.ps1')

Describe 'FileSystem Module Functions' {
    BeforeAll {
        Import-TestCommonModule | Out-Null
        $script:TestTempDir = New-TestTempDirectory -Prefix 'FileSystemTests'
    }

    AfterAll {
        if ($script:TestTempDir -and (Test-Path $script:TestTempDir)) {
            Remove-Item -Path $script:TestTempDir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    Context 'Test-PathParameter' {
        It 'Validates path parameter exists' {
            $testFile = Join-Path $script:TestTempDir 'test.txt'
            New-Item -ItemType File -Path $testFile -Force | Out-Null

            { Test-PathParameter -Path $testFile -PathType 'File' } | Should -Not -Throw
        }

        It 'Throws error for non-existent path' {
            $nonExistentPath = Join-Path $script:TestTempDir 'nonexistent.txt'
            { Test-PathParameter -Path $nonExistentPath -PathType 'File' } | Should -Throw
        }

        It 'Throws error for wrong path type' {
            $testDir = Join-Path $script:TestTempDir 'testdir'
            New-Item -ItemType Directory -Path $testDir -Force | Out-Null

            { Test-PathParameter -Path $testDir -PathType 'File' } | Should -Throw
        }
    }
}
