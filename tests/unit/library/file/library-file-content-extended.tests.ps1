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
    $libPath = Get-TestPath -RelativePath 'scripts\lib' -StartPath $PSScriptRoot -EnsureExists
    Import-Module (Join-Path $libPath 'file' 'FileContent.psm1') -DisableNameChecking -Force

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
}
