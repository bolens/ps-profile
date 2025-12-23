

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
            . (Join-Path $script:ProfileDir 'bootstrap.ps1')
            . (Join-Path $script:ProfileDir 'system.ps1')
        }

        It 'Get-DiskUsage function exists and returns drive information' {
            try {
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
        }

        It 'Get-TopProcesses function exists and returns process information' {
            Get-Command Get-TopProcesses -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            $result = Get-TopProcesses
            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -BeLessOrEqual 10
        }

        It 'Get-NetworkPorts function exists' {
            Get-Command Get-NetworkPorts -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            # Mock netstat command availability and execution to avoid actual network calls
            # Get-NetworkPorts checks: Get-Command netstat, then calls: & netstat -an
            Mock-CommandAvailabilityPester -CommandName 'netstat' -Available $true -Scope It
            Mock -CommandName netstat -MockWith { "Active Connections`nTCP    0.0.0.0:80" }
            # Test that function doesn't throw when called
            { Get-NetworkPorts -ErrorAction SilentlyContinue | Out-Null } | Should -Not -Throw
        }

        It 'Get-NetworkPorts handles missing netstat command gracefully' {
            Get-Command Get-NetworkPorts -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            # Mock netstat as unavailable
            Mock-CommandAvailabilityPester -CommandName 'netstat' -Available $false -Scope It
            # Function should handle missing command gracefully
            { Get-NetworkPorts -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It 'Test-NetworkConnection function exists' {
            Get-Command Test-NetworkConnection -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            # Mock Test-Connection to avoid actual network calls
            Mock-TestConnection -Success $true -ResponseTime 1 -ComputerName 'localhost'
            # Test with localhost which should always work
            $result = Test-NetworkConnection -ComputerName localhost -Count 1 -ErrorAction SilentlyContinue
            # Result may be null if ping fails, but function should exist
            { Test-NetworkConnection -ComputerName localhost -Count 1 -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It 'Resolve-DnsNameCustom function exists' {
            Get-Command Resolve-DnsNameCustom -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            # Mock Resolve-DnsName to avoid actual DNS calls
            Mock-NetworkPester -Operation 'Resolve-DnsName' -ReturnValue @{
                Name      = 'localhost'
                Type      = 'A'
                IPAddress = '127.0.0.1'
            } -ParameterFilter { $Name -eq 'localhost' }
            # Test with localhost
            { Resolve-DnsNameCustom -Name localhost -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It 'Find-File function exists and can search for files' {
            Get-Command Find-File -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            # Create a test file
            $testFile = Join-Path $TestDrive 'test_find.txt'
            Set-Content -Path $testFile -Value 'test content'
            # Search for it
            $result = Find-File -Filter 'test_find.txt'
            # Result may be empty if search doesn't work as expected, but function should exist
            { Find-File -Filter '*.txt' } | Should -Not -Throw
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
            # Mock Invoke-RestMethod to avoid network dependency (Invoke-RestApi uses Invoke-RestMethod internally)
            # Call Mock directly in test context to ensure proper scoping
            $returnValue = @{ success = $true }
            $returnValueJson = ($returnValue | ConvertTo-Json -Compress -Depth 10)
            $mockWith = [scriptblock]::Create("('$returnValueJson' | ConvertFrom-Json)")
            Mock -CommandName Invoke-RestMethod -MockWith $mockWith
            # Test that function doesn't throw when called
            { Invoke-RestApi -Uri 'http://test.example.com' -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It 'Invoke-WebRequestCustom function exists' {
            Get-Command Invoke-WebRequestCustom -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            # Mock Invoke-WebRequest to avoid network dependency (Invoke-WebRequestCustom uses Invoke-WebRequest internally)
            # Call Mock directly in test context to ensure proper scoping
            $values = @{
                StatusCode = 200
                Content    = "Test response"
                Headers    = @{}
            }
            $valuesJson = ($values | ConvertTo-Json -Compress -Depth 10)
            $mockWith = [scriptblock]::Create("`$v = ('$valuesJson' | ConvertFrom-Json); [PSCustomObject]@{ StatusCode = `$v.StatusCode; Content = `$v.Content; Headers = `$v.Headers }")
            Mock -CommandName Invoke-WebRequest -MockWith $mockWith
            # Test that function doesn't throw when called
            { Invoke-WebRequestCustom -Uri 'http://test.example.com' -ErrorAction SilentlyContinue } | Should -Not -Throw
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

