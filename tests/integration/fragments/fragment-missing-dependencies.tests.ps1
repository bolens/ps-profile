

Describe 'Fragment Missing Dependencies' {
    BeforeAll {
        try {
            $script:RepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
            $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
            $script:ProfilePath = Get-TestPath -RelativePath 'Microsoft.PowerShell_profile.ps1' -StartPath $PSScriptRoot -EnsureExists

            if ($null -eq $script:ProfilePath -or [string]::IsNullOrWhiteSpace($script:ProfilePath)) {
                throw "Get-TestPath returned null or empty value for ProfilePath"
            }
            if (-not (Test-Path -LiteralPath $script:ProfilePath)) {
                throw "Profile file not found at: $script:ProfilePath"
            }
        }
        catch {
            $errorDetails = @{
                Message  = $_.Exception.Message
                Type     = $_.Exception.GetType().FullName
                Location = $_.InvocationInfo.ScriptLineNumber
            }
            Write-Error "Failed to initialize fragment missing dependencies tests in BeforeAll: $($errorDetails | ConvertTo-Json -Compress)" -ErrorAction Stop
            throw
        }

        $script:InvokeProfile = {
            $WarningPreference = 'Continue'
            . $script:ProfilePath
        }

        # Helper to create a temporary fragment with specific content
        function script:New-TestFragment {
            param(
                [string]$Name,
                [string]$Content
            )

            $fragmentPath = Join-Path $script:ProfileDir $Name
            Set-Content -Path $fragmentPath -Value $Content -Encoding UTF8
            return $fragmentPath
        }

        # Helper to remove test fragment
        function script:Remove-TestFragment {
            param([string]$Name)
            $fragmentPath = Join-Path $script:ProfileDir $Name
            Remove-Item -Path $fragmentPath -Force -ErrorAction SilentlyContinue
        }
    }

    AfterEach {
        # Clean up any test fragments
        Get-ChildItem -Path $script:ProfileDir -Filter '99-test-*.ps1' -ErrorAction SilentlyContinue | Remove-Item -Force
    }

    AfterAll {
        Remove-Variable -Name 'InvokeProfile' -Scope Script -ErrorAction SilentlyContinue
    }

    Context 'Missing Dependencies' {
        It 'handles fragment referencing non-existent command' {
            $fragmentName = '99-test-missing-cmd.ps1'
            $cleanupNeeded = $false

            try {
                $content = @'
# Try to use a command that doesn't exist
$result = Get-NonExistentCommand -ErrorAction SilentlyContinue
'@

                New-TestFragment -Name $fragmentName -Content $content
                $cleanupNeeded = $true

                $records = & $script:InvokeProfile 3>&1
                foreach ($record in $records) {
                    if ($record -is [System.Management.Automation.WarningRecord] -and
                        $record.Message -notlike "Failed to load profile fragment '$fragmentName': *Get-NonExistentCommand*") {
                        Write-Warning $record.Message
                    }
                }
            }
            catch {
                $errorDetails = @{
                    Message      = $_.Exception.Message
                    FragmentName = $fragmentName
                    Category     = $_.CategoryInfo.Category
                }
                Write-Error "Fragment missing command test failed: $($errorDetails | ConvertTo-Json -Compress)" -ErrorAction Continue
                throw
            }
            finally {
                if ($cleanupNeeded) {
                    Remove-TestFragment -Name $fragmentName
                }
            }
        }

        It 'handles fragment referencing non-existent module' {
            $fragmentName = '99-test-missing-module.ps1'
            $cleanupNeeded = $false

            try {
                $content = @'
Import-Module NonExistentModule -ErrorAction SilentlyContinue
'@

                New-TestFragment -Name $fragmentName -Content $content
                $cleanupNeeded = $true

                # Profile should handle missing module gracefully
                { & $script:InvokeProfile } | Should -Not -Throw -Because "profile should handle missing modules gracefully"
            }
            catch {
                $errorDetails = @{
                    Message      = $_.Exception.Message
                    FragmentName = $fragmentName
                    Category     = $_.CategoryInfo.Category
                }
                Write-Error "Fragment missing module test failed: $($errorDetails | ConvertTo-Json -Compress)" -ErrorAction Continue
                throw
            }
            finally {
                if ($cleanupNeeded) {
                    Remove-TestFragment -Name $fragmentName
                }
            }
        }
    }
}

