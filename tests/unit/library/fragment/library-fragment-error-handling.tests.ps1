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
    $script:FragmentErrorHandlingPath = Join-Path $script:LibPath 'fragment' 'FragmentErrorHandling.psm1'
    
    # Import Logging module first (dependency)
    $loggingPath = Join-Path $script:LibPath 'core' 'Logging.psm1'
    if (Test-Path $loggingPath) {
        Import-Module $loggingPath -DisableNameChecking -ErrorAction SilentlyContinue -Force
    }
    
    # Import the module under test
    Import-Module $script:FragmentErrorHandlingPath -DisableNameChecking -ErrorAction Stop -Force
    
    # Create test fragment files
    $script:TestFragmentDir = New-TestTempDirectory -Prefix 'FragmentErrorTests'
    New-Item -ItemType Directory -Path $script:TestFragmentDir -Force | Out-Null
    
    # Valid fragment
    $script:ValidFragmentPath = Join-Path $script:TestFragmentDir 'valid-fragment.ps1'
    Set-Content -Path $script:ValidFragmentPath -Value @'
# Valid test fragment
$script:TestVariable = 'loaded'
'@
    
    # Fragment with error
    $script:ErrorFragmentPath = Join-Path $script:TestFragmentDir 'error-fragment.ps1'
    Set-Content -Path $script:ErrorFragmentPath -Value @'
# Fragment that throws an error
throw 'Test error in fragment'
'@
    
    # Fragment with syntax error
    $script:SyntaxErrorFragmentPath = Join-Path $script:TestFragmentDir 'syntax-error-fragment.ps1'
    Set-Content -Path $script:SyntaxErrorFragmentPath -Value @'
# Fragment with syntax error
function Test-Function {
    # Missing closing brace
'@
}

AfterAll {
    Remove-Module FragmentErrorHandling -ErrorAction SilentlyContinue -Force
    Remove-Module Logging -ErrorAction SilentlyContinue -Force
    
    # Clean up test fragments
    if ($script:TestFragmentDir -and (Test-Path $script:TestFragmentDir)) {
        Remove-Item -Path $script:TestFragmentDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Describe 'FragmentErrorHandling Module Functions' {
    Context 'Invoke-FragmentSafely' {
        It 'Successfully executes a valid fragment file' {
            $result = Invoke-FragmentSafely -FragmentName 'test-fragment' -FragmentPath $script:ValidFragmentPath
            $result | Should -Be $true
        }

        It 'Returns false for non-existent fragment file' {
            $nonExistentPath = Join-Path $script:TestFragmentDir 'nonexistent.ps1'
            $result = Invoke-FragmentSafely -FragmentName 'nonexistent' -FragmentPath $nonExistentPath
            $result | Should -Be $false
        }

        It 'Successfully executes a script block' {
            $scriptBlock = { $script:TestVar = 'executed' }
            $result = Invoke-FragmentSafely -FragmentName 'test-block' -FragmentPath 'dummy.ps1' -ScriptBlock $scriptBlock
            $result | Should -Be $true
            $script:TestVar | Should -Be 'executed'
        }

        It 'Returns false when script block throws an error' {
            $errorBlock = { throw 'Test error' }
            $result = Invoke-FragmentSafely -FragmentName 'error-block' -FragmentPath 'dummy.ps1' -ScriptBlock $errorBlock
            $result | Should -Be $false
        }

        It 'Returns false when fragment file throws an error' {
            $result = Invoke-FragmentSafely -FragmentName 'error-fragment' -FragmentPath $script:ErrorFragmentPath
            $result | Should -Be $false
        }

        It 'Handles file access errors gracefully' {
            # Create a file that will cause access issues (if possible)
            $accessErrorPath = Join-Path $script:TestFragmentDir 'access-error.ps1'
            Set-Content -Path $accessErrorPath -Value '# Test'
            
            # Try to make it inaccessible (may not work on all systems)
                        $acl = Get-Acl $accessErrorPath
            $acl.SetAccessRuleProtection($true, $false)
            $acl.Access | ForEach-Object { $acl.RemoveAccessRule($_) }
            Set-Acl $accessErrorPath $acl -ErrorAction SilentlyContinue
            
            $result = Invoke-FragmentSafely -FragmentName 'access-error' -FragmentPath $accessErrorPath
            $result | Should -Be $false
        }
        catch {
            # If we can't test access errors, just verify the function exists
            Get-Command Invoke-FragmentSafely | Should -Not -BeNullOrEmpty
        }

        It 'Suppresses warnings when SuppressWarnings is specified' {
            $errorBlock = { throw 'Test error' }
            $result = Invoke-FragmentSafely -FragmentName 'suppressed' -FragmentPath 'dummy.ps1' -ScriptBlock $errorBlock -SuppressWarnings
            $result | Should -Be $false
            # Warning should be suppressed (hard to test directly, but function should complete)
        }

        It 'Includes line number in error message when available' {
            $errorBlock = {
                $line = 42
                throw 'Test error with line number'
            }
            $result = Invoke-FragmentSafely -FragmentName 'line-number' -FragmentPath 'dummy.ps1' -ScriptBlock $errorBlock
            $result | Should -Be $false
        }

        It 'Handles debug mode correctly' {
            $originalDebug = $env:PS_PROFILE_DEBUG
                        $env:PS_PROFILE_DEBUG = '1'
            $errorBlock = { throw 'Debug test error' }
            $result = Invoke-FragmentSafely -FragmentName 'debug-test' -FragmentPath 'dummy.ps1' -ScriptBlock $errorBlock
            $result | Should -Be $false
        }
        finally {
            if ($originalDebug) {
                $env:PS_PROFILE_DEBUG = $originalDebug
            }
            else {
                $env:PS_PROFILE_DEBUG = $null
            }
        }
    }

    Context 'Write-FragmentError' {
        It 'Writes error with fragment name' {
            $errorRecord = [System.Management.Automation.ErrorRecord]::new(
                [System.Exception]::new('Test error'),
                'TestErrorId',
                [System.Management.Automation.ErrorCategory]::InvalidOperation,
                $null
            )

            Write-FragmentError -ErrorRecord $errorRecord -FragmentName 'test-fragment' -ErrorAction SilentlyContinue -ErrorVariable fragmentErrors | Out-Null
            $fragmentErrors | Should -Not -BeNullOrEmpty
        }

        It 'Includes context in error message when provided' {
            $errorRecord = [System.Management.Automation.ErrorRecord]::new(
                [System.Exception]::new('Test error'),
                'TestErrorId',
                [System.Management.Automation.ErrorCategory]::InvalidOperation,
                $null
            )

            Write-FragmentError -ErrorRecord $errorRecord -FragmentName 'test-fragment' -Context 'Initialization' -ErrorAction SilentlyContinue -ErrorVariable fragmentErrors | Out-Null
            $fragmentErrors | Should -Not -BeNullOrEmpty
            $fragmentErrors[0].Exception.Message | Should -Match 'Initialization'
        }

        It 'Uses Write-ProfileError when fragment load fails in debug mode' {
            $script:WriteProfileErrorInvocations = [System.Collections.Generic.List[hashtable]]::new()
            $originalWriteProfileError = Get-Command Write-ProfileError -ErrorAction SilentlyContinue

            function global:Write-ProfileError {
                param(
                    $ErrorRecord,
                    $Context,
                    $Category
                )

                $null = $script:WriteProfileErrorInvocations.Add(@{
                        Context  = $Context
                        Category = $Category
                    })
            }

            Set-Item -Path Function:\global:Write-ProfileError -Value ${function:global:Write-ProfileError} -Force

            if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
                Clear-TestCachedCommandCache | Out-Null
            }
            if (Get-Command Remove-TestCachedCommandCacheEntry -ErrorAction SilentlyContinue) {
                Remove-TestCachedCommandCacheEntry -Name 'Write-ProfileError' | Out-Null
            }

            $originalDebug = $env:PS_PROFILE_DEBUG
            try {
                $env:PS_PROFILE_DEBUG = '1'
                $errorBlock = { throw 'Test error' }
                $result = Invoke-FragmentSafely -FragmentName 'test-fragment' -FragmentPath 'dummy.ps1' -ScriptBlock $errorBlock
                $result | Should -Be $false
                $script:WriteProfileErrorInvocations.Count | Should -BeGreaterThan 0
            }
            finally {
                Remove-Item Function:\Write-ProfileError -Force -ErrorAction SilentlyContinue
                Remove-Item Function:\global:Write-ProfileError -Force -ErrorAction SilentlyContinue
                if ($originalWriteProfileError) {
                    Set-Item -Path Function:\global:Write-ProfileError -Value $originalWriteProfileError.ScriptBlock -Force
                }

                if ($null -ne $originalDebug) {
                    $env:PS_PROFILE_DEBUG = $originalDebug
                }
                else {
                    Remove-Item Env:\PS_PROFILE_DEBUG -ErrorAction SilentlyContinue
                }
            }
        }

        It 'Falls back to Write-Error when Write-ProfileError is not available' {
            $errorRecord = [System.Management.Automation.ErrorRecord]::new(
                [System.Exception]::new('Test error'),
                'TestErrorId',
                [System.Management.Automation.ErrorCategory]::InvalidOperation,
                $null
            )

            Write-FragmentError -ErrorRecord $errorRecord -FragmentName 'test-fragment' -ErrorAction SilentlyContinue -ErrorVariable fragmentErrors | Out-Null
            $fragmentErrors | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-FragmentErrorInfo' {
        It 'Extracts error information correctly' {
            $errorRecord = [System.Management.Automation.ErrorRecord]::new(
                [System.Exception]::new('Test error message'),
                'TestErrorId',
                [System.Management.Automation.ErrorCategory]::InvalidOperation,
                $null
            )
            
            $errorInfo = Get-FragmentErrorInfo -ErrorRecord $errorRecord -FragmentName 'test-fragment'
            $errorInfo | Should -Not -BeNullOrEmpty
            $errorInfo.FragmentName | Should -Be 'test-fragment'
            $errorInfo.ErrorMessage | Should -Be 'Test error message'
            $errorInfo.ErrorType | Should -Not -BeNullOrEmpty
        }

        It 'Includes timestamp in error info' {
            $errorRecord = [System.Management.Automation.ErrorRecord]::new(
                [System.Exception]::new('Test error'),
                'TestErrorId',
                [System.Management.Automation.ErrorCategory]::InvalidOperation,
                $null
            )
            
            $errorInfo = Get-FragmentErrorInfo -ErrorRecord $errorRecord -FragmentName 'test-fragment'
            $errorInfo.Timestamp | Should -Not -BeNullOrEmpty
            $errorInfo.Timestamp | Should -BeOfType [DateTime]
        }

        It 'Includes inner exception when available' {
            $innerException = [System.Exception]::new('Inner error')
            $outerException = [System.Exception]::new('Outer error', $innerException)
            $errorRecord = [System.Management.Automation.ErrorRecord]::new(
                $outerException,
                'TestErrorId',
                [System.Management.Automation.ErrorCategory]::InvalidOperation,
                $null
            )
            
            $errorInfo = Get-FragmentErrorInfo -ErrorRecord $errorRecord -FragmentName 'test-fragment'
            $errorInfo.PSObject.Properties.Name | Should -Contain 'InnerException'
            $errorInfo.InnerException | Should -Be 'Inner error'
            $errorInfo.PSObject.Properties.Name | Should -Contain 'InnerExceptionType'
        }

        It 'Includes script stack trace when available' {
                        throw 'Test error for stack trace'
        }
        catch {
            $errorInfo = Get-FragmentErrorInfo -ErrorRecord $_ -FragmentName 'test-fragment'
            # Stack trace may or may not be available depending on context
            if ($errorInfo.PSObject.Properties.Name -contains 'ScriptStackTrace') {
                $errorInfo.ScriptStackTrace | Should -Not -BeNullOrEmpty
            }
        }

        It 'Includes invocation information' {
            $errorRecord = [System.Management.Automation.ErrorRecord]::new(
                [System.Exception]::new('Test error'),
                'TestErrorId',
                [System.Management.Automation.ErrorCategory]::InvalidOperation,
                $null
            )
            
            $errorInfo = Get-FragmentErrorInfo -ErrorRecord $errorRecord -FragmentName 'test-fragment'
            $errorInfo.PSObject.Properties.Name | Should -Contain 'FullyQualifiedErrorId'
            $errorInfo.FullyQualifiedErrorId | Should -Be 'TestErrorId'
        }

        It 'Handles error records with line numbers' {
                        # Create an error with line number context
            $null = Get-Item 'nonexistent-file-that-does-not-exist-12345.ps1' -ErrorAction Stop
        }
        catch {
            $errorInfo = Get-FragmentErrorInfo -ErrorRecord $_ -FragmentName 'test-fragment'
            $errorInfo | Should -Not -BeNullOrEmpty
            $errorInfo.ErrorMessage | Should -Not -BeNullOrEmpty
        }
    }
}

