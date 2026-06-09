<#
tests/unit/library-file-content-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for Read-FileContentOrNull optional reads.
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
    $script:LibPath = Get-TestPath -RelativePath 'scripts\lib' -StartPath $PSScriptRoot -EnsureExists
    $script:FileContentPath = Join-Path $script:LibPath 'file' 'FileContent.psm1'
    Import-Module $script:FileContentPath -DisableNameChecking -Force

    $script:TempRoot = New-TestTempDirectory -Prefix 'FileContentExtended'
}

AfterAll {
    Remove-Module FileContent -ErrorAction SilentlyContinue -Force

    if ($script:TempRoot -and (Test-Path -LiteralPath $script:TempRoot)) {
        Remove-Item -LiteralPath $script:TempRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Describe 'FileContent extended scenarios' {
    Context 'Read-FileContentOrNull' {
        It 'Returns file content for readable files' {
            $file = Join-Path $script:TempRoot 'present.txt'
            Set-Content -LiteralPath $file -Value 'payload' -Encoding UTF8

            Read-FileContentOrNull -Path $file | Should -Match '^payload$'
        }

        It 'Returns null for missing files' {
            $missing = Join-Path $script:TempRoot 'missing.txt'

            Read-FileContentOrNull -Path $missing | Should -BeNullOrEmpty
        }

        It 'Returns null for whitespace-only files' {
            $blank = Join-Path $script:TempRoot 'blank.txt'
            Set-Content -LiteralPath $blank -Value '   ' -Encoding UTF8

            Read-FileContentOrNull -Path $blank | Should -BeNullOrEmpty
        }

        It 'Returns multiline content intact' {
            $file = Join-Path $script:TempRoot 'multiline.txt'
            @'
line one
line two
'@ | Set-Content -LiteralPath $file -Encoding UTF8

            $content = Read-FileContentOrNull -Path $file

            $content | Should -Match 'line one'
            $content | Should -Match 'line two'
        }
    }

    Context 'FileContent test environment hooks' {
        It 'Throws through Validation when ErrorAction is Stop and the file is missing' {
            Import-Module (Join-Path $script:LibPath 'core' 'Validation.psm1') -DisableNameChecking -Force -ErrorAction SilentlyContinue
            $missing = Join-Path $script:TempRoot 'validation-missing.txt'

            { Read-FileContent -Path $missing -ErrorAction Stop } | Should -Throw '*not found*'
        }

        It 'Returns empty string when Get-Content fails and ErrorAction is SilentlyContinue' {
            $file = Join-Path $script:TempRoot 'read-error.txt'
            Set-Content -LiteralPath $file -Value 'payload' -Encoding UTF8

            function global:Get-Content {
                [CmdletBinding()]
                param(
                    [Parameter(Mandatory)]
                    [string[]]$Path,

                    [switch]$Raw
                )

                if ($Path -match 'read-error\.txt$') {
                    throw 'file content read probe'
                }

                Microsoft.PowerShell.Management\Get-Content @PSBoundParameters
            }

            try {
                Read-FileContent -Path $file | Should -Be ''
            }
            finally {
                Remove-Item -Path Function:Get-Content -ErrorAction SilentlyContinue -Force
            }
        }

        It 'Loads ErrorHandling through manual import fallbacks when forced' {
            $originalFlag = $env:PS_PROFILE_FILECONTENT_FORCE_MANUAL_IMPORT
            $env:PS_PROFILE_FILECONTENT_FORCE_MANUAL_IMPORT = '1'

            Get-Module FileContent, SafeImport -All | Remove-Module -Force -ErrorAction SilentlyContinue

            try {
                Import-Module $script:FileContentPath -DisableNameChecking -Force
                Get-Command Read-FileContent -ErrorAction Stop | Should -Not -BeNullOrEmpty
            }
            finally {
                Remove-Module FileContent -ErrorAction SilentlyContinue -Force
                if ($null -eq $originalFlag) {
                    Remove-Item Env:PS_PROFILE_FILECONTENT_FORCE_MANUAL_IMPORT -ErrorAction SilentlyContinue
                }
                else {
                    $env:PS_PROFILE_FILECONTENT_FORCE_MANUAL_IMPORT = $originalFlag
                }

                Import-Module $script:FileContentPath -DisableNameChecking -Force
            }
        }

        It 'Uses manual validation when PS_PROFILE_FILECONTENT_SKIP_VALIDATION is enabled' {
            $missing = Join-Path $script:TempRoot 'manual-validation-missing.txt'
            $originalFlag = $env:PS_PROFILE_FILECONTENT_SKIP_VALIDATION
            $env:PS_PROFILE_FILECONTENT_SKIP_VALIDATION = '1'

            try {
                Read-FileContent -Path $missing | Should -Be ''
            }
            finally {
                if ($null -eq $originalFlag) {
                    Remove-Item Env:PS_PROFILE_FILECONTENT_SKIP_VALIDATION -ErrorAction SilentlyContinue
                }
                else {
                    $env:PS_PROFILE_FILECONTENT_SKIP_VALIDATION = $originalFlag
                }
            }
        }
    }
}
