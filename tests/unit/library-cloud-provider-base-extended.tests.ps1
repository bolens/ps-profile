<#
tests/unit/library-cloud-provider-base-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for CloudProviderBase helper edge cases.
#>

BeforeAll {
    . (Join-Path $PSScriptRoot '..\TestSupport.ps1')

    $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
    . (Join-Path $script:ProfileDir 'bootstrap.ps1')

    $errorHandlingPath = Join-Path $script:ProfileDir 'bootstrap' 'ErrorHandlingStandard.ps1'
    if (Test-Path -LiteralPath $errorHandlingPath) {
        . $errorHandlingPath
    }

    $script:RealInvokeWithWideEvent = ${function:Invoke-WithWideEvent}
    function Invoke-WithWideEvent {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory)]
            [string]$OperationName,
            [Parameter(Mandatory)]
            [scriptblock]$ScriptBlock,
            [hashtable]$Context = @{},
            [ValidateSet('DEBUG', 'INFO', 'WARN', 'ERROR', 'FATAL')]
            [string]$Level = 'INFO',
            [switch]$AlwaysKeep
        )

        & $script:RealInvokeWithWideEvent -OperationName $OperationName -ScriptBlock $ScriptBlock -Context $Context -Level $Level -AlwaysKeep:$true
    }

    . (Join-Path $script:ProfileDir 'bootstrap' 'CloudProviderBase.ps1')

    if (-not (Get-Variable -Name MissingToolWarnings -Scope Global -ErrorAction SilentlyContinue)) {
        $global:MissingToolWarnings = @{}
    }

    if (-not (Get-Variable -Name CollectedMissingToolWarnings -Scope Global -ErrorAction SilentlyContinue)) {
        $global:CollectedMissingToolWarnings = [System.Collections.Generic.List[hashtable]]::new()
    }
}

AfterAll {
    if ($script:RealInvokeWithWideEvent) {
        Set-Item -Path 'Function:\Global:Invoke-WithWideEvent' -Value $script:RealInvokeWithWideEvent -Force -ErrorAction SilentlyContinue
    }
}

$global:ClearCloudCommandMocks = {
    foreach ($commandName in @('aws', 'az', 'gcloud')) {
        Remove-Item "Function:\Global:$commandName" -Force -ErrorAction SilentlyContinue
    }
}

Describe 'CloudProviderBase extended scenarios' {
    BeforeEach {
        & $global:ClearCloudCommandMocks
        $global:LASTEXITCODE = 0
        $env:PS_PROFILE_SUPPRESS_EVENTS = '1'

        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }

        if (Get-Command Clear-EventCollection -ErrorAction SilentlyContinue) {
            Clear-EventCollection | Out-Null
        }
    }

    Context 'Resolve-CloudInstallHint' {
        It 'Returns an explicit install hint when provided' {
            Resolve-CloudInstallHint -CommandName 'aws' -InstallHint 'Install via package manager' |
                Should -Be 'Install via package manager'
        }

        It 'Uses InstallPackageName in the default scoop hint' {
            Resolve-CloudInstallHint -CommandName 'aws' -InstallPackageName 'aws-cli' |
                Should -Match 'aws-cli'
        }
    }

    Context 'Test-CloudConnection' {
        It 'Returns false when the cloud command is unavailable' {
            Mark-TestCommandsUnavailable -CommandNames 'aws'

            Test-CloudConnection -CommandName 'aws' -TestCommand @('sts', 'get-caller-identity') |
                Should -Be $false
        }
    }

    Context 'Invoke-CloudCommand' {
        It 'Joins all arguments in wide event context' {
            Set-TestCommandAvailabilityState -CommandName 'aws'

            Set-Item -Path 'Function:\Global:aws' -Value {
                $global:LASTEXITCODE = 0
                return '{}'
            }.GetNewClosure() -Force

            Invoke-CloudCommand -CommandName 'aws' -Arguments @('s3', 'ls', '--region', 'us-east-1')

            $global:WideEvents[-1].context.arguments | Should -Be 's3 ls --region us-east-1'
        }
    }

    Context 'Set-CloudProfile' {
        It 'Leaves the environment variable unset when profile setting fails' {
            Mark-TestCommandsUnavailable -CommandNames 'aws'
            Remove-Item Env:AWS_PROFILE -ErrorAction SilentlyContinue

            Set-CloudProfile -ProviderName 'aws' -ProfileType 'Profile' -Value 'staging' -EnvVarName 'AWS_PROFILE' -CommandName 'aws' |
                Should -Be $false

            $env:AWS_PROFILE | Should -BeNullOrEmpty
        }
    }
}
