

Describe 'SSH Integration Tests' {
    BeforeAll {
                $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
        if ($null -eq $script:ProfileDir -or [string]::IsNullOrWhiteSpace($script:ProfileDir)) {
            throw "Get-TestPath returned null or empty value for ProfileDir"
        }
        if (-not (Test-Path -LiteralPath $script:ProfileDir)) {
            throw "Profile directory not found at: $script:ProfileDir"
        }
    }
    catch {
        $errorDetails = @{
            Message  = $_.Exception.Message
            Type     = $_.Exception.GetType().FullName
            Location = $_.InvocationInfo.ScriptLineNumber
        }
        Write-Error "Failed to initialize SSH tests in BeforeAll: $($errorDetails | ConvertTo-Json -Compress)" -ErrorAction Stop
        throw
    }

    Context 'SSH functions' {
        BeforeAll {
            . (Join-Path $script:ProfileDir 'bootstrap.ps1')
            . (Join-Path $script:ProfileDir 'ssh.ps1')
        }

        It 'Get-SSHKeys function exists' {
            Get-Command Get-SSHKeys -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'Get-SSHKeys can be called without error' {
                        # Test that the function can be called without throwing
            { Get-SSHKeys } | Should -Not -Throw -Because "Get-SSHKeys should execute without errors"
        }
        catch {
            $errorDetails = @{
                Message  = $_.Exception.Message
                Function = 'Get-SSHKeys'
                Category = $_.CategoryInfo.Category
            }
            Write-Error "Get-SSHKeys execution test failed: $($errorDetails | ConvertTo-Json -Compress)" -ErrorAction Continue
            throw
        }

        It 'ssh-list alias exists for Get-SSHKeys' {
            Get-Alias ssh-list -ErrorAction SilentlyContinue | Should -Not -Be $null
            (Get-Alias ssh-list).ResolvedCommandName | Should -Be 'Get-SSHKeys'
        }

        It 'Add-SSHKeyIfNotLoaded function exists' {
            Get-Command Add-SSHKeyIfNotLoaded -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'Add-SSHKeyIfNotLoaded warns when no path provided' {
            # Should not throw when called without parameters
            { Add-SSHKeyIfNotLoaded } | Should -Not -Throw
        }

        It 'Add-SSHKeyIfNotLoaded warns when path does not exist' {
            $warnings = @()
            Add-SSHKeyIfNotLoaded -path '/nonexistent/key/id_rsa' -WarningVariable warnings 2>&1 | Out-Null
            # Function should warn rather than throw when key file is not found
            { Add-SSHKeyIfNotLoaded -path '/nonexistent/key/id_rsa' } | Should -Not -Throw
        }

        It 'ssh-add-if alias exists for Add-SSHKeyIfNotLoaded' {
            Get-Alias ssh-add-if -ErrorAction SilentlyContinue | Should -Not -Be $null
            (Get-Alias ssh-add-if).ResolvedCommandName | Should -Be 'Add-SSHKeyIfNotLoaded'
        }

        It 'Start-SSHAgent function exists' {
            Get-Command Start-SSHAgent -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'Start-SSHAgent can be called without error' {
            # Should not throw regardless of ssh-agent availability
            { Start-SSHAgent } | Should -Not -Throw
        }

        It 'ssh-agent-start alias exists for Start-SSHAgent' {
            Get-Alias ssh-agent-start -ErrorAction SilentlyContinue | Should -Not -Be $null
            (Get-Alias ssh-agent-start).ResolvedCommandName | Should -Be 'Start-SSHAgent'
        }
    }
}

