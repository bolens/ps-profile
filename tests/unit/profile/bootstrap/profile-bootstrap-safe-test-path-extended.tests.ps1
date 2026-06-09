# ===============================================
# profile-bootstrap-safe-test-path-extended.tests.ps1
# Execution tests for bootstrap/SafeTestPath.ps1 behavior
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
    $script:BootstrapDir = Join-Path $script:ProfileDir 'bootstrap'
    . (Join-Path $script:ProfileDir 'bootstrap.ps1')
    $script:TempDir = New-TestTempDirectory -Prefix 'SafeTestPathExtended'
    $script:ExistingFile = Join-Path $script:TempDir 'exists.txt'
    Set-Content -LiteralPath $script:ExistingFile -Value 'exists' -Encoding UTF8
}

Describe 'profile.d/bootstrap/SafeTestPath.ps1 extended scenarios' {
    It 'Registers safe path testing helpers' {
        Get-Command Test-NullSafePath -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Trace-TestPath -ErrorAction Stop | Should -Not -BeNullOrEmpty
    }

    It 'Test-NullSafePath returns false for whitespace paths without prompting' {
        Test-NullSafePath -Path '   ' | Should -Be $false
        Test-NullSafePath -LiteralPath $script:ExistingFile -PathType Leaf | Should -Be $true
    }

    It 'Preserves safe path helper bodies on repeated module loads' {
        $firstTest = Get-Command Test-NullSafePath -ErrorAction Stop

        . (Join-Path $script:BootstrapDir 'SafeTestPath.ps1')

        (Get-Command Test-NullSafePath -ErrorAction Stop).ScriptBlock.ToString() |
            Should -Be $firstTest.ScriptBlock.ToString()
    }
}
