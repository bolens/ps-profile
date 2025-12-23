

Describe 'Bootstrap Idempotency Tests' {
    BeforeAll {
        try {
            $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
            $script:BootstrapPath = Get-TestPath -RelativePath 'profile.d\bootstrap.ps1' -StartPath $PSScriptRoot -EnsureExists
            if ($null -eq $script:BootstrapPath -or [string]::IsNullOrWhiteSpace($script:BootstrapPath)) {
                throw "Get-TestPath returned null or empty value for BootstrapPath"
            }
            if (-not (Test-Path -LiteralPath $script:BootstrapPath)) {
                throw "Bootstrap file not found at: $script:BootstrapPath"
            }
            . $script:BootstrapPath
        }
        catch {
            $errorDetails = @{
                Message  = $_.Exception.Message
                Type     = $_.Exception.GetType().FullName
                Location = $_.InvocationInfo.ScriptLineNumber
            }
            Write-Error "Failed to load bootstrap in BeforeAll: $($errorDetails | ConvertTo-Json -Compress)" -ErrorAction Stop
            throw
        }
    }

    Context 'Idempotency tests' {
        It 'Set-AgentModeFunction is idempotent' {
            $funcName = "TestIdempotent_$(Get-Random)"
            $cleanupNeeded = $false

            try {
                . $script:BootstrapPath

                $result1 = Set-AgentModeFunction -Name $funcName -Body { 'test' }
                $result1 | Should -Be $true -Because "first call should succeed"
                $cleanupNeeded = $true

                $result2 = Set-AgentModeFunction -Name $funcName -Body { 'test2' }
                $result2 | Should -Be $false -Because "second call should return false when function exists"

                $funcResult = & $funcName
                $funcResult | Should -Be 'test' -Because "function body should not change on second call"
            }
            catch {
                $errorDetails = @{
                    Message      = $_.Exception.Message
                    FunctionName = $funcName
                    Category     = $_.CategoryInfo.Category
                }
                Write-Error "Set-AgentModeFunction idempotency test failed: $($errorDetails | ConvertTo-Json -Compress)" -ErrorAction Continue
                throw
            }
            finally {
                if ($cleanupNeeded) {
                    Remove-Item -Path "Function:\$funcName" -Force -ErrorAction SilentlyContinue
                    Remove-Item -Path "Function:\global:$funcName" -Force -ErrorAction SilentlyContinue
                }
            }
        }

        It 'Set-AgentModeAlias is idempotent' {
            $aliasName = "TestAliasIdempotent_$(Get-Random)"
            $cleanupNeeded = $false

            try {
                . $script:BootstrapPath

                $result1 = Set-AgentModeAlias -Name $aliasName -Target 'Write-Output'
                $result1 | Should -Be $true -Because "first call should succeed"
                $cleanupNeeded = $true

                $result2 = Set-AgentModeAlias -Name $aliasName -Target 'Write-Host'
                $result2 | Should -Be $false -Because "second call should return false when alias exists"

                $aliasResult = Get-Alias -Name $aliasName -ErrorAction SilentlyContinue
                if ($aliasResult) {
                    $aliasResult.Definition | Should -Match 'Write-Output' -Because "alias target should not change on second call"
                }
            }
            catch {
                $errorDetails = @{
                    Message   = $_.Exception.Message
                    AliasName = $aliasName
                    Category  = $_.CategoryInfo.Category
                }
                Write-Error "Set-AgentModeAlias idempotency test failed: $($errorDetails | ConvertTo-Json -Compress)" -ErrorAction Continue
                throw
            }
            finally {
                if ($cleanupNeeded) {
                    Remove-Alias -Name $aliasName -Scope Global -Force -ErrorAction SilentlyContinue
                }
            }
        }
    }
}

