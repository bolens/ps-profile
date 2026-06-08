# ===============================================
# profile-jq-yq-fragment-extended.tests.ps1
# Execution tests for jq-yq.ps1 fragment behavior
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
    Mark-TestCommandsUnavailable -CommandNames @('jq', 'yq')
    Set-TestCommandAvailabilityState -CommandName 'jq' -Available $true
    Set-TestCommandAvailabilityState -CommandName 'yq' -Available $true
    . (Join-Path $script:ProfileDir 'jq-yq.ps1')
    Register-TestFragmentAliases @{
        jq2json = 'Convert-JqToJson'
        yq2json = 'Convert-YqToJson'
    }
}

Describe 'profile.d/jq-yq.ps1 extended scenarios' {
    It 'Registers Convert-JqToJson and jq2json alias' {
        Get-Command Convert-JqToJson -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Alias jq2json -ErrorAction Stop | Should -Not -BeNullOrEmpty
        (Get-Alias jq2json).ResolvedCommandName | Should -Be 'Convert-JqToJson'
    }

    It 'Registers Convert-YqToJson and yq2json alias' {
        Get-Command Convert-YqToJson -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Alias yq2json -ErrorAction Stop | Should -Not -BeNullOrEmpty
        (Get-Alias yq2json).ResolvedCommandName | Should -Be 'Convert-YqToJson'
    }

    It 'Convert-JqToJson warns when jq is unavailable' {
        if ($global:MissingToolWarnings) {
            $null = $global:MissingToolWarnings.TryRemove('jq', [ref]$null)
        }
        Mark-TestCommandsUnavailable -CommandNames @('jq')
        Set-TestCommandAvailabilityState -CommandName 'jq' -Available $false
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }

        $testFile = New-TestTempFile -Prefix 'jq-fragment-test' -Extension '.json' -Content '{"ok":true}'
        try {
            $output = Convert-JqToJson -File $testFile 2>&1 3>&1 | Out-String
            Assert-TestMissingToolWarning -Output $output -Pattern 'jq not found'
        }
        finally {
            Remove-TestArtifacts
        }
    }
}
