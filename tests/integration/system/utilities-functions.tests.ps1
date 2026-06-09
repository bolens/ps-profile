

Describe 'System Utility Functions' {
    BeforeAll {
        try {
            # Load TestSupport to ensure network mocking functions are available
            $testSupportPath = Get-TestSupportPath -StartPath $PSScriptRoot
            if ($null -eq $testSupportPath -or [string]::IsNullOrWhiteSpace($testSupportPath)) {
                throw "Get-TestSupportPath returned null or empty value"
            }
            if (-not (Test-Path -LiteralPath $testSupportPath)) {
                throw "TestSupport file not found at: $testSupportPath"
            }
            . $testSupportPath

            $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
            if (-not (Get-Command Initialize-SystemUtilityIntegration -ErrorAction SilentlyContinue)) {
                throw 'Initialize-SystemUtilityIntegration is not available from TestSupport'
            }
            $script:ProfilePath = Get-TestPath -RelativePath 'Microsoft.PowerShell_profile.ps1' -StartPath $PSScriptRoot -EnsureExists
            if ($null -eq $script:ProfileDir -or [string]::IsNullOrWhiteSpace($script:ProfileDir)) {
                throw "Get-TestPath returned null or empty value for ProfileDir"
            }
            if ($null -eq $script:ProfilePath -or [string]::IsNullOrWhiteSpace($script:ProfilePath)) {
                throw "Get-TestPath returned null or empty value for ProfilePath"
            }
            if (-not (Test-Path -LiteralPath $script:ProfileDir)) {
                throw "Profile directory not found at: $script:ProfileDir"
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
            Write-Error "Failed to initialize system utility functions tests in BeforeAll: $($errorDetails | ConvertTo-Json -Compress)" -ErrorAction Stop
            throw
        }
    }

    Context 'System utility functions' {
        BeforeAll {
            Initialize-SystemUtilityIntegration -ProfileDir $script:ProfileDir -IncludeUtilities
        }

        It 'Get-DiskUsage function exists and returns drive information' {
                        Get-Command Get-DiskUsage -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null -Because "Get-DiskUsage function should be available"
            $result = Get-DiskUsage
            $result | Should -Not -BeNullOrEmpty -Because "Get-DiskUsage should return drive information"
            $result[0].PSObject.Properties.Name | Should -Contain 'Name' -Because "drive information should include Name property"
        }
        catch {
            $errorDetails = @{
                Message  = $_.Exception.Message
                Function = 'Get-DiskUsage'
                Category = $_.CategoryInfo.Category
            }
            Write-Error "Get-DiskUsage test failed: $($errorDetails | ConvertTo-Json -Compress)" -ErrorAction Continue
            throw
        }

        It 'Get-TopProcesses function exists and returns process information' {
            Get-Command Get-TopProcesses -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            $result = Get-TopProcesses
            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -BeLessOrEqual 10
        }

        It 'Get-NetworkPorts function exists' {
            Get-Command Get-NetworkPorts -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            Setup-CapturingCommandMock -CommandName 'netstat' -Output @(
                'Active Connections',
                'TCP    0.0.0.0:80'
            )
            $result = Get-NetworkPorts -ErrorAction SilentlyContinue
            $result | Should -Not -BeNullOrEmpty
            Assert-TestCommandInvokedExactlyOnce
        }

        It 'Get-NetworkPorts handles missing netstat command gracefully' {
            Get-Command Get-NetworkPorts -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            Mark-TestCommandsUnavailable -CommandNames @('netstat')
            Set-TestCommandAvailabilityState -CommandName 'netstat' -Available $false
            { Get-NetworkPorts -ErrorAction Stop } | Should -Throw '*netstat*'
        }

        It 'Test-NetworkConnection function exists' {
            Get-Command Test-NetworkConnection -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            Register-TestProfileFunctionStub -Name 'Test-Connection' -Body {
                param(
                    [Parameter(ValueFromRemainingArguments = $true)]
                    [object[]]$Arguments
                )

                return [PSCustomObject]@{
                    ComputerName = 'localhost'
                    ResponseTime = 1
                    Status       = 'Success'
                }
            }
            $result = Test-NetworkConnection -ComputerName localhost -Count 1 -ErrorAction SilentlyContinue
            { Test-NetworkConnection -ComputerName localhost -Count 1 -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It 'Resolve-DnsNameCustom function exists' {
            Get-Command Resolve-DnsNameCustom -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            if (-not (Get-Command Resolve-DnsName -ErrorAction SilentlyContinue)) {
                function global:Resolve-DnsName {
                    param([string]$Name)
                    [PSCustomObject]@{ Name = $Name; Type = 'A'; IPAddress = '127.0.0.1' }
                }
            }
            { Resolve-DnsNameCustom -Name 'localhost' -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It 'Find-File function exists and can search for files' {
            Get-Command Find-File -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            $testFile = Join-Path $TestDrive 'test_find.txt'
            Set-Content -Path $testFile -Value 'test content'
            Push-Location $TestDrive
                        { Find-File 'test_find.txt' -ErrorAction SilentlyContinue | Out-Null } | Should -Not -Throw
        }
        finally {
            Pop-Location
        }

        It 'New-Directory function exists' {
            Get-Command New-Directory -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            $testDir = Join-Path $TestDrive 'test_new_dir'
            { New-Directory -Path $testDir } | Should -Not -Throw
            if ($testDir -and -not [string]::IsNullOrWhiteSpace($testDir)) {
                Test-Path -LiteralPath $testDir | Should -Be $true
            }
        }

        It 'Remove-ItemCustom function exists' {
            Get-Command Remove-ItemCustom -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            $testFile = Join-Path $TestDrive 'test_remove.txt'
            Set-Content -Path $testFile -Value 'test'
            { Remove-ItemCustom -Path $testFile } | Should -Not -Throw
            if ($testFile -and -not [string]::IsNullOrWhiteSpace($testFile)) {
                Test-Path -LiteralPath $testFile | Should -Be $false
            }
        }

        It 'Copy-ItemCustom function exists' {
            Get-Command Copy-ItemCustom -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            $sourceFile = Join-Path $TestDrive 'test_copy_source.txt'
            $destFile = Join-Path $TestDrive 'test_copy_dest.txt'
            Set-Content -Path $sourceFile -Value 'test content'
            { Copy-ItemCustom -Path $sourceFile -Destination $destFile } | Should -Not -Throw
            if ($destFile -and -not [string]::IsNullOrWhiteSpace($destFile)) {
                Test-Path -LiteralPath $destFile | Should -Be $true
            }
        }

        It 'Move-ItemCustom function exists' {
            Get-Command Move-ItemCustom -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            $sourceFile = Join-Path $TestDrive 'test_move_source.txt'
            $destFile = Join-Path $TestDrive 'test_move_dest.txt'
            Set-Content -Path $sourceFile -Value 'test content'
            { Move-ItemCustom -Path $sourceFile -Destination $destFile } | Should -Not -Throw
            if ($sourceFile -and -not [string]::IsNullOrWhiteSpace($sourceFile)) {
                Test-Path -LiteralPath $sourceFile | Should -Be $false
            }
            if ($destFile -and -not [string]::IsNullOrWhiteSpace($destFile)) {
                Test-Path -LiteralPath $destFile | Should -Be $true
            }
        }

        It 'Invoke-RestApi function exists' {
            Get-Command Invoke-RestApi -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            Setup-CapturingCommandMock -CommandName 'Invoke-RestMethod' -OnInvoke {
                return [PSCustomObject]@{ success = $true }
            }
            $result = Invoke-RestApi -Uri 'http://test.example.com' -ErrorAction SilentlyContinue
            $result | Should -Not -BeNullOrEmpty
            $result.success | Should -Be $true
            Assert-TestCommandInvokedExactlyOnce
        }

        It 'Invoke-WebRequestCustom function exists' {
            Get-Command Invoke-WebRequestCustom -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            Setup-CapturingCommandMock -CommandName 'Invoke-WebRequest' -OnInvoke {
                return [PSCustomObject]@{
                    StatusCode = 200
                    Content    = 'Test response'
                    Headers    = @{}
                }
            }
            $result = Invoke-WebRequestCustom -Uri 'http://test.example.com' -ErrorAction SilentlyContinue
            $result | Should -Not -BeNullOrEmpty
            $result.StatusCode | Should -Be 200
            Assert-TestCommandInvokedExactlyOnce
        }

        It 'Expand-ArchiveCustom function exists' {
            Get-Command Expand-ArchiveCustom -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            # Just test that function exists, don't call with invalid parameters
        }

        It 'Compress-ArchiveCustom function exists' {
            Get-Command Compress-ArchiveCustom -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            # Just test that function exists, don't call with invalid parameters
        }

        It 'Open-VSCode function exists' {
            Get-Command Open-VSCode -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            # Just test that function exists, don't call it since VS Code may not be installed
        }
    }
}

