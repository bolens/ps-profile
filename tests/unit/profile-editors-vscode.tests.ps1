# ===============================================
# profile-editors-vscode.tests.ps1
# Unit tests for VS Code editor functions
# ===============================================

. (Join-Path $PSScriptRoot '..\TestSupport.ps1')

# Import mocking utilities
$mockingDir = Join-Path (Split-Path $PSScriptRoot -Parent) 'TestSupport' 'Mocking'
Import-Module (Join-Path $mockingDir 'PesterMocks.psm1') -DisableNameChecking -ErrorAction SilentlyContinue

BeforeAll {
    $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
    . (Join-Path $script:ProfileDir 'bootstrap.ps1')
    . (Join-Path $script:ProfileDir 'editors.ps1')
}

Describe 'editors.ps1 - VS Code Functions' {
    BeforeEach {
        # Clear command cache
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }
        
        if (Get-Variable -Name 'TestCachedCommandCache' -Scope Global -ErrorAction SilentlyContinue) {
            $null = $global:TestCachedCommandCache.TryRemove('code-insiders', [ref]$null)
            $null = $global:TestCachedCommandCache.TryRemove('code', [ref]$null)
            $null = $global:TestCachedCommandCache.TryRemove('codium', [ref]$null)
        }
        
        Mock Get-Location -MockWith { return [PSCustomObject]@{ Path = $TestDrive } }
        
        # Always mock Start-Process to prevent actual process launches
        # Individual tests can override this with more specific mocks
        Mock Start-Process -MockWith {
            # Default mock - just capture the call, don't launch anything
            return $null
        }
    }
    
    Context 'Edit-WithVSCode' {
        It 'Returns null when VS Code is not available' {
            Mock-CommandAvailabilityPester -CommandName 'code-insiders' -Available $false
            Mock-CommandAvailabilityPester -CommandName 'code' -Available $false
            Mock-CommandAvailabilityPester -CommandName 'codium' -Available $false
            
            $result = Edit-WithVSCode -ErrorAction SilentlyContinue
            
            $result | Should -BeNullOrEmpty
        }
        
        It 'Calls code-insiders when available' {
            Setup-AvailableCommandMock -CommandName 'code-insiders'
            Mock Test-Path -ParameterFilter { $LiteralPath -eq $TestDrive } -MockWith { return $true }
            
            $script:capturedProcess = $null
            Mock Start-Process -MockWith {
                $script:capturedProcess = @{
                    FilePath     = $FilePath
                    ArgumentList = $ArgumentList
                }
            }
            
            Edit-WithVSCode -ErrorAction SilentlyContinue
            
            $script:capturedProcess | Should -Not -BeNullOrEmpty
            $script:capturedProcess.FilePath | Should -Be 'code-insiders'
        }
        
        It 'Falls back to code when code-insiders not available' {
            Mock-CommandAvailabilityPester -CommandName 'code-insiders' -Available $false
            Setup-AvailableCommandMock -CommandName 'code'
            Mock Test-Path -ParameterFilter { $LiteralPath -eq $TestDrive } -MockWith { return $true }
            
            $script:capturedProcess = $null
            Mock Start-Process -MockWith {
                $script:capturedProcess = @{
                    FilePath     = $FilePath
                    ArgumentList = $ArgumentList
                }
            }
            
            Edit-WithVSCode -ErrorAction SilentlyContinue
            
            $script:capturedProcess.FilePath | Should -Be 'code'
        }
        
        It 'Falls back to codium when code-insiders and code not available' {
            Mock-CommandAvailabilityPester -CommandName 'code-insiders' -Available $false
            Mock-CommandAvailabilityPester -CommandName 'code' -Available $false
            Setup-AvailableCommandMock -CommandName 'codium'
            Mock Test-Path -ParameterFilter { $LiteralPath -eq $TestDrive } -MockWith { return $true }
            
            $script:capturedProcess = $null
            Mock Start-Process -MockWith {
                $script:capturedProcess = @{
                    FilePath     = $FilePath
                    ArgumentList = $ArgumentList
                }
            }
            
            Edit-WithVSCode -ErrorAction SilentlyContinue
            
            $script:capturedProcess.FilePath | Should -Be 'codium'
        }
        
        It 'Calls VS Code with new window flag when provided' {
            Setup-AvailableCommandMock -CommandName 'code-insiders'
            Mock Test-Path -ParameterFilter { $LiteralPath -eq $TestDrive } -MockWith { return $true }
            
            $script:capturedProcess = $null
            Mock Start-Process -MockWith {
                $script:capturedProcess = @{
                    FilePath     = $FilePath
                    ArgumentList = $ArgumentList
                }
            }
            
            Edit-WithVSCode -NewWindow -ErrorAction SilentlyContinue
            
            $script:capturedProcess.ArgumentList | Should -Contain '--new-window'
        }
        
        It 'Calls VS Code with wait flag when provided' {
            Setup-AvailableCommandMock -CommandName 'code-insiders'
            Mock Test-Path -ParameterFilter { $LiteralPath -eq $TestDrive } -MockWith { return $true }
            
            $script:capturedProcess = $null
            $script:capturedWait = $null
            Mock Start-Process -MockWith {
                $script:capturedProcess = @{
                    FilePath     = $FilePath
                    ArgumentList = $ArgumentList
                }
                $script:capturedWait = $Wait
                # Return a process object with ExitCode when Wait and PassThru are used
                if ($Wait -and $PassThru) {
                    return [PSCustomObject]@{
                        ExitCode = 0
                    }
                }
            } -ParameterFilter { $Wait -eq $true -and $PassThru -eq $true }
            
            Edit-WithVSCode -Wait -ErrorAction SilentlyContinue
            
            $script:capturedProcess.ArgumentList | Should -Contain '--wait'
            $script:capturedWait | Should -Be $true
        }
        
        It 'Handles VS Code exit code when Wait is used' {
            Setup-AvailableCommandMock -CommandName 'code-insiders'
            Mock Test-Path -ParameterFilter { $LiteralPath -eq $TestDrive } -MockWith { return $true }
            
            $script:capturedProcess = $null
            Mock Start-Process -MockWith {
                $script:capturedProcess = @{
                    FilePath     = $FilePath
                    ArgumentList = $ArgumentList
                }
                # Return a process object with non-zero exit code
                return [PSCustomObject]@{
                    ExitCode = 1
                }
            } -ParameterFilter { $Wait -eq $true -and $PassThru -eq $true }
            
            Edit-WithVSCode -Wait -ErrorAction SilentlyContinue
            
            $script:capturedProcess.ArgumentList | Should -Contain '--wait'
        }
        
        It 'Handles Start-Process errors gracefully' {
            Setup-AvailableCommandMock -CommandName 'code-insiders'
            Mock Test-Path -ParameterFilter { $LiteralPath -eq $TestDrive } -MockWith { return $true }
            Mock Start-Process -MockWith { throw "Process start failed" }
            
            { Edit-WithVSCode -ErrorAction Stop } | Should -Throw
        }
        
        It 'Errors when path does not exist' {
            Setup-AvailableCommandMock -CommandName 'code-insiders'
            Mock Test-Path -ParameterFilter { $LiteralPath -eq 'nonexistent' } -MockWith { return $false }
            
            { Edit-WithVSCode -Path 'nonexistent' -ErrorAction Stop } | Should -Throw
        }
    }
}

