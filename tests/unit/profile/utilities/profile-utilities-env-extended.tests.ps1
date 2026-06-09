# ===============================================
# profile-utilities-env-extended.tests.ps1
# Execution tests for utilities-modules/system/utilities-env.ps1 behavior
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
    . (Join-Path $script:ProfileDir 'files-module-registry.ps1')
    . (Join-Path $script:ProfileDir 'utilities.ps1')
    Ensure-Utilities
}

Describe 'profile.d/utilities-modules/system/utilities-env.ps1 extended scenarios' {
    It 'Registers environment variable helpers through Ensure-Utilities' {
        Get-Command Get-EnvVar -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Set-EnvVar -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Add-Path -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Remove-Path -ErrorAction Stop | Should -Not -BeNullOrEmpty
    }

    It 'Get-EnvVar reads process-scoped environment values' {
        $name = "PS_PROFILE_TEST_ENV_$([Guid]::NewGuid().ToString('N'))"
        Set-Item -Path "Env:$name" -Value 'profile-test-value' -Force

        try {
            Get-EnvVar -Name $name | Should -Be 'profile-test-value'
        }
        finally {
            Remove-Item -Path "Env:$name" -ErrorAction SilentlyContinue
        }
    }

    It 'Add-Path and Remove-Path manipulate PATH entries without throwing' {
        $entry = New-TestTempDirectory -Prefix 'UtilitiesEnvPath'
        try {
            { Add-Path -Path $entry | Out-Null } | Should -Not -Throw
            $env:PATH -split [System.IO.Path]::PathSeparator | Should -Contain $entry
            { Remove-Path -Path $entry | Out-Null } | Should -Not -Throw
        }
        finally {
            if ($env:PATH -and $env:PATH.Contains($entry)) {
                Remove-Path -Path $entry -ErrorAction SilentlyContinue | Out-Null
            }
        }
    }
}
