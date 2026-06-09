# ===============================================
# profile-system-file-operations-extended.tests.ps1
# Execution tests for system/FileOperations.ps1 behavior
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
    $script:TestTempRoot = New-TestTempDirectory -Prefix 'ProfileSystemFileOps'
    . (Join-Path $script:ProfileDir 'bootstrap.ps1')
    . (Join-Path $script:ProfileDir 'files-module-registry.ps1')
    . (Join-Path $script:ProfileDir 'system.ps1')
}

function script:Reset-SystemFragmentState {
    Set-Variable -Name 'SystemInitialized' -Scope Global -Value $false -Force
}

Describe 'profile.d/system/FileOperations.ps1 extended scenarios' {
    BeforeEach {
        Reset-SystemFragmentState
        Ensure-System
    }

    It 'Registers file operation helpers through Ensure-System' {
        Get-Command New-EmptyFile -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command New-Directory -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Find-File -ErrorAction Stop | Should -Not -BeNullOrEmpty

        $touchAlias = Get-Alias touch -ErrorAction SilentlyContinue
        if ($touchAlias) {
            $touchAlias.ResolvedCommandName | Should -Be 'New-EmptyFile'
        }
    }

    It 'New-EmptyFile creates an empty file in a temp directory' {
        $tempFile = Join-Path $script:TestTempRoot 'touch-create.txt'
        New-EmptyFile -LiteralPath $tempFile

        Test-Path -LiteralPath $tempFile | Should -Be $true
        (Get-Item -LiteralPath $tempFile).Length | Should -Be 0
    }

    It 'Find-File locates files matching a filter under the current directory' {
        $searchRoot = Join-Path $script:TestTempRoot 'find-root'
        $nestedDir = Join-Path $searchRoot 'nested'
        New-Item -ItemType Directory -Path $nestedDir -Force | Out-Null
        $targetFile = Join-Path $nestedDir 'match-me.txt'
        Set-Content -Path $targetFile -Value 'find-me' -NoNewline

        Push-Location $searchRoot
        try {
            $matches = @(Find-File 'match-me.txt')
            $matches | Should -Contain 'nested/match-me.txt'
        }
        finally {
            Pop-Location
        }
    }
}
