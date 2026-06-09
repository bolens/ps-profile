# ===============================================
# profile-aws-fragment-extended.tests.ps1
# Execution tests for aws.ps1 fragment behavior
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
    . (Join-Path $script:ProfileDir 'aws.ps1')
}

Describe 'profile.d/aws.ps1 extended scenarios' {
    It 'Registers Invoke-Aws and profile management helpers' {
        Get-Command Invoke-Aws -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Set-AwsProfile -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Set-AwsRegion -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command aws -ErrorAction Stop | Should -Not -BeNullOrEmpty
    }

    It 'Set-AwsProfile sets AWS_PROFILE when aws is available' {
        Mark-TestCommandsUnavailable -CommandNames @('aws')
        Set-TestCommandAvailabilityState -CommandName 'aws' -Available $true
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }

                Set-AwsProfile -ProfileName 'fragment-test-profile'
        $env:AWS_PROFILE | Should -Be 'fragment-test-profile'
    }
    finally {
        Remove-Item Env:AWS_PROFILE -ErrorAction SilentlyContinue
    }

    It 'Invoke-Aws warns when aws is unavailable' {
        Mark-TestCommandsUnavailable -CommandNames @('aws')
        Set-TestCommandAvailabilityState -CommandName 'aws' -Available $false
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }
        if ($global:MissingToolWarnings) {
            $null = $global:MissingToolWarnings.TryRemove('aws', [ref]$null)
        }

        $output = Invoke-Aws --version 2>&1 3>&1 | Out-String
        Assert-TestMissingToolWarning -Output $output -Pattern 'aws not found'
    }
}
