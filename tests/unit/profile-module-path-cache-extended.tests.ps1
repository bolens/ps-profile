<#
tests/unit/profile-module-path-cache-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for ModulePathCache lookup and invalidation.
#>

BeforeAll {
    . (Join-Path $PSScriptRoot '..\TestSupport.ps1')

    $bootstrapPath = Get-TestPath -RelativePath 'profile.d\bootstrap\ModulePathCache.ps1' -StartPath $PSScriptRoot -EnsureExists
    . $bootstrapPath

    $script:TempDir = New-TestTempDirectory -Prefix 'ModulePathCacheExtended'
    $script:ModuleFile = Join-Path $script:TempDir 'sample-module.ps1'
    Set-Content -LiteralPath $script:ModuleFile -Value '# sample module' -Encoding UTF8
}

AfterAll {
    Clear-ModulePathCache | Out-Null

    if ($script:TempDir -and (Test-Path -LiteralPath $script:TempDir)) {
        Remove-Item -LiteralPath $script:TempDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Describe 'ModulePathCache extended scenarios' {
    BeforeEach {
        Clear-ModulePathCache | Out-Null
        Set-Content -LiteralPath $script:ModuleFile -Value '# sample module' -Encoding UTF8
    }

    Context 'Test-ModulePath' {
        It 'Returns false for whitespace-only paths' {
            Test-ModulePath -Path '   ' | Should -Be $false
        }

        It 'Caches positive lookup results for repeated calls' {
            $cacheProbeFile = Join-Path $script:TempDir 'cache-probe.ps1'
            Set-Content -LiteralPath $cacheProbeFile -Value '# cache probe' -Encoding UTF8

            $first = Test-ModulePath -Path $cacheProbeFile
            Remove-Item -LiteralPath $cacheProbeFile -Force

            $first | Should -Be $true
            Test-ModulePath -Path $cacheProbeFile | Should -Be $true
        }

        It 'Caches negative lookup results for missing paths' {
            $missingPath = Join-Path $script:TempDir 'missing-module.ps1'

            Test-ModulePath -Path $missingPath | Should -Be $false
            Test-ModulePath -Path $missingPath | Should -Be $false
        }
    }

    Context 'Remove-ModulePathCacheEntry' {
        It 'Forces the next lookup to re-check the filesystem' {
            Test-ModulePath -Path $script:ModuleFile | Should -Be $true
            Remove-ModulePathCacheEntry -Path $script:ModuleFile | Should -Be $true

            Remove-Item -LiteralPath $script:ModuleFile -Force -ErrorAction SilentlyContinue
            Test-ModulePath -Path $script:ModuleFile | Should -Be $false
        }
    }

    Context 'Clear-ModulePathCache' {
        It 'Clears all cached path entries' {
            Test-ModulePath -Path $script:ModuleFile | Out-Null
            Clear-ModulePathCache | Should -Be $true
            $global:PSProfileModulePathCache.Count | Should -Be 0
        }
    }
}
