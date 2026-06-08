# ===============================================
# profile-minio-fragment-extended.tests.ps1
# Execution tests for minio.ps1 fragment behavior
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
    . (Join-Path $script:ProfileDir 'minio.ps1')
}

Describe 'profile.d/minio.ps1 extended scenarios' {
    It 'Registers MinIO client helpers and aliases' {
        Get-Command Get-MinioFileList -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Copy-MinioFile -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command mc-ls -ErrorAction Stop | Should -Not -BeNullOrEmpty
    }

    It 'Get-MinioFileList warns when mc is unavailable' {
        Set-TestCommandAvailabilityState -CommandName 'mc' -Available $false
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }
        if ($global:MissingToolWarnings) {
            $null = $global:MissingToolWarnings.TryRemove('mc', [ref]$null)
        }

        $output = Get-MinioFileList 'local/bucket' 2>&1 3>&1 | Out-String
        Assert-TestMissingToolWarning -Output $output -Pattern 'mc not found'
    }

    It 'Preserves existing minio helper bodies on repeated fragment loads' {
        $firstList = Get-Command Get-MinioFileList -ErrorAction Stop

        . (Join-Path $script:ProfileDir 'minio.ps1')

        (Get-Command Get-MinioFileList -ErrorAction Stop).ScriptBlock.ToString() |
            Should -Be $firstList.ScriptBlock.ToString()
    }
}
