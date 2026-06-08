# ===============================================
# library-cloud-provider-base.tests.ps1
# Unit tests for CloudProviderBase.ps1
# ===============================================

BeforeAll {
    . (Join-Path $PSScriptRoot '..\TestSupport.ps1')
    $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
    . (Join-Path $script:ProfileDir 'bootstrap.ps1')

    $errorHandlingPath = Join-Path $script:ProfileDir 'bootstrap' 'ErrorHandlingStandard.ps1'
    if (Test-Path -LiteralPath $errorHandlingPath) {
        . $errorHandlingPath
    }

    # Keep wide events during tests (tail sampling otherwise drops most success events).
    # Install wrapper before CloudProviderBase so Invoke-CloudCommand resolves it at runtime.
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

$global:ResetCloudCommandExitCode = {
    $global:LASTEXITCODE = 0
}

Describe 'CloudProviderBase.ps1 - Invoke-CloudCommand' {
    BeforeEach {
        & $global:ClearCloudCommandMocks
        & $global:ResetCloudCommandExitCode

        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }

        if (Get-Variable -Name 'TestCachedCommandCache' -Scope Global -ErrorAction SilentlyContinue) {
            $null = $global:TestCachedCommandCache.TryRemove('aws', [ref]$null)
            $null = $global:TestCachedCommandCache.TryRemove('az', [ref]$null)
            $null = $global:TestCachedCommandCache.TryRemove('gcloud', [ref]$null)
        }

        if (Get-Command Clear-EventCollection -ErrorAction SilentlyContinue) {
            Clear-EventCollection | Out-Null
        }

        $global:TestCapturedArguments = $null
        $env:PS_PROFILE_SUPPRESS_EVENTS = '1'
    }

    AfterEach {
        & $global:ClearCloudCommandMocks
    }

    Context 'Command Detection' {
        It 'Returns null when command is not available' {
            Mark-TestCommandsUnavailable -CommandNames 'aws'

            $result = Invoke-CloudCommand -CommandName 'aws' -Arguments @('s3', 'ls')

            $result | Should -BeNullOrEmpty
        }

        It 'Shows warning when command is not available' {
            Mark-TestCommandsUnavailable -CommandNames 'aws'

            $null = Invoke-CloudCommand -CommandName 'aws' -Arguments @('s3', 'ls')

            $warningTools = @($global:CollectedMissingToolWarnings | ForEach-Object { $_.Tool })
            $warningTools | Should -Contain 'aws'
        }

        It 'Executes command when available' {
            Set-TestCommandAvailabilityState -CommandName 'aws'

            Set-Item -Path 'Function:\Global:aws' -Value {
                $global:LASTEXITCODE = 0
                if ($args.Count -ge 2 -and $args[0] -eq 's3' -and $args[1] -eq 'ls') {
                    return 'bucket1', 'bucket2'
                }
            }.GetNewClosure() -Force

            $result = Invoke-CloudCommand -CommandName 'aws' -Arguments @('s3', 'ls')

            $result | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Operation Name Generation' {
        It 'Generates operation name from command and first argument' {
            Set-TestCommandAvailabilityState -CommandName 'aws'

            Set-Item -Path 'Function:\Global:aws' -Value {
                $global:LASTEXITCODE = 0
                return '{}'
            }.GetNewClosure() -Force

            Invoke-CloudCommand -CommandName 'aws' -Arguments @('s3', 'ls')

            $global:WideEvents[-1].event_name | Should -Be 'aws.s3'
        }

        It 'Uses provided operation name' {
            Set-TestCommandAvailabilityState -CommandName 'aws'

            Set-Item -Path 'Function:\Global:aws' -Value {
                $global:LASTEXITCODE = 0
                return '{}'
            }.GetNewClosure() -Force

            Invoke-CloudCommand -CommandName 'aws' -Arguments @('s3', 'ls') -OperationName 'custom.operation'

            $global:WideEvents[-1].event_name | Should -Be 'custom.operation'
        }
    }

    Context 'JSON Parsing' {
        It 'Parses JSON output by default' {
            Set-TestCommandAvailabilityState -CommandName 'aws'

            Set-Item -Path 'Function:\Global:aws' -Value {
                $global:LASTEXITCODE = 0
                return '{"Buckets":[{"Name":"bucket1"}]}'
            }.GetNewClosure() -Force

            $result = Invoke-CloudCommand -CommandName 'aws' -Arguments @('s3api', 'list-buckets')

            $result | Should -BeOfType [PSCustomObject]
            $result.Buckets | Should -Not -BeNullOrEmpty
        }

        It 'Returns raw output when ParseJson is false' {
            Set-TestCommandAvailabilityState -CommandName 'aws'

            Set-Item -Path 'Function:\Global:aws' -Value {
                $global:LASTEXITCODE = 0
                return 'bucket1 bucket2'
            }.GetNewClosure() -Force

            $result = Invoke-CloudCommand -CommandName 'aws' -Arguments @('s3', 'ls') -ParseJson $false

            $result | Should -Be 'bucket1 bucket2'
        }

        It 'Handles invalid JSON gracefully' {
            Set-TestCommandAvailabilityState -CommandName 'aws'

            Set-Item -Path 'Function:\Global:aws' -Value {
                $global:LASTEXITCODE = 0
                return 'not json'
            }.GetNewClosure() -Force

            $result = Invoke-CloudCommand -CommandName 'aws' -Arguments @('s3', 'ls') -ParseJson $true

            $result | Should -Be 'not json'
        }
    }

    Context 'Error Handling' {
        It 'Throws error on non-zero exit code by default' {
            Set-TestCommandAvailabilityState -CommandName 'aws'

            Set-Item -Path 'Function:\Global:aws' -Value {
                $global:LASTEXITCODE = 1
                return 'Error: Access denied'
            }.GetNewClosure() -Force

            {
                Invoke-CloudCommand -CommandName 'aws' -Arguments @('s3', 'ls')
            } | Should -Throw
        }

        It 'Returns output when ErrorOnNonZeroExit is false' {
            Set-TestCommandAvailabilityState -CommandName 'aws'

            Set-Item -Path 'Function:\Global:aws' -Value {
                $global:LASTEXITCODE = 1
                return 'Error'
            }.GetNewClosure() -Force

            $result = Invoke-CloudCommand -CommandName 'aws' -Arguments @('s3', 'ls') -ErrorOnNonZeroExit $false

            $result | Should -Be 'Error'
        }
    }

    Context 'Context Tracking' {
        It 'Includes command and arguments in context' {
            Set-TestCommandAvailabilityState -CommandName 'aws'

            Set-Item -Path 'Function:\Global:aws' -Value {
                $global:LASTEXITCODE = 0
                return '{}'
            }.GetNewClosure() -Force

            Invoke-CloudCommand -CommandName 'aws' -Arguments @('s3', 'ls') -Context @{ custom = 'value' }

            $eventContext = $global:WideEvents[-1].context
            $eventContext.command | Should -Be 'aws'
            $eventContext.arguments | Should -Be 's3 ls'
            $eventContext.custom | Should -Be 'value'
        }
    }
}

Describe 'CloudProviderBase.ps1 - Set-CloudProfile' {
    BeforeEach {
        & $global:ClearCloudCommandMocks
        & $global:ResetCloudCommandExitCode
        $env:PS_PROFILE_SUPPRESS_EVENTS = '1'
        Remove-Item Env:AWS_PROFILE -ErrorAction SilentlyContinue

        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }
    }

    Context 'Profile Setting' {
        It 'Sets environment variable' {
            Set-TestCommandAvailabilityState -CommandName 'aws'

            $result = Set-CloudProfile -ProviderName 'aws' -ProfileType 'Profile' -Value 'production' -EnvVarName 'AWS_PROFILE' -CommandName 'aws' -DisplayName 'AWS profile'

            $result | Should -Be $true
            $env:AWS_PROFILE | Should -Be 'production'
        }

        It 'Returns false when command is not available' {
            Mark-TestCommandsUnavailable -CommandNames 'aws'

            $result = Set-CloudProfile -ProviderName 'aws' -ProfileType 'Profile' -Value 'production' -EnvVarName 'AWS_PROFILE' -CommandName 'aws'

            $result | Should -Be $false
        }

        It 'Validates setting when ValidateCommand provided' {
            Set-TestCommandAvailabilityState -CommandName 'aws'

            Set-Item -Path 'Function:\Global:aws' -Value {
                $global:LASTEXITCODE = 0
                if ($args.Count -ge 2 -and $args[0] -eq 'sts' -and $args[1] -eq 'get-caller-identity') {
                    return '{"Account":"123456789012"}'
                }
            }.GetNewClosure() -Force

            $result = Set-CloudProfile -ProviderName 'aws' -ProfileType 'Profile' -Value 'production' -EnvVarName 'AWS_PROFILE' -CommandName 'aws' -ValidateCommand 'sts get-caller-identity'

            $result | Should -Be $true
        }
    }
}

Describe 'CloudProviderBase.ps1 - Get-CloudResources' {
    BeforeEach {
        & $global:ClearCloudCommandMocks
        & $global:ResetCloudCommandExitCode
        $global:TestCapturedArguments = $null
        $env:PS_PROFILE_SUPPRESS_EVENTS = '1'

        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }

        if (Get-Command Clear-EventCollection -ErrorAction SilentlyContinue) {
            Clear-EventCollection | Out-Null
        }
    }

    Context 'Service/Action Pattern' {
        It 'Builds command arguments from service and action' {
            Set-TestCommandAvailabilityState -CommandName 'aws'

            Set-Item -Path 'Function:\Global:aws' -Value {
                $global:LASTEXITCODE = 0
                $global:TestCapturedArguments = $args
                return '{}'
            }.GetNewClosure() -Force

            Get-CloudResources -CommandName 'aws' -Service 'ec2' -Action 'describe-instances'

            $global:TestCapturedArguments[0] | Should -Be 'ec2'
            $global:TestCapturedArguments[1] | Should -Be 'describe-instances'
        }

        It 'Generates operation name from service and action' {
            Set-TestCommandAvailabilityState -CommandName 'aws'

            Set-Item -Path 'Function:\Global:aws' -Value {
                $global:LASTEXITCODE = 0
                return '{}'
            }.GetNewClosure() -Force

            Get-CloudResources -CommandName 'aws' -Service 'ec2' -Action 'describe-instances'

            $global:WideEvents[-1].event_name | Should -Be 'aws.ec2.describe-instances'
        }
    }

    Context 'Direct Arguments Pattern' {
        It 'Uses provided arguments directly' {
            Set-TestCommandAvailabilityState -CommandName 'az'

            Set-Item -Path 'Function:\Global:az' -Value {
                $global:LASTEXITCODE = 0
                $global:TestCapturedArguments = $args
                return '[]'
            }.GetNewClosure() -Force

            Get-CloudResources -CommandName 'az' -Arguments @('vm', 'list')

            $global:TestCapturedArguments[0] | Should -Be 'vm'
            $global:TestCapturedArguments[1] | Should -Be 'list'
        }
    }

    Context 'Error Handling' {
        It 'Returns null when neither Service/Action nor Arguments provided' {
            { Get-CloudResources -CommandName 'aws' } | Should -Throw '*Service/Action*'
        }
    }
}

Describe 'CloudProviderBase.ps1 - Test-CloudConnection' {
    BeforeEach {
        & $global:ClearCloudCommandMocks
        & $global:ResetCloudCommandExitCode
        $env:PS_PROFILE_SUPPRESS_EVENTS = '1'

        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }
    }

    Context 'Connection Testing' {
        It 'Tests connection successfully' {
            Set-TestCommandAvailabilityState -CommandName 'aws'

            Set-Item -Path 'Function:\Global:aws' -Value {
                $global:LASTEXITCODE = 0
                return '{"Account":"123456789012"}'
            }.GetNewClosure() -Force

            $result = Test-CloudConnection -CommandName 'aws' -TestCommand @('sts', 'get-caller-identity') -SuccessIndicator 'Account'

            $result | Should -Be $true
        }

        It 'Returns false when connection fails' {
            Set-TestCommandAvailabilityState -CommandName 'aws'

            Set-Item -Path 'Function:\Global:aws' -Value {
                $global:LASTEXITCODE = 1
                return ''
            }.GetNewClosure() -Force

            $result = Test-CloudConnection -CommandName 'aws' -TestCommand @('sts', 'get-caller-identity')

            $result | Should -Be $false
        }

        It 'Validates success indicator' {
            Set-TestCommandAvailabilityState -CommandName 'aws'

            Set-Item -Path 'Function:\Global:aws' -Value {
                $global:LASTEXITCODE = 0
                return '{"Account":"123456789012"}'
            }.GetNewClosure() -Force

            $result = Test-CloudConnection -CommandName 'aws' -TestCommand @('sts', 'get-caller-identity') -SuccessIndicator 'Account'

            $result | Should -Be $true
        }

        It 'Returns false when success indicator not found' {
            Set-TestCommandAvailabilityState -CommandName 'aws'

            Set-Item -Path 'Function:\Global:aws' -Value {
                $global:LASTEXITCODE = 0
                return '{"UserId":"test"}'
            }.GetNewClosure() -Force

            $result = Test-CloudConnection -CommandName 'aws' -TestCommand @('sts', 'get-caller-identity') -SuccessIndicator 'Account'

            $result | Should -Be $false
        }

        It 'Handles nested success indicators' {
            Set-TestCommandAvailabilityState -CommandName 'aws'

            Set-Item -Path 'Function:\Global:aws' -Value {
                $global:LASTEXITCODE = 0
                return '{"Response":{"Account":"123456789012"}}'
            }.GetNewClosure() -Force

            $result = Test-CloudConnection -CommandName 'aws' -TestCommand @('sts', 'get-caller-identity') -SuccessIndicator 'Response.Account'

            $result | Should -Be $true
        }
    }
}
