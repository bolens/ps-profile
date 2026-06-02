# ===============================================
# profile-aws-enhanced.tests.ps1
# Unit tests for enhanced AWS functions
# ===============================================

BeforeAll {
    . (Join-Path $PSScriptRoot '..\TestSupport.ps1')
    $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
    . (Join-Path $script:ProfileDir 'bootstrap.ps1')
    . (Join-Path $script:ProfileDir 'aws.ps1')

    $script:OriginalSetAwsProfile = ${function:Set-AwsProfile}
    $script:OriginalTestAwsConnection = ${function:Test-AwsConnection}
    $script:TestAwsHome = New-TestTempDirectory -Prefix 'AwsHome'
    $script:TestCredentialsPath = Join-Path (Join-Path $script:TestAwsHome '.aws') 'credentials'
    $null = New-Item -ItemType Directory -Path (Split-Path $script:TestCredentialsPath -Parent) -Force
    Set-Content -Path $script:TestCredentialsPath -Value @(
        '[default]',
        'aws_access_key_id = AKIAIOSFODNN7EXAMPLE',
        'aws_secret_access_key = wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY',
        '[production]',
        'aws_access_key_id = AKIAI44QH8DHBEXAMPLE',
        'aws_secret_access_key = je7MtGbClwBF/2Zp9Utk/h3yCo8nvbEXAMPLEKEY'
    )
}

AfterAll {
    if ($script:OriginalSetAwsProfile) {
        Set-Item -Path Function:\Set-AwsProfile -Value $script:OriginalSetAwsProfile -Force
    }

    if ($script:OriginalTestAwsConnection) {
        Set-Item -Path Function:\Test-AwsConnection -Value $script:OriginalTestAwsConnection -Force
    }
}

function global:Install-TestAwsProfileStubs {
    param(
        [bool]$ConnectionResult = $true
    )

    $script:TestAwsConnectionResult = $ConnectionResult

    Set-Item -Path Function:\Set-AwsProfile -Value {
        param([string]$ProfileName)
        $script:TestAwsSelectedProfile = $ProfileName
        $env:AWS_PROFILE = $ProfileName
    } -Force

    Set-Item -Path Function:\Test-AwsConnection -Value {
        param([string]$Profile)
        return [bool]$script:TestAwsConnectionResult
    } -Force
}

function global:Reset-TestAwsProfileStubs {
    if ($script:OriginalSetAwsProfile) {
        Set-Item -Path Function:\Set-AwsProfile -Value $script:OriginalSetAwsProfile -Force
    }

    if ($script:OriginalTestAwsConnection) {
        Set-Item -Path Function:\Test-AwsConnection -Value $script:OriginalTestAwsConnection -Force
    }
}

Describe 'aws.ps1 - Enhanced Functions' {
    BeforeEach {
        Clear-TestCommandInvocationCapture
        Reset-TestAwsProfileStubs

        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }

        Set-TestCommandAvailabilityState -CommandName 'aws' -Available $false
        Remove-Item -Path 'Function:\aws' -Force -ErrorAction SilentlyContinue
        Remove-Item -Path 'Function:\global:aws' -Force -ErrorAction SilentlyContinue

        $script:OriginalHome = $env:HOME
        $script:OriginalUserProfile = $env:USERPROFILE
        $env:HOME = $script:TestAwsHome
        $env:USERPROFILE = $script:TestAwsHome
    }

    AfterEach {
        if ($null -ne $script:OriginalHome) {
            $env:HOME = $script:OriginalHome
        }

        if ($null -ne $script:OriginalUserProfile) {
            $env:USERPROFILE = $script:OriginalUserProfile
        }
    }

    Context 'Get-AwsCredentials' {
        It 'Returns null when aws is not available' {
            $result = Get-AwsCredentials -ErrorAction SilentlyContinue

            $result | Should -BeNullOrEmpty
        }

        It 'Parses credentials file correctly' {
            Setup-AvailableCommandMock -CommandName 'aws'

            $result = Get-AwsCredentials -ErrorAction SilentlyContinue

            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -Be 2
            $result[0].ProfileName | Should -Be 'default'
            $result[1].ProfileName | Should -Be 'production'
        }

        It 'Masks access keys when ShowKeys is specified' {
            Setup-AvailableCommandMock -CommandName 'aws'

            $result = Get-AwsCredentials -ShowKeys -ErrorAction SilentlyContinue

            $result[0].AccessKeyId | Should -Match '^\w{4}\*\*\*\*\w{4}$'
        }
    }

    Context 'Test-AwsConnection' {
        It 'Returns false when aws is not available' {
            $result = Test-AwsConnection -ErrorAction SilentlyContinue

            $result | Should -Be $false
        }

        It 'Handles missing aws command gracefully' {
            { Test-AwsConnection -ErrorAction Stop } | Should -Not -Throw
        }
    }

    Context 'Get-AwsResources' {
        It 'Returns null when aws is not available' {
            $result = Get-AwsResources -Service 'ec2' -Action 'describe-instances' -ErrorAction SilentlyContinue

            $result | Should -BeNullOrEmpty
        }

        It 'Requires Service and Action parameters' {
            $parameters = (Get-Command Get-AwsResources).Parameters
            $parameters.ContainsKey('Service') | Should -Be $true
            $parameters.ContainsKey('Action') | Should -Be $true
        }
    }

    Context 'Export-AwsCredentials' {
        It 'Returns null when aws is not available' {
            $result = Export-AwsCredentials -ErrorAction SilentlyContinue

            $result | Should -BeNullOrEmpty
        }

        It 'Handles missing aws command gracefully' {
            $result = Export-AwsCredentials -ErrorAction SilentlyContinue

            $result | Should -BeNullOrEmpty
        }
    }

    Context 'Switch-AwsAccount' {
        It 'Returns false when aws is not available' {
            $result = Switch-AwsAccount -ProfileName 'test' -ErrorAction SilentlyContinue

            $result | Should -Be $false
        }

        It 'Requires ProfileName parameter' {
            $parameters = (Get-Command Switch-AwsAccount).Parameters
            $parameters.ContainsKey('ProfileName') | Should -Be $true
        }

        It 'Switches profile and tests connection' {
            Setup-AvailableCommandMock -CommandName 'aws'
            Install-TestAwsProfileStubs -ConnectionResult $true

            $result = Switch-AwsAccount -ProfileName 'production' -ErrorAction SilentlyContinue

            $result | Should -Be $true
            $script:TestAwsSelectedProfile | Should -Be 'production'
        }

        It 'Skips test when SkipTest is specified' {
            Setup-AvailableCommandMock -CommandName 'aws'
            Install-TestAwsProfileStubs -ConnectionResult $true

            $result = Switch-AwsAccount -ProfileName 'dev' -SkipTest -ErrorAction SilentlyContinue

            $result | Should -Be $true
            $script:TestAwsSelectedProfile | Should -Be 'dev'
        }
    }

    Context 'Get-AwsCosts' {
        It 'Returns null when aws is not available' {
            $result = Get-AwsCosts -ErrorAction SilentlyContinue

            $result | Should -BeNullOrEmpty
        }

        It 'Handles missing aws command gracefully' {
            { Get-AwsCosts -ErrorAction Stop } | Should -Not -Throw
        }
    }
}
