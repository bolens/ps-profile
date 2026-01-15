. (Join-Path $PSScriptRoot '..\TestSupport.ps1')

BeforeAll {
    try {
        $script:RepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
        $script:LibPath = Get-TestPath -RelativePath 'scripts\lib' -StartPath $PSScriptRoot -EnsureExists
        if ($null -eq $script:LibPath -or [string]::IsNullOrWhiteSpace($script:LibPath)) {
            throw "Get-TestPath returned null or empty value for LibPath"
        }
        if (-not (Test-Path -LiteralPath $script:LibPath)) {
            throw "Library path not found at: $script:LibPath"
        }
        
        $script:ExitCodesPath = Join-Path $script:LibPath 'core' 'ExitCodes.psm1'
        if ($null -eq $script:ExitCodesPath -or [string]::IsNullOrWhiteSpace($script:ExitCodesPath)) {
            throw "ExitCodesPath is null or empty"
        }
        if (-not (Test-Path -LiteralPath $script:ExitCodesPath)) {
            throw "ExitCodes module not found at: $script:ExitCodesPath"
        }
        
        # Import the module under test
        Import-Module $script:ExitCodesPath -DisableNameChecking -ErrorAction Stop -Force
    }
    catch {
        $errorDetails = @{
            Message  = $_.Exception.Message
            Type     = $_.Exception.GetType().FullName
            Location = $_.InvocationInfo.ScriptLineNumber
        }
        Write-Error "Failed to initialize ExitCodes tests in BeforeAll: $($errorDetails | ConvertTo-Json -Compress)" -ErrorAction Stop
        throw
    }
}

AfterAll {
    Remove-Module ExitCodes -ErrorAction SilentlyContinue -Force
}

Describe 'ExitCodes Module Functions' {

    Context 'Exit Code Constants' {
        It 'Defines EXIT_SUCCESS constant' {
            try {
                Get-Variable EXIT_SUCCESS -ErrorAction Stop | Should -Not -BeNullOrEmpty -Because "EXIT_SUCCESS constant should be defined"
                $EXIT_SUCCESS | Should -Be 0 -Because "EXIT_SUCCESS should equal 0"
            }
            catch {
                $errorDetails = @{
                    Message  = $_.Exception.Message
                    Constant = 'EXIT_SUCCESS'
                    Category = $_.CategoryInfo.Category
                }
                Write-Error "EXIT_SUCCESS constant test failed: $($errorDetails | ConvertTo-Json -Compress)" -ErrorAction Continue
                throw
            }
        }

        It 'Defines EXIT_VALIDATION_FAILURE constant' {
            Get-Variable EXIT_VALIDATION_FAILURE -ErrorAction Stop | Should -Not -BeNullOrEmpty
            $EXIT_VALIDATION_FAILURE | Should -Be 1
        }

        It 'Defines EXIT_SETUP_ERROR constant' {
            Get-Variable EXIT_SETUP_ERROR -ErrorAction Stop | Should -Not -BeNullOrEmpty
            $EXIT_SETUP_ERROR | Should -Be 2
        }

        It 'Defines EXIT_OTHER_ERROR constant' {
            Get-Variable EXIT_OTHER_ERROR -ErrorAction Stop | Should -Not -BeNullOrEmpty
            $EXIT_OTHER_ERROR | Should -Be 3
        }

        It 'Exports all exit code constants' {
            $module = Get-Module ExitCodes
            # ExportedVariables is a Dictionary, check Keys property
            $module.ExportedVariables.Keys | Should -Contain 'EXIT_SUCCESS'
            $module.ExportedVariables.Keys | Should -Contain 'EXIT_VALIDATION_FAILURE'
            $module.ExportedVariables.Keys | Should -Contain 'EXIT_SETUP_ERROR'
            $module.ExportedVariables.Keys | Should -Contain 'EXIT_OTHER_ERROR'
        }
    }

    Context 'Exit-WithCode Function' {
        It 'Function exists and has correct signature' {
            $module = Get-Module ExitCodes
            $module.ExportedFunctions.Keys | Should -Contain 'Exit-WithCode'
            
            $function = Get-Command Exit-WithCode
            $function | Should -Not -BeNullOrEmpty
            $function.Parameters.Keys | Should -Contain 'ExitCode'
            $function.Parameters.Keys | Should -Contain 'Message'
            $function.Parameters.Keys | Should -Contain 'ErrorRecord'
        }

        It 'Outputs message when provided' {
            # Test message output by capturing it before exit
            # Use a job to test without terminating the test process
            $testScript = Join-Path $TestDrive "test-exit-message-$(Get-Random).ps1"
            $scriptContent = @"
Import-Module '$($script:ExitCodesPath)' -DisableNameChecking -Force
Exit-WithCode -ExitCode `$EXIT_VALIDATION_FAILURE -Message 'Test message'
"@
            Set-Content -Path $testScript -Value $scriptContent
            
            # Use direct invocation which is faster than Start-Process
            $output = & pwsh -NoProfile -File $testScript 2>&1
            $output | Should -Match 'Test message'
        }

        It 'Handles ErrorRecord parameter' {
            $testScript = Join-Path $TestDrive "test-exit-error-$(Get-Random).ps1"
            $scriptContent = @"
Import-Module '$($script:ExitCodesPath)' -DisableNameChecking -Force
try {
    throw 'Test error'
}
catch {
    Exit-WithCode -ExitCode `$EXIT_SETUP_ERROR -ErrorRecord `$_
}
"@
            Set-Content -Path $testScript -Value $scriptContent
            
            # Use direct invocation with exit code check
            $exitCode = 0
            & pwsh -NoProfile -File $testScript 2>&1 | Out-Null
            $exitCode = $LASTEXITCODE
            $exitCode | Should -Be 2
        }

        It 'Exits with EXIT_SUCCESS' {
            $testScript = Join-Path $TestDrive "test-exit-success-$(Get-Random).ps1"
            $scriptContent = @"
Import-Module '$($script:ExitCodesPath)' -DisableNameChecking -Force
Exit-WithCode -ExitCode `$EXIT_SUCCESS
"@
            Set-Content -Path $testScript -Value $scriptContent
            
            & pwsh -NoProfile -File $testScript 2>&1 | Out-Null
            $LASTEXITCODE | Should -Be 0
        }

        It 'Exits with EXIT_VALIDATION_FAILURE' {
            $testScript = Join-Path $TestDrive "test-exit-validation-$(Get-Random).ps1"
            $scriptContent = @"
Import-Module '$($script:ExitCodesPath)' -DisableNameChecking -Force
Exit-WithCode -ExitCode `$EXIT_VALIDATION_FAILURE
"@
            Set-Content -Path $testScript -Value $scriptContent
            
            & pwsh -NoProfile -File $testScript 2>&1 | Out-Null
            $LASTEXITCODE | Should -Be 1
        }

        It 'Exits with EXIT_SETUP_ERROR' {
            $testScript = Join-Path $TestDrive "test-exit-setup-$(Get-Random).ps1"
            $scriptContent = @"
Import-Module '$($script:ExitCodesPath)' -DisableNameChecking -Force
Exit-WithCode -ExitCode `$EXIT_SETUP_ERROR
"@
            Set-Content -Path $testScript -Value $scriptContent
            
            & pwsh -NoProfile -File $testScript 2>&1 | Out-Null
            $LASTEXITCODE | Should -Be 2
        }

        It 'Exits with EXIT_OTHER_ERROR' {
            $testScript = Join-Path $TestDrive "test-exit-other-$(Get-Random).ps1"
            $scriptContent = @"
Import-Module '$($script:ExitCodesPath)' -DisableNameChecking -Force
Exit-WithCode -ExitCode `$EXIT_OTHER_ERROR
"@
            Set-Content -Path $testScript -Value $scriptContent
            
            & pwsh -NoProfile -File $testScript 2>&1 | Out-Null
            $LASTEXITCODE | Should -Be 3
        }

        It 'Exits with custom exit code' {
            $testScript = Join-Path $TestDrive "test-exit-custom-$(Get-Random).ps1"
            $scriptContent = @"
Import-Module '$($script:ExitCodesPath)' -DisableNameChecking -Force
Exit-WithCode -ExitCode 42
"@
            Set-Content -Path $testScript -Value $scriptContent
            
            & pwsh -NoProfile -File $testScript 2>&1 | Out-Null
            $LASTEXITCODE | Should -Be 42
        }

        It 'Handles empty message' {
            $testScript = Join-Path $TestDrive "test-exit-empty-$(Get-Random).ps1"
            $scriptContent = @"
Import-Module '$($script:ExitCodesPath)' -DisableNameChecking -Force
Exit-WithCode -ExitCode `$EXIT_SUCCESS -Message ''
"@
            Set-Content -Path $testScript -Value $scriptContent
            
            & pwsh -NoProfile -File $testScript 2>&1 | Out-Null
            $LASTEXITCODE | Should -Be 0
        }

        It 'Accepts ExitCode enum value' {
            $testScript = Join-Path $TestDrive "test-exit-enum-$(Get-Random).ps1"
            $scriptContent = @"
Import-Module '$($script:ExitCodesPath)' -DisableNameChecking -Force
Exit-WithCode -ExitCode [ExitCode]::ValidationFailure
"@
            Set-Content -Path $testScript -Value $scriptContent
            
            & pwsh -NoProfile -File $testScript 2>&1 | Out-Null
            $LASTEXITCODE | Should -Be 1
        }

        It 'Accepts ExitCode enum for all values' {
            $testCases = @(
                @{ EnumValue = '[ExitCode]::Success'; ExpectedCode = 0 }
                @{ EnumValue = '[ExitCode]::ValidationFailure'; ExpectedCode = 1 }
                @{ EnumValue = '[ExitCode]::SetupError'; ExpectedCode = 2 }
                @{ EnumValue = '[ExitCode]::OtherError'; ExpectedCode = 3 }
                @{ EnumValue = '[ExitCode]::TestFailure'; ExpectedCode = 4 }
                @{ EnumValue = '[ExitCode]::TestTimeout'; ExpectedCode = 5 }
                @{ EnumValue = '[ExitCode]::CoverageFailure'; ExpectedCode = 6 }
                @{ EnumValue = '[ExitCode]::NoTestsFound'; ExpectedCode = 7 }
                @{ EnumValue = '[ExitCode]::WatchModeCanceled'; ExpectedCode = 8 }
            )

            foreach ($testCase in $testCases) {
                $testScript = Join-Path $TestDrive "test-exit-enum-$($testCase.ExpectedCode)-$(Get-Random).ps1"
                $scriptContent = @"
Import-Module '$($script:ExitCodesPath)' -DisableNameChecking -Force
Exit-WithCode -ExitCode $($testCase.EnumValue)
"@
                Set-Content -Path $testScript -Value $scriptContent
                
                & pwsh -NoProfile -File $testScript 2>&1 | Out-Null
                $LASTEXITCODE | Should -Be $testCase.ExpectedCode -Because "ExitCode enum $($testCase.EnumValue) should exit with code $($testCase.ExpectedCode)"
            }
        }
    }

    Context 'ExitCode Enum' {
        It 'ExitCode enum is available' {
            $exitCodeType = [ExitCode]
            $exitCodeType | Should -Not -BeNullOrEmpty
        }

        It 'ExitCode enum has all expected values' {
            $expectedValues = @('Success', 'ValidationFailure', 'SetupError', 'OtherError', 'TestFailure', 'TestTimeout', 'CoverageFailure', 'NoTestsFound', 'WatchModeCanceled')
            $enumValues = [Enum]::GetNames([ExitCode])
            
            foreach ($expected in $expectedValues) {
                $enumValues | Should -Contain $expected -Because "ExitCode enum should contain $expected"
            }
        }

        It 'ExitCode enum values match constant values' {
            [int][ExitCode]::Success | Should -Be $EXIT_SUCCESS
            [int][ExitCode]::ValidationFailure | Should -Be $EXIT_VALIDATION_FAILURE
            [int][ExitCode]::SetupError | Should -Be $EXIT_SETUP_ERROR
            [int][ExitCode]::OtherError | Should -Be $EXIT_OTHER_ERROR
        }
    }
}

