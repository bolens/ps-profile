<#
tests/unit/library-filesystem-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for FileSystem validation helpers and script discovery.
#>

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
    $libPath = Get-TestPath -RelativePath 'scripts\lib' -StartPath $PSScriptRoot -EnsureExists
    Import-Module (Join-Path $libPath 'file' 'FileSystem.psm1') -DisableNameChecking -Force

    $script:TempRoot = New-TestTempDirectory -Prefix 'FileSystemExtended'
}

AfterAll {
    Remove-Module FileSystem -ErrorAction SilentlyContinue -Force

    if ($script:TempRoot -and (Test-Path -LiteralPath $script:TempRoot)) {
        Remove-Item -LiteralPath $script:TempRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Describe 'FileSystem extended scenarios' {
    Context 'Test-RequiredParameters' {
        It 'Passes when all required parameters are populated' {
            { Test-RequiredParameters -Parameters @{ Path = 'value'; Name = 'sample' } } | Should -Not -Throw
        }

        It 'Throws when a required parameter is whitespace' {
            { Test-RequiredParameters -Parameters @{ Path = '   ' } } | Should -Throw '*Path*'
        }

        It 'Throws when a required parameter is null' {
            { Test-RequiredParameters -Parameters @{ Name = $null } } | Should -Throw '*Name*'
        }
    }

    Context 'Test-PathExists' {
        It 'Validates existing files with File path type' {
            $file = Join-Path $script:TempRoot 'exists.ps1'
            Set-Content -LiteralPath $file -Value '# sample' -Encoding UTF8

            Test-PathExists -Path $file -PathType File | Should -Be $true
        }

        It 'Throws when a directory is validated as a file' {
            $directory = Join-Path $script:TempRoot 'dir-only'
            New-Item -ItemType Directory -Path $directory -Force | Out-Null

            { Test-PathExists -Path $directory -PathType File } | Should -Throw '*not a file*'
        }
    }

    Context 'Get-PowerShellScripts' {
        It 'Sorts scripts by name when requested' {
            $scriptsDir = Join-Path $script:TempRoot 'sorted-scripts'
            New-Item -ItemType Directory -Path $scriptsDir -Force | Out-Null
            Set-Content -LiteralPath (Join-Path $scriptsDir 'z-last.ps1') -Value '# z' -Encoding UTF8
            Set-Content -LiteralPath (Join-Path $scriptsDir 'a-first.ps1') -Value '# a' -Encoding UTF8

            $scripts = @(Get-PowerShellScripts -Path $scriptsDir -SortByName)

            @($scripts).Count | Should -Be 2
            $scripts[0].Name | Should -Be 'a-first.ps1'
            $scripts[1].Name | Should -Be 'z-last.ps1'
        }

        It 'Finds scripts in nested directories when Recurse is enabled' {
            $root = Join-Path $script:TempRoot 'recursive-scripts'
            $nested = Join-Path $root 'nested'
            New-Item -ItemType Directory -Path $nested -Force | Out-Null
            Set-Content -LiteralPath (Join-Path $root 'root.ps1') -Value '# root' -Encoding UTF8
            Set-Content -LiteralPath (Join-Path $nested 'child.ps1') -Value '# child' -Encoding UTF8

            @((Get-PowerShellScripts -Path $root -Recurse)).Count | Should -Be 2
        }
    }
}
