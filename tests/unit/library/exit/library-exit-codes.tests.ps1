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
    $script:TestTempRoot = New-TestTempDirectory -Prefix 'ExitCodesTests'
}

AfterAll {
    Remove-Module ExitCodes -ErrorAction SilentlyContinue -Force

    if ($script:TestTempRoot -and (Test-Path -LiteralPath $script:TestTempRoot)) {
        Remove-Item -LiteralPath $script:TestTempRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Describe 'ExitCodes Module Functions' {

    Context 'Exit Code Constants' {
        It 'Defines EXIT_SUCCESS constant' {
            Get-Variable EXIT_SUCCESS -ErrorAction Stop | Should -Not -BeNullOrEmpty -Because 'EXIT_SUCCESS constant should be defined'
            $EXIT_SUCCESS | Should -Be 0 -Because 'EXIT_SUCCESS should equal 0'
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

        It 'Defines EXIT_RUNTIME_ERROR alias matching EXIT_OTHER_ERROR' {
            Get-Variable EXIT_RUNTIME_ERROR -ErrorAction Stop | Should -Not -BeNullOrEmpty
            $EXIT_RUNTIME_ERROR | Should -Be 3
            $EXIT_RUNTIME_ERROR | Should -Be $EXIT_OTHER_ERROR
        }

        It 'Exports all exit code constants' {
            $module = Get-Module ExitCodes
            # ExportedVariables is a Dictionary, check Keys property
            $module.ExportedVariables.Keys | Should -Contain 'EXIT_SUCCESS'
            $module.ExportedVariables.Keys | Should -Contain 'EXIT_VALIDATION_FAILURE'
            $module.ExportedVariables.Keys | Should -Contain 'EXIT_SETUP_ERROR'
            $module.ExportedVariables.Keys | Should -Contain 'EXIT_OTHER_ERROR'
            $module.ExportedVariables.Keys | Should -Contain 'EXIT_RUNTIME_ERROR'
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
            $testScript = Join-Path $script:TestTempRoot "test-exit-message-$(Get-Random).ps1"
            $scriptContent = @"
Remove-Item Env:PS_PROFILE_TEST_MODE -ErrorAction SilentlyContinue
Import-Module '$($script:ExitCodesPath)' -DisableNameChecking -Force
Exit-WithCode -ExitCode `$EXIT_VALIDATION_FAILURE -Message 'Test message'
"@
            Set-Content -Path $testScript -Value $scriptContent
            
            # Use direct invocation which is faster than Start-Process
            $output = & pwsh -NoProfile -File $testScript 2>&1
            $output | Should -Match 'Test message'
        }

        It 'Handles ErrorRecord parameter' {
            $testScript = Join-Path $script:TestTempRoot "test-exit-error-$(Get-Random).ps1"
            $scriptContent = @"
Remove-Item Env:PS_PROFILE_TEST_MODE -ErrorAction SilentlyContinue
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
            $testScript = Join-Path $script:TestTempRoot "test-exit-success-$(Get-Random).ps1"
            $scriptContent = @"
Remove-Item Env:PS_PROFILE_TEST_MODE -ErrorAction SilentlyContinue
Import-Module '$($script:ExitCodesPath)' -DisableNameChecking -Force
Exit-WithCode -ExitCode `$EXIT_SUCCESS
"@
            Set-Content -Path $testScript -Value $scriptContent
            
            & pwsh -NoProfile -File $testScript 2>&1 | Out-Null
            $LASTEXITCODE | Should -Be 0
        }

        It 'Exits with EXIT_VALIDATION_FAILURE' {
            $testScript = Join-Path $script:TestTempRoot "test-exit-validation-$(Get-Random).ps1"
            $scriptContent = @"
Remove-Item Env:PS_PROFILE_TEST_MODE -ErrorAction SilentlyContinue
Import-Module '$($script:ExitCodesPath)' -DisableNameChecking -Force
Exit-WithCode -ExitCode `$EXIT_VALIDATION_FAILURE
"@
            Set-Content -Path $testScript -Value $scriptContent
            
            & pwsh -NoProfile -File $testScript 2>&1 | Out-Null
            $LASTEXITCODE | Should -Be 1
        }

        It 'Exits with EXIT_SETUP_ERROR' {
            $testScript = Join-Path $script:TestTempRoot "test-exit-setup-$(Get-Random).ps1"
            $scriptContent = @"
Remove-Item Env:PS_PROFILE_TEST_MODE -ErrorAction SilentlyContinue
Import-Module '$($script:ExitCodesPath)' -DisableNameChecking -Force
Exit-WithCode -ExitCode `$EXIT_SETUP_ERROR
"@
            Set-Content -Path $testScript -Value $scriptContent
            
            & pwsh -NoProfile -File $testScript 2>&1 | Out-Null
            $LASTEXITCODE | Should -Be 2
        }

        It 'Exits with EXIT_OTHER_ERROR' {
            $testScript = Join-Path $script:TestTempRoot "test-exit-other-$(Get-Random).ps1"
            $scriptContent = @"
Remove-Item Env:PS_PROFILE_TEST_MODE -ErrorAction SilentlyContinue
Import-Module '$($script:ExitCodesPath)' -DisableNameChecking -Force
Exit-WithCode -ExitCode `$EXIT_OTHER_ERROR
"@
            Set-Content -Path $testScript -Value $scriptContent
            
            & pwsh -NoProfile -File $testScript 2>&1 | Out-Null
            $LASTEXITCODE | Should -Be 3
        }

        It 'Exits with custom exit code' {
            $testScript = Join-Path $script:TestTempRoot "test-exit-custom-$(Get-Random).ps1"
            $scriptContent = @"
Remove-Item Env:PS_PROFILE_TEST_MODE -ErrorAction SilentlyContinue
Import-Module '$($script:ExitCodesPath)' -DisableNameChecking -Force
Exit-WithCode -ExitCode 42
"@
            Set-Content -Path $testScript -Value $scriptContent
            
            & pwsh -NoProfile -File $testScript 2>&1 | Out-Null
            $LASTEXITCODE | Should -Be 42
        }

        It 'Handles empty message' {
            $testScript = Join-Path $script:TestTempRoot "test-exit-empty-$(Get-Random).ps1"
            $scriptContent = @"
Remove-Item Env:PS_PROFILE_TEST_MODE -ErrorAction SilentlyContinue
Import-Module '$($script:ExitCodesPath)' -DisableNameChecking -Force
Exit-WithCode -ExitCode `$EXIT_SUCCESS -Message ''
"@
            Set-Content -Path $testScript -Value $scriptContent
            
            & pwsh -NoProfile -File $testScript 2>&1 | Out-Null
            $LASTEXITCODE | Should -Be 0
        }

        It 'Accepts ExitCode enum value' {
            $testScript = Join-Path $script:TestTempRoot "test-exit-enum-$(Get-Random).ps1"
            $scriptContent = @"
Remove-Item Env:PS_PROFILE_TEST_MODE -ErrorAction SilentlyContinue
Import-Module '$($script:ExitCodesPath)' -DisableNameChecking -Force
Exit-WithCode -ExitCode 1
"@
            Set-Content -Path $testScript -Value $scriptContent
            
            & pwsh -NoProfile -File $testScript 2>&1 | Out-Null
            $LASTEXITCODE | Should -Be 1
        }

        It 'Accepts ExitCode enum for all values' {
            $testCases = @(
                @{ ExitArgument = '0'; ExpectedCode = 0 }
                @{ ExitArgument = '1'; ExpectedCode = 1 }
                @{ ExitArgument = '2'; ExpectedCode = 2 }
                @{ ExitArgument = '3'; ExpectedCode = 3 }
                @{ ExitArgument = '4'; ExpectedCode = 4 }
                @{ ExitArgument = '5'; ExpectedCode = 5 }
                @{ ExitArgument = '6'; ExpectedCode = 6 }
                @{ ExitArgument = '7'; ExpectedCode = 7 }
                @{ ExitArgument = '8'; ExpectedCode = 8 }
            )

            foreach ($testCase in $testCases) {
                $testScript = Join-Path $script:TestTempRoot "test-exit-enum-$($testCase.ExpectedCode)-$(Get-Random).ps1"
                $scriptContent = @"
Remove-Item Env:PS_PROFILE_TEST_MODE -ErrorAction SilentlyContinue
Import-Module '$($script:ExitCodesPath)' -DisableNameChecking -Force
Exit-WithCode -ExitCode $($testCase.ExitArgument)
"@
                Set-Content -Path $testScript -Value $scriptContent
                
                & pwsh -NoProfile -File $testScript 2>&1 | Out-Null
                $LASTEXITCODE | Should -Be $testCase.ExpectedCode -Because "Exit code $($testCase.ExitArgument) should exit with code $($testCase.ExpectedCode)"
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

