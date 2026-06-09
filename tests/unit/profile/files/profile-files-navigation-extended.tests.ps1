# ===============================================
# profile-files-navigation-extended.tests.ps1
# Execution tests for files-modules/navigation/files-navigation.ps1 behavior
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
    $script:TestTempRoot = New-TestTempDirectory -Prefix 'ProfileFilesNavigation'
    . (Join-Path $script:ProfileDir 'bootstrap.ps1')
}

Describe 'profile.d/files-modules/navigation/files-navigation.ps1 extended scenarios' {
    BeforeEach {
        . (Join-Path $script:ProfileDir 'files-modules/navigation/files-navigation.ps1')
    }

    It 'Registers Ensure-FileNavigation and parent-directory helpers' {
        Get-Command Ensure-FileNavigation -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command .. -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command ... -ErrorAction Stop | Should -Not -BeNullOrEmpty
    }

    It 'Ensure-FileNavigation materializes navigation helper functions' {
        Ensure-FileNavigation

        Test-Path -Path Function:\__FileNavigation_UpOne | Should -Be $true
        Test-Path -Path Function:\__FileNavigation_Home | Should -Be $true
    }

    It 'Parent-directory helper moves up one level' {
        $childDir = Join-Path $script:TestTempRoot 'child'
        New-Item -ItemType Directory -Path $childDir -Force | Out-Null

        Push-Location $childDir
        try {
            .. | Out-Null
            (Get-Location).Path | Should -Be (Resolve-Path -LiteralPath $script:TestTempRoot).Path
        }
        finally {
            Pop-Location
        }
    }
}
