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
}

<#
.SYNOPSIS
    Integration tests for storage tool fragments (rclone, minio).

.DESCRIPTION
    Tests rclone and MinIO helper functions.
    These tests verify that functions are created correctly and handle
    missing tools gracefully.
#>

Describe 'Storage Tools Integration Tests' {
    BeforeAll {
                $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
        if ($null -eq $script:ProfileDir -or [string]::IsNullOrWhiteSpace($script:ProfileDir)) {
            throw "Get-TestPath returned null or empty value for ProfileDir"
        }
        if (-not (Test-Path -LiteralPath $script:ProfileDir)) {
            throw "Profile directory not found at: $script:ProfileDir"
        }
        
        $bootstrapPath = Join-Path $script:ProfileDir 'bootstrap.ps1'
        if ($null -eq $bootstrapPath -or [string]::IsNullOrWhiteSpace($bootstrapPath)) {
            throw "BootstrapPath is null or empty"
        }
        if (-not (Test-Path -LiteralPath $bootstrapPath)) {
            throw "Bootstrap file not found at: $bootstrapPath"
        }
        . $bootstrapPath
    }
    catch {
        $errorDetails = @{
            Message  = $_.Exception.Message
            Type     = $_.Exception.GetType().FullName
            Location = $_.InvocationInfo.ScriptLineNumber
        }
        Write-Error "Failed to initialize storage tools tests in BeforeAll: $($errorDetails | ConvertTo-Json -Compress)" -ErrorAction Stop
        throw
    }

    Context 'rclone helpers (rclone.ps1)' {
        BeforeAll {
            Mark-TestCommandsUnavailable -CommandNames @('rclone', 'rcopy', 'rls')
            Set-TestCommandAvailabilityState -CommandName 'rclone' -Available $true
            . (Join-Path $script:ProfileDir 'rclone.ps1')
            Register-TestFragmentAliases @{
                rcopy = 'Copy-RcloneFile'
                rls   = 'Get-RcloneFileList'
            }
        }

        It 'Creates Copy-RcloneFile function' {
            Get-Command Copy-RcloneFile -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates rcopy alias for Copy-RcloneFile' {
            Get-Alias rcopy -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias rcopy).ResolvedCommandName | Should -Be 'Copy-RcloneFile'
        }

        It 'rcopy alias handles missing tool gracefully and recommends installation' {
            if ($global:MissingToolWarnings) {
                $null = $global:MissingToolWarnings.TryRemove('rclone', [ref]$null)
            }
            Mark-TestCommandsUnavailable -CommandNames @('rclone')
            Set-TestCommandAvailabilityState -CommandName 'rclone' -Available $false
            Set-Alias -Name rcopy -Value Copy-RcloneFile -Scope Global -Force -ErrorAction SilentlyContinue | Out-Null
            $output = rcopy source dest 2>&1 3>&1 | Out-String
            Assert-TestMissingToolWarning -Output $output -Pattern 'rclone not found'
            Assert-TestOutputContainsInstallCommand -Output $output -ToolName 'rclone'
        }

        It 'Creates Get-RcloneFileList function' {
            Get-Command Get-RcloneFileList -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates rls alias for Get-RcloneFileList' {
            Get-Alias rls -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias rls).ResolvedCommandName | Should -Be 'Get-RcloneFileList'
        }
    }

    Context 'MinIO helpers (minio.ps1)' {
        BeforeAll {
            Mark-TestCommandsUnavailable -CommandNames @('mc')
            Set-TestCommandAvailabilityState -CommandName 'mc' -Available $true
            . (Join-Path $script:ProfileDir 'minio.ps1')
            Register-TestFragmentAliases @{
                'mc-ls' = 'Get-MinioFileList'
                'mc-cp' = 'Copy-MinioFile'
            }
        }

        It 'Creates Get-MinioFileList function' {
            Get-Command Get-MinioFileList -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates mc-ls alias for Get-MinioFileList' {
            Get-Alias mc-ls -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias mc-ls).ResolvedCommandName | Should -Be 'Get-MinioFileList'
        }

        It 'mc-ls alias handles missing tool gracefully and recommends installation' {
            if ($global:MissingToolWarnings) {
                $null = $global:MissingToolWarnings.TryRemove('mc', [ref]$null)
            }
            Mark-TestCommandsUnavailable -CommandNames @('mc')
            Set-TestCommandAvailabilityState -CommandName 'mc' -Available $false
            Set-Alias -Name mc-ls -Value Get-MinioFileList -Scope Global -Force -ErrorAction SilentlyContinue | Out-Null
            $output = mc-ls path 2>&1 3>&1 | Out-String
            Assert-TestMissingToolWarning -Output $output -Pattern 'mc not found'
            Assert-TestOutputContainsInstallCommand -Output $output -ToolName 'minio-client'
        }

        It 'Creates Copy-MinioFile function' {
            Get-Command Copy-MinioFile -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates mc-cp alias for Copy-MinioFile' {
            Get-Alias mc-cp -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias mc-cp).ResolvedCommandName | Should -Be 'Copy-MinioFile'
        }
    }
}

