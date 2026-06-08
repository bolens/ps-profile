<#
tests/unit/library-envfile-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for Load-EnvFile preservation and parsing rules.
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
    Import-Module (Join-Path $libPath 'utilities' 'EnvFile.psm1') -DisableNameChecking -Force

    $script:TempRoot = New-TestTempDirectory -Prefix 'EnvFileExtended'
}

AfterAll {
    Remove-Module EnvFile -ErrorAction SilentlyContinue -Force

    if ($script:TempRoot -and (Test-Path -LiteralPath $script:TempRoot)) {
        Remove-Item -LiteralPath $script:TempRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Describe 'EnvFile extended scenarios' {
    Context 'Load-EnvFile' {
        It 'Preserves existing environment variables unless Overwrite is specified' {
            $envFile = Join-Path $script:TempRoot 'preserve.env'
            'PRESERVE_ME=from-file' | Set-Content -LiteralPath $envFile -Encoding UTF8

            $env:PRESERVE_ME = 'existing-value'
            try {
                Load-EnvFile -EnvFilePath $envFile
                $env:PRESERVE_ME | Should -Be 'existing-value'
            }
            finally {
                Remove-Item Env:\PRESERVE_ME -ErrorAction SilentlyContinue
            }
        }

        It 'Overwrites existing environment variables when requested' {
            $envFile = Join-Path $script:TempRoot 'overwrite.env'
            'OVERWRITE_ME=replaced' | Set-Content -LiteralPath $envFile -Encoding UTF8

            $env:OVERWRITE_ME = 'original-value'
            try {
                Load-EnvFile -EnvFilePath $envFile -Overwrite
                $env:OVERWRITE_ME | Should -Be 'replaced'
            }
            finally {
                Remove-Item Env:\OVERWRITE_ME -ErrorAction SilentlyContinue
            }
        }

        It 'Skips lines that do not contain an assignment' {
            $envFile = Join-Path $script:TempRoot 'invalid-lines.env'
            @'
NOT_AN_ASSIGNMENT
VALID_VAR=loaded
'@ | Set-Content -LiteralPath $envFile -Encoding UTF8

            try {
                Load-EnvFile -EnvFilePath $envFile
                $env:VALID_VAR | Should -Be 'loaded'
                Get-Item Env:\NOT_AN_ASSIGNMENT -ErrorAction SilentlyContinue | Should -BeNullOrEmpty
            }
            finally {
                Remove-Item Env:\VALID_VAR -ErrorAction SilentlyContinue
            }
        }

        It 'Ignores comment-only lines mixed with assignments' {
            $envFile = Join-Path $script:TempRoot 'comments.env'
            @'
# comment line
COMMENTED_PAIR=kept
'@ | Set-Content -LiteralPath $envFile -Encoding UTF8

            try {
                Load-EnvFile -EnvFilePath $envFile
                $env:COMMENTED_PAIR | Should -Be 'kept'
            }
            finally {
                Remove-Item Env:\COMMENTED_PAIR -ErrorAction SilentlyContinue
            }
        }
    }
}
