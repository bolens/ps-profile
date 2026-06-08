<#
tests/unit/library-scoop-detection-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for ScoopDetection path resolution helpers.
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
    $scoopDetectionPath = Get-TestPath -RelativePath 'scripts\lib\runtime\ScoopDetection.psm1' -StartPath $PSScriptRoot -EnsureExists
    Import-Module $scoopDetectionPath -DisableNameChecking -Force

    $script:TempDir = New-TestTempDirectory -Prefix 'ScoopDetectionExtended'
    $script:FakeScoopRoot = Join-Path $script:TempDir 'scoop'
    New-Item -ItemType Directory -Path (Join-Path $script:FakeScoopRoot 'shims') -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $script:FakeScoopRoot 'apps') -Force | Out-Null
}

AfterAll {
    Remove-Module ScoopDetection -ErrorAction SilentlyContinue -Force

    if ($script:TempDir -and (Test-Path -LiteralPath $script:TempDir)) {
        Remove-Item -LiteralPath $script:TempDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Describe 'ScoopDetection extended scenarios' {
    Context 'Get-ScoopRoot' {
        It 'Prefers SCOOP_GLOBAL over SCOOP when both are set' {
            $globalRoot = Join-Path $script:TempDir 'scoop-global'
            New-Item -ItemType Directory -Path (Join-Path $globalRoot 'apps') -Force | Out-Null
            $originalGlobal = $env:SCOOP_GLOBAL
            $originalLocal = $env:SCOOP

            try {
                $env:SCOOP_GLOBAL = $globalRoot
                $env:SCOOP = $script:FakeScoopRoot

                Get-ScoopRoot | Should -Be $globalRoot
            }
            finally {
                $env:SCOOP_GLOBAL = $originalGlobal
                $env:SCOOP = $originalLocal
            }
        }
    }

    Context 'Get-ScoopShimsPath and Get-ScoopBinPath' {
        BeforeEach {
            $originalScoop = $env:SCOOP
            $env:SCOOP = $script:FakeScoopRoot
        }

        AfterEach {
            $env:SCOOP = $originalScoop
        }

        It 'Resolves the shims directory under the detected root' {
            Get-ScoopShimsPath | Should -Be (Join-Path $script:FakeScoopRoot 'shims')
        }

        It 'Returns null for bin path when the bin directory does not exist' {
            Get-ScoopBinPath | Should -BeNullOrEmpty
        }
    }

    Context 'Test-ScoopInstalled' {
        It 'Reports installed when a valid Scoop root is detected' {
            $originalScoop = $env:SCOOP
            try {
                $env:SCOOP = $script:FakeScoopRoot
                Test-ScoopInstalled | Should -Be $true
            }
            finally {
                $env:SCOOP = $originalScoop
            }
        }
    }
}
