#
# Path and directory helper error handling tests.
#

. (Join-Path $PSScriptRoot '..\TestSupport.ps1')

BeforeAll {
    Import-TestCommonModule | Out-Null
    $script:TempRoot = New-TestTempDirectory -Prefix 'PathValidation'
}

Describe 'Path Validation Helpers' {
    BeforeEach {
        Get-ChildItem -LiteralPath $script:TempRoot -Force | ForEach-Object {
            Remove-Item -LiteralPath $_.FullName -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    AfterAll {
        if (Test-Path $script:TempRoot) {
            Remove-Item -LiteralPath $script:TempRoot -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    Context 'Get-RepoRoot' {
        It 'Throws for directories without git metadata' {
            $tempDir = Join-Path $script:TempRoot ([System.Guid]::NewGuid().ToString())
            New-Item -ItemType Directory -Path $tempDir -Force | Out-Null

            { Get-RepoRoot -ScriptPath $tempDir } | Should -Throw
        }
    }

    Context 'Resolve-DefaultPath' {
        It 'Throws for invalid explicit paths' {
            { Resolve-DefaultPath -Path 'Z:\this-path-should-not-exist' -DefaultPath 'C:\' -PathType File } | Should -Throw
        }

        It 'Returns default when path is null' {
            $defaultPath = Join-Path $script:TempRoot 'default'
            New-Item -ItemType Directory -Path $defaultPath -Force | Out-Null

            $result = Resolve-DefaultPath -Path $null -DefaultPath $defaultPath
            $result | Should -Be $defaultPath
        }

        It 'Validates provided directory paths' {
            $defaultPath = Join-Path $script:TempRoot 'default'
            New-Item -ItemType Directory -Path $defaultPath -Force | Out-Null
            $missingPath = Join-Path $script:TempRoot 'missing'

            { Resolve-DefaultPath -Path $missingPath -DefaultPath $defaultPath -PathType Directory } | Should -Throw
        }
    }

    Context 'Test-PathExists' {
        It 'Throws for non-existent paths' {
            $target = Join-Path $script:TempRoot 'nonexistent.file'
            { Test-PathExists -Path $target -PathType File } | Should -Throw
        }

        It 'Throws when path type does not match' {
            $filePath = Join-Path $script:TempRoot 'test.txt'
            New-Item -ItemType File -Path $filePath -Force | Out-Null

            { Test-PathExists -Path $filePath -PathType Directory } | Should -Throw
        }
    }

    Context 'Ensure-DirectoryExists' {
        It 'Creates directories that are missing' {
            $target = Join-Path $script:TempRoot 'nested\dir'
            Ensure-DirectoryExists -Path $target
            Test-Path -LiteralPath $target -PathType Container | Should -Be $true
        }

        It 'Allows ensuring existing directories' {
            $target = Join-Path $script:TempRoot 'existing'
            New-Item -ItemType Directory -Path $target -Force | Out-Null

            { Ensure-DirectoryExists -Path $target } | Should -Not -Throw
        }
    }
}
