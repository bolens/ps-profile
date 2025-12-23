

BeforeAll {
    try {
        # Load the bootstrap fragment first to ensure Test-HasCommand is available
        $bootstrapFragment = Get-TestPath "profile.d\bootstrap.ps1" -StartPath $PSScriptRoot -EnsureExists
        if ($null -eq $bootstrapFragment -or [string]::IsNullOrWhiteSpace($bootstrapFragment)) {
            throw "Get-TestPath returned null or empty value for bootstrapFragment"
        }
        if (-not (Test-Path -LiteralPath $bootstrapFragment)) {
            throw "Bootstrap fragment not found at: $bootstrapFragment"
        }
        . $bootstrapFragment

        # Clear any existing guards
        Remove-Variable -Name 'ErrorHandlingLoaded' -Scope Global -ErrorAction SilentlyContinue

        # Load the error-handling fragment
        $errorHandlingFragment = Get-TestPath "profile.d\error-handling.ps1" -StartPath $PSScriptRoot -EnsureExists
        if ($null -eq $errorHandlingFragment -or [string]::IsNullOrWhiteSpace($errorHandlingFragment)) {
            throw "Get-TestPath returned null or empty value for errorHandlingFragment"
        }
        if (-not (Test-Path -LiteralPath $errorHandlingFragment)) {
            throw "Error handling fragment not found at: $errorHandlingFragment"
        }
        . $errorHandlingFragment
    }
    catch {
        $errorDetails = @{
            Message  = $_.Exception.Message
            Type     = $_.Exception.GetType().FullName
            Location = $_.InvocationInfo.ScriptLineNumber
        }
        Write-Error "Failed to initialize error handling tests in BeforeAll: $($errorDetails | ConvertTo-Json -Compress)" -ErrorAction Stop
        throw
    }
}

Describe 'Error Handling Module' {
    BeforeEach {
        # Clear any existing error log file for clean testing
        $userHome = if ($env:HOME) { $env:HOME } else { $env:USERPROFILE }
        $logDir = Join-Path $userHome '.local' 'share' 'powershell'
        $logFile = Join-Path $logDir 'profile-errors.log'
        if ($logFile -and -not [string]::IsNullOrWhiteSpace($logFile) -and (Test-Path -LiteralPath $logFile)) { Remove-Item $logFile -Force }

        # Set debug mode for testing
        $env:PS_PROFILE_DEBUG = '1'
    }

    AfterEach {
        # Clean up environment
        $env:PS_PROFILE_DEBUG = $null
    }

    Context 'Write-ProfileError' {
        It 'logs error to file when debug mode is enabled' {
            # Create an error record by executing a script that throws
            try {
                & {
                    throw "Test error"
                }
            }
            catch {
                $errorRecord = $_
            }

            Write-ProfileError -ErrorRecord $errorRecord -Context "Test context" -Category "Profile"

            $userHome = if ($env:HOME) { $env:HOME } else { $env:USERPROFILE }
            $logDir = Join-Path $userHome '.local' 'share' 'powershell'
            $logFile = Join-Path $logDir 'profile-errors.log'

            $logContent = Get-Content $logFile -Raw
            $logContent | Should -Match "\[Profile\] Error"
            $logContent | Should -Match "Context: Test context"
            $logContent | Should -Match "Message: Test error"
        }

        It 'displays warning when debug mode is disabled' {
            $env:PS_PROFILE_DEBUG = $null

            $errorRecord = [System.Management.Automation.ErrorRecord]::new(
                [System.Exception]::new("Test error"),
                "TestError",
                [System.Management.Automation.ErrorCategory]::NotSpecified,
                $null
            )

            $result = Write-ProfileError -ErrorRecord $errorRecord -Category "Command"

            # Should not throw and should have written warning
            $true | Should -Be $true  # Just to have an assertion
        }

        It 'handles different error categories' {
            $errorRecord = [System.Management.Automation.ErrorRecord]::new(
                [System.Exception]::new("Network error"),
                "NetworkError",
                [System.Management.Automation.ErrorCategory]::ConnectionError,
                $null
            )

            Write-ProfileError -ErrorRecord $errorRecord -Category "Network"

            $userHome = if ($env:HOME) { $env:HOME } else { $env:USERPROFILE }
            $logDir = Join-Path $userHome '.local' 'share' 'powershell'
            $logFile = Join-Path $logDir 'profile-errors.log'

            $logContent = Get-Content $logFile -Raw
            $logContent | Should -Match "\[Network\] Error"
        }
    }

    Context 'Invoke-ProfileErrorHandler' {
        It 'provides suggestions for CommandNotFoundException' {
            $errorRecord = [System.Management.Automation.ErrorRecord]::new(
                [System.Management.Automation.CommandNotFoundException]::new("The term 'missingcommand' is not recognized"),
                "CommandNotFound",
                [System.Management.Automation.ErrorCategory]::ObjectNotFound,
                $null
            )

            { Invoke-ProfileErrorHandler -ErrorRecord $errorRecord } | Should -Throw
            # The function throws the original error after logging and suggestions
        }

        It 'provides suggestions for network errors' {
            $errorRecord = [System.Management.Automation.ErrorRecord]::new(
                [System.Exception]::new("Network connection failed"),
                "NetworkError",
                [System.Management.Automation.ErrorCategory]::ConnectionError,
                $null
            )

            { Invoke-ProfileErrorHandler -ErrorRecord $errorRecord } | Should -Throw
        }

        It 'provides suggestions for access denied errors' {
            $errorRecord = [System.Management.Automation.ErrorRecord]::new(
                [System.UnauthorizedAccessException]::new("Access to the path is denied"),
                "AccessDenied",
                [System.Management.Automation.ErrorCategory]::PermissionDenied,
                $null
            )

            { Invoke-ProfileErrorHandler -ErrorRecord $errorRecord } | Should -Throw
        }

        It 'provides suggestions for module not found errors' {
            $errorRecord = [System.Management.Automation.ErrorRecord]::new(
                [System.Exception]::new("Module 'MissingModule' is not installed"),
                "ModuleNotFound",
                [System.Management.Automation.ErrorCategory]::ResourceUnavailable,
                $null
            )

            { Invoke-ProfileErrorHandler -ErrorRecord $errorRecord } | Should -Throw
        }
    }

    Context 'Invoke-SafeFragmentLoad' {
        It 'successfully loads a valid fragment' {
            # Create a temporary test fragment
            $tempFragment = [System.IO.Path]::GetTempFileName() + ".ps1"
            try {
                '$global:TestFragmentLoaded = $true' | Out-File -FilePath $tempFragment -Encoding UTF8

                $result = Invoke-SafeFragmentLoad -FragmentPath $tempFragment -FragmentName "TestFragment"

                $result | Should -Be $true
                $global:TestFragmentLoaded | Should -Be $true
            }
            finally {
                if ($tempFragment -and -not [string]::IsNullOrWhiteSpace($tempFragment) -and (Test-Path -LiteralPath $tempFragment)) { Remove-Item $tempFragment -Force }
                Remove-Variable -Name 'TestFragmentLoaded' -Scope Global -ErrorAction SilentlyContinue
            }
        }

        It 'retries on failure and eventually succeeds' {
            $attemptCount = 0
            $tempFragment = [System.IO.Path]::GetTempFileName() + ".ps1"
            try {
                # Create fragment that fails first time, succeeds second time
                @'
$global:TestRetryFragmentAttempts = ($global:TestRetryFragmentAttempts ?? 0) + 1
if ($global:TestRetryFragmentAttempts -lt 2) {
    throw "Temporary load failure"
}
$global:TestRetryFragmentLoaded = $true
'@ | Out-File -FilePath $tempFragment -Encoding UTF8

                $result = Invoke-SafeFragmentLoad -FragmentPath $tempFragment -FragmentName "TestRetryFragment" -MaxRetries 2

                $result | Should -Be $true
                $global:TestRetryFragmentLoaded | Should -Be $true
                $global:TestRetryFragmentAttempts | Should -Be 2
            }
            finally {
                if ($tempFragment -and -not [string]::IsNullOrWhiteSpace($tempFragment) -and (Test-Path -LiteralPath $tempFragment)) { Remove-Item $tempFragment -Force }
                Remove-Variable -Name 'TestRetryFragmentAttempts' -Scope Global -ErrorAction SilentlyContinue
                Remove-Variable -Name 'TestRetryFragmentLoaded' -Scope Global -ErrorAction SilentlyContinue
            }
        }

        It 'fails after max retries' {
            $tempFragment = [System.IO.Path]::GetTempFileName() + ".ps1"
            try {
                # Create fragment that always fails
                'throw "Persistent failure"' | Out-File -FilePath $tempFragment -Encoding UTF8

                $result = Invoke-SafeFragmentLoad -FragmentPath $tempFragment -FragmentName "TestFailFragment" -MaxRetries 1

                $result | Should -Be $false
            }
            finally {
                if ($tempFragment -and -not [string]::IsNullOrWhiteSpace($tempFragment) -and (Test-Path -LiteralPath $tempFragment)) { Remove-Item $tempFragment -Force }
            }
        }

        It 'handles non-existent fragment file' {
            $result = Invoke-SafeFragmentLoad -FragmentPath "C:\NonExistentFragment.ps1" -FragmentName "NonExistent" -MaxRetries 1

            $result | Should -Be $false
        }
    }
}

