<#
tests/unit/library-datafile-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for Import-CachedPowerShellDataFile edge cases.
#>

BeforeAll {
    . (Join-Path $PSScriptRoot '..\TestSupport.ps1')

    $libPath = Get-TestPath -RelativePath 'scripts\lib' -StartPath $PSScriptRoot -EnsureExists
    Import-Module (Join-Path $libPath 'utilities' 'DataFile.psm1') -DisableNameChecking -Force

    $script:TempRoot = New-TestTempDirectory -Prefix 'DataFileExtended'
}

AfterAll {
    Remove-Module DataFile -ErrorAction SilentlyContinue -Force

    if ($script:TempRoot -and (Test-Path -LiteralPath $script:TempRoot)) {
        Remove-Item -LiteralPath $script:TempRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Describe 'DataFile extended scenarios' {
    Context 'Import-CachedPowerShellDataFile' {
        It 'Returns an empty hashtable for @{} data files' {
            $file = Join-Path $script:TempRoot 'empty.psd1'
            Set-Content -LiteralPath $file -Value '@{}' -Encoding UTF8

            $result = Import-CachedPowerShellDataFile -Path $file

            $result | Should -BeOfType [hashtable]
            @($result.Keys).Count | Should -Be 0
        }

        It 'Imports nested hashtable structures' {
            $file = Join-Path $script:TempRoot 'nested.psd1'
            @'
@{
    Runner = @{
        Suite = 'Unit'
        Tags  = @('Smoke', 'Fast')
    }
}
'@ | Set-Content -LiteralPath $file -Encoding UTF8

            $result = Import-CachedPowerShellDataFile -Path $file

            $result.Runner.Suite | Should -Be 'Unit'
            @($result.Runner.Tags).Count | Should -Be 2
        }

        It 'Uses cached content on subsequent reads' {
            $file = Join-Path $script:TempRoot 'cached.psd1'
            @'
@{
    Version = '1.0.0'
}
'@ | Set-Content -LiteralPath $file -Encoding UTF8

            $first = Import-CachedPowerShellDataFile -Path $file
            $second = Import-CachedPowerShellDataFile -Path $file

            $first.Version | Should -Be '1.0.0'
            $second.Version | Should -Be '1.0.0'
        }

        It 'Throws for syntactically invalid data files' {
            $file = Join-Path $script:TempRoot 'invalid.psd1'
            Set-Content -LiteralPath $file -Value '@{' -Encoding UTF8

            { Import-CachedPowerShellDataFile -Path $file } | Should -Throw
        }
    }
}
