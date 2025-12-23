

Describe 'Bootstrap Function Scoping and Visibility' {
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

    Context 'Function scoping and visibility' {
        It 'Set-AgentModeFunction creates global functions' {
            $funcName = "TestGlobal_$(Get-Random)"
            $cleanupNeeded = $false

            try {
                $result = Set-AgentModeFunction -Name $funcName -Body { 'global' }
                $result | Should -Be $true -Because "Set-AgentModeFunction should return true for new function"
                $cleanupNeeded = $true

                Get-Command $funcName -ErrorAction Stop | Should -Not -Be $null -Because "function should be available globally after creation"
            }
            catch {
                $errorDetails = @{
                    Message      = $_.Exception.Message
                    FunctionName = $funcName
                    Category     = $_.CategoryInfo.Category
                }
                Write-Error "Set-AgentModeFunction global scope test failed: $($errorDetails | ConvertTo-Json -Compress)" -ErrorAction Continue
                throw
            }
            finally {
                if ($cleanupNeeded) {
                    Remove-Item -Path "Function:\$funcName" -Force -ErrorAction SilentlyContinue
                    Remove-Item -Path "Function:\global:$funcName" -Force -ErrorAction SilentlyContinue
                }
            }
        }

        It 'Set-AgentModeAlias creates global aliases' {
            $aliasName = "TestGlobalAlias_$(Get-Random)"
            $cleanupNeeded = $false

            try {
                $result = Set-AgentModeAlias -Name $aliasName -Target 'Write-Output'
                $result | Should -Be $true -Because "Set-AgentModeAlias should return true for new alias"
                $cleanupNeeded = $true

                Get-Alias $aliasName -ErrorAction Stop | Should -Not -Be $null -Because "alias should be available globally after creation"
            }
            catch {
                $errorDetails = @{
                    Message   = $_.Exception.Message
                    AliasName = $aliasName
                    Category  = $_.CategoryInfo.Category
                }
                Write-Error "Set-AgentModeAlias global scope test failed: $($errorDetails | ConvertTo-Json -Compress)" -ErrorAction Continue
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

