<#
.SYNOPSIS
    Unit tests for ErrorHandling module.

.DESCRIPTION
    Tests for Get-ErrorActionPreference, Invoke-WithErrorHandling, and Write-ErrorOrThrow functions.
#>

BeforeAll {
    $modulePath = Join-Path $PSScriptRoot '..' '..' 'scripts' 'lib' 'core' 'ErrorHandling.psm1'
    Import-Module $modulePath -Force -DisableNameChecking
}

AfterAll {
    Remove-Module ErrorHandling -Force -ErrorAction SilentlyContinue
}

Describe 'Get-ErrorActionPreference' {
    It 'Returns ErrorAction from PSBoundParameters when present' {
        $params = @{ ErrorAction = 'Continue' }
        $result = Get-ErrorActionPreference -PSBoundParameters $params
        $result | Should -Be 'Continue'
    }

    It 'Returns default value when ErrorAction not in PSBoundParameters' {
        $params = @{ Path = 'test' }
        $result = Get-ErrorActionPreference -PSBoundParameters $params
        $result | Should -Be 'Stop'
    }

    It 'Returns custom default when specified' {
        $params = @{ Path = 'test' }
        $result = Get-ErrorActionPreference -PSBoundParameters $params -Default 'SilentlyContinue'
        $result | Should -Be 'SilentlyContinue'
    }

    It 'Handles empty PSBoundParameters' {
        $params = @{}
        $result = Get-ErrorActionPreference -PSBoundParameters $params
        $result | Should -Be 'Stop'
    }

    It 'Handles all ErrorAction values' {
        $actions = @('Stop', 'Continue', 'SilentlyContinue', 'Ignore', 'Suspend', 'Inquire')
        foreach ($action in $actions) {
            $params = @{ ErrorAction = $action }
            $result = Get-ErrorActionPreference -PSBoundParameters $params
            $result | Should -Be $action
        }
    }
}

Describe 'Invoke-WithErrorHandling' {
    It 'Returns result when scriptblock succeeds' {
        $result = Invoke-WithErrorHandling -ScriptBlock { return 'success' } -ErrorActionPreference 'Stop'
        $result | Should -Be 'success'
    }

    It 'Throws when ErrorActionPreference is Stop and scriptblock fails' {
        { Invoke-WithErrorHandling -ScriptBlock { throw 'Test error' } -ErrorActionPreference 'Stop' } | Should -Throw
    }

    It 'Returns null when ErrorActionPreference is SilentlyContinue and scriptblock fails' {
        $result = Invoke-WithErrorHandling -ScriptBlock { throw 'Test error' } -ErrorActionPreference 'SilentlyContinue'
        $result | Should -BeNullOrEmpty
    }

    It 'Writes error when ErrorActionPreference is Continue and scriptblock fails' {
        $result = Invoke-WithErrorHandling -ScriptBlock { throw 'Test error' } -ErrorActionPreference 'Continue'
        $result | Should -BeNullOrEmpty
        # Error should be written (we can't easily test Write-Error output in Pester)
    }

    It 'Uses custom error message when provided' {
        $errorMessage = 'Custom error message'
        { Invoke-WithErrorHandling -ScriptBlock { throw 'Original error' } -ErrorActionPreference 'Stop' -ErrorMessage $errorMessage } | Should -Throw -ExpectedMessage $errorMessage
    }

    It 'Handles scriptblocks with parameters' {
        $scriptBlock = { param($value) return "Result: $value" }
        $result = Invoke-WithErrorHandling -ScriptBlock $scriptBlock -ErrorActionPreference 'Stop'
        # The scriptblock needs to be invoked with parameters, so we'll test it differently
        $testValue = 'test'
        $scriptBlockWithValue = { param($val) return "Result: $val" }
        $result = Invoke-WithErrorHandling -ScriptBlock { & $scriptBlockWithValue -val $testValue } -ErrorActionPreference 'Stop'
        $result | Should -Be 'Result: test'
    }

    It 'Handles scriptblocks that return null' {
        $result = Invoke-WithErrorHandling -ScriptBlock { return $null } -ErrorActionPreference 'Stop'
        $result | Should -BeNullOrEmpty
    }

    It 'Handles scriptblocks that return objects' {
        $obj = [PSCustomObject]@{ Name = 'Test'; Value = 123 }
        $result = Invoke-WithErrorHandling -ScriptBlock { return $obj } -ErrorActionPreference 'Stop'
        $result.Name | Should -Be 'Test'
        $result.Value | Should -Be 123
    }
}

Describe 'Write-ErrorOrThrow' {
    It 'Throws when ErrorActionPreference is Stop' {
        { Write-ErrorOrThrow -Message 'Test error' -ErrorActionPreference 'Stop' } | Should -Throw -ExpectedMessage 'Test error'
    }

    It 'Writes error when ErrorActionPreference is Continue' {
        { Write-ErrorOrThrow -Message 'Test error' -ErrorActionPreference 'Continue' } | Should -Not -Throw
        # Error should be written (we can't easily test Write-Error output in Pester)
    }

    It 'Writes error when ErrorActionPreference is SilentlyContinue' {
        { Write-ErrorOrThrow -Message 'Test error' -ErrorActionPreference 'SilentlyContinue' } | Should -Not -Throw
    }

    It 'Throws exception when Exception parameter provided and ErrorActionPreference is Stop' {
        $ex = [Exception]::new('Exception message')
        { Write-ErrorOrThrow -Message 'Test error' -Exception $ex -ErrorActionPreference 'Stop' } | Should -Throw
    }

    It 'Includes ErrorId when provided' {
        { Write-ErrorOrThrow -Message 'Test error' -ErrorId 'TestError' -ErrorActionPreference 'Stop' } | Should -Throw
    }

    It 'Uses custom error category when provided' {
        { Write-ErrorOrThrow -Message 'Test error' -Category 'InvalidArgument' -ErrorActionPreference 'Stop' } | Should -Throw
    }

    It 'Handles empty message' {
        { Write-ErrorOrThrow -Message '' -ErrorActionPreference 'Stop' } | Should -Throw
    }
}

