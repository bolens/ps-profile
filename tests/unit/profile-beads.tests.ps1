# ===============================================
# profile-beads.tests.ps1
# Unit tests for Invoke-Beads function
# ===============================================

. (Join-Path $PSScriptRoot '..\TestSupport.ps1')

# Import mocking utilities
$mockingDir = Join-Path (Split-Path $PSScriptRoot -Parent) 'TestSupport' 'Mocking'
Import-Module (Join-Path $mockingDir 'PesterMocks.psm1') -DisableNameChecking -ErrorAction SilentlyContinue

BeforeAll {
    $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
    . (Join-Path $script:ProfileDir 'bootstrap.ps1')
    . (Join-Path $script:ProfileDir 'beads.ps1')
}

Describe 'beads.ps1 - Invoke-Beads' {
    BeforeEach {
        # Clear command cache
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }
        
        if (Get-Variable -Name 'TestCachedCommandCache' -Scope Global -ErrorAction SilentlyContinue) {
            $null = $global:TestCachedCommandCache.TryRemove('bd', [ref]$null)
            $null = $global:TestCachedCommandCache.TryRemove('BD', [ref]$null)
        }
        
        if (Get-Variable -Name 'AssumedAvailableCommands' -Scope Global -ErrorAction SilentlyContinue) {
            $null = $global:AssumedAvailableCommands.TryRemove('bd', [ref]$null)
            $null = $global:AssumedAvailableCommands.TryRemove('BD', [ref]$null)
        }
    }
    
    Context 'Tool not available' {
        It 'Returns null when bd is not available' {
            Mock-CommandAvailabilityPester -CommandName 'bd' -Available $false
            Mock Get-Command -ParameterFilter { $Name -eq 'bd' } -MockWith { return $null }
            
            $result = Invoke-Beads -Arguments @('ready') -ErrorAction SilentlyContinue
            
            $result | Should -BeNullOrEmpty
        }
        
        It 'Shows installation hint when bd is not available' {
            Mock-CommandAvailabilityPester -CommandName 'bd' -Available $false
            Mock Get-Command -ParameterFilter { $Name -eq 'bd' } -MockWith { return $null }
            Mock Write-MissingToolWarning { }
            
            $result = Invoke-Beads -Arguments @('ready') -ErrorAction SilentlyContinue
            
            Should -Invoke Write-MissingToolWarning -Times 1 -Exactly
        }
    }
    
    Context 'Tool available' {
        It 'Calls bd with correct arguments' {
            Setup-AvailableCommandMock -CommandName 'bd'
            
            $script:capturedArgs = $null
            Mock -CommandName 'bd' -MockWith { 
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                return 'bd-a1b2  [task] Fix bug' 
            }
            
            $result = Invoke-Beads -Arguments @('ready')
            
            $result | Should -Not -BeNullOrEmpty
            Should -Invoke -CommandName 'bd' -Times 1 -Exactly
            $script:capturedArgs | Should -Contain 'ready'
        }
        
        It 'Handles bd init command' {
            Setup-AvailableCommandMock -CommandName 'bd'
            
            Mock -CommandName 'bd' -MockWith { 
                return 'Beads initialized successfully'
            }
            
            $result = Invoke-Beads -Arguments @('init')
            
            $result | Should -Not -BeNullOrEmpty
            Should -Invoke -CommandName 'bd' -Times 1 -Exactly
        }
        
        It 'Handles bd create command' {
            Setup-AvailableCommandMock -CommandName 'bd'
            
            Mock -CommandName 'bd' -MockWith { 
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                return 'bd-f14c  [task] Fix bug'
            }
            
            $result = Invoke-Beads -Arguments @('create', 'Fix bug', '-p', '1')
            
            $result | Should -Not -BeNullOrEmpty
            Should -Invoke -CommandName 'bd' -Times 1 -Exactly
        }
        
        It 'Handles bd execution errors' {
            Setup-AvailableCommandMock -CommandName 'bd'
            
            Mock -CommandName 'bd' -MockWith { 
                throw [System.Management.Automation.CommandNotFoundException]::new('bd: command failed')
            }
            Mock Write-Error { }
            
            $result = Invoke-Beads -Arguments @('invalid-command') -ErrorAction SilentlyContinue
            
            $result | Should -BeNullOrEmpty
            Should -Invoke Write-Error -Times 1
        }
    }
}

Describe 'beads.ps1 - Helper Functions' {
    BeforeEach {
        Setup-AvailableCommandMock -CommandName 'bd'
    }
    
    Context 'Initialize-Beads' {
        It 'Calls bd init with no arguments' {
            Mock -CommandName 'bd' -MockWith { 
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                return 'Beads initialized'
            }
            
            $result = Initialize-Beads
            
            Should -Invoke -CommandName 'bd' -Times 1 -Exactly
            $script:capturedArgs | Should -Contain 'init'
        }
        
        It 'Calls bd init with --contributor flag' {
            Mock -CommandName 'bd' -MockWith { 
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                return 'Beads initialized'
            }
            
            $result = Initialize-Beads -Contributor
            
            $script:capturedArgs | Should -Contain '--contributor'
        }
        
        It 'Calls bd init with --quiet flag' {
            Mock -CommandName 'bd' -MockWith { 
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                return 'Beads initialized'
            }
            
            $result = Initialize-Beads -Quiet
            
            $script:capturedArgs | Should -Contain '--quiet'
        }
    }
    
    Context 'Get-BeadsReady' {
        It 'Calls bd ready with no arguments' {
            Mock -CommandName 'bd' -MockWith { 
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                return 'bd-a1b2  [task] Fix bug'
            }
            
            $result = Get-BeadsReady
            
            Should -Invoke -CommandName 'bd' -Times 1 -Exactly
            $script:capturedArgs | Should -Contain 'ready'
        }
        
        It 'Calls bd ready with --limit' {
            Mock -CommandName 'bd' -MockWith { 
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                return 'bd-a1b2  [task] Fix bug'
            }
            
            $result = Get-BeadsReady -Limit 10
            
            $script:capturedArgs | Should -Contain '--limit'
            $script:capturedArgs | Should -Contain '10'
        }
        
        It 'Calls bd ready with --priority' {
            Mock -CommandName 'bd' -MockWith { 
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                return 'bd-a1b2  [task] Fix bug'
            }
            
            $result = Get-BeadsReady -Priority 1
            
            $script:capturedArgs | Should -Contain '--priority'
            $script:capturedArgs | Should -Contain '1'
        }
        
        It 'Calls bd ready with --json' {
            Mock -CommandName 'bd' -MockWith { 
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                return '{"issues":[]}'
            }
            
            $result = Get-BeadsReady -Json
            
            $script:capturedArgs | Should -Contain '--json'
        }
    }
    
    Context 'New-BeadsIssue' {
        It 'Calls bd create with title' {
            Mock -CommandName 'bd' -MockWith { 
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                return 'bd-f14c  [task] Fix bug'
            }
            
            $result = New-BeadsIssue -Title 'Fix bug'
            
            Should -Invoke -CommandName 'bd' -Times 1 -Exactly
            $script:capturedArgs | Should -Contain 'create'
            $script:capturedArgs | Should -Contain 'Fix bug'
        }
        
        It 'Calls bd create with priority and type' {
            Mock -CommandName 'bd' -MockWith { 
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                return 'bd-f14c  [bug] Fix bug'
            }
            
            $result = New-BeadsIssue -Title 'Fix bug' -Priority 1 -Type bug
            
            $script:capturedArgs | Should -Contain '-p'
            $script:capturedArgs | Should -Contain '1'
            $script:capturedArgs | Should -Contain '-t'
            $script:capturedArgs | Should -Contain 'bug'
        }
        
        It 'Calls bd create with description' {
            Mock -CommandName 'bd' -MockWith { 
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                return 'bd-f14c  [task] Fix bug'
            }
            
            $result = New-BeadsIssue -Title 'Fix bug' -Description 'Detailed description'
            
            $script:capturedArgs | Should -Contain '-d'
            $script:capturedArgs | Should -Contain 'Detailed description'
        }
    }
    
    Context 'Get-BeadsIssue' {
        It 'Calls bd show with issue ID' {
            Mock -CommandName 'bd' -MockWith { 
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                return 'Issue bd-a1b2 details'
            }
            
            $result = Get-BeadsIssue -IssueId 'bd-a1b2'
            
            Should -Invoke -CommandName 'bd' -Times 1 -Exactly
            $script:capturedArgs | Should -Contain 'show'
            $script:capturedArgs | Should -Contain 'bd-a1b2'
        }
        
        It 'Calls bd show with --json' {
            Mock -CommandName 'bd' -MockWith { 
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                return '{"id":"bd-a1b2"}'
            }
            
            $result = Get-BeadsIssue -IssueId 'bd-a1b2' -Json
            
            $script:capturedArgs | Should -Contain '--json'
        }
    }
    
    Context 'Get-BeadsIssues' {
        It 'Calls bd list with no arguments' {
            Mock -CommandName 'bd' -MockWith { 
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                return 'bd-a1b2  [task] Fix bug'
            }
            
            $result = Get-BeadsIssues
            
            Should -Invoke -CommandName 'bd' -Times 1 -Exactly
            $script:capturedArgs | Should -Contain 'list'
        }
        
        It 'Calls bd list with --status filter' {
            Mock -CommandName 'bd' -MockWith { 
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                return 'bd-a1b2  [task] Fix bug'
            }
            
            $result = Get-BeadsIssues -Status 'open'
            
            $script:capturedArgs | Should -Contain '--status'
            $script:capturedArgs | Should -Contain 'open'
        }
        
        It 'Calls bd list with --label filter' {
            Mock -CommandName 'bd' -MockWith { 
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                return 'bd-a1b2  [task] Fix bug'
            }
            
            $result = Get-BeadsIssues -Labels 'urgent,backend'
            
            $script:capturedArgs | Should -Contain '--label'
            $script:capturedArgs | Should -Contain 'urgent,backend'
        }
    }
    
    Context 'Update-BeadsIssue' {
        It 'Calls bd update with issue ID and status' {
            Mock -CommandName 'bd' -MockWith { 
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                return 'Updated bd-a1b2'
            }
            
            $result = Update-BeadsIssue -IssueId 'bd-a1b2' -Status 'in_progress'
            
            Should -Invoke -CommandName 'bd' -Times 1 -Exactly
            $script:capturedArgs | Should -Contain 'update'
            $script:capturedArgs | Should -Contain 'bd-a1b2'
            $script:capturedArgs | Should -Contain '--status'
            $script:capturedArgs | Should -Contain 'in_progress'
        }
        
        It 'Calls bd update with priority' {
            Mock -CommandName 'bd' -MockWith { 
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                return 'Updated bd-a1b2'
            }
            
            $result = Update-BeadsIssue -IssueId 'bd-a1b2' -Priority 0
            
            $script:capturedArgs | Should -Contain '--priority'
            $script:capturedArgs | Should -Contain '0'
        }
    }
    
    Context 'Close-BeadsIssue' {
        It 'Calls bd close with issue ID' {
            Mock -CommandName 'bd' -MockWith { 
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                return 'Closed bd-a1b2'
            }
            
            $result = Close-BeadsIssue -IssueId 'bd-a1b2'
            
            Should -Invoke -CommandName 'bd' -Times 1 -Exactly
            $script:capturedArgs | Should -Contain 'close'
            $script:capturedArgs | Should -Contain 'bd-a1b2'
        }
        
        It 'Calls bd close with reason' {
            Mock -CommandName 'bd' -MockWith { 
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                return 'Closed bd-a1b2'
            }
            
            $result = Close-BeadsIssue -IssueId 'bd-a1b2' -Reason 'Completed'
            
            $script:capturedArgs | Should -Contain '--reason'
            $script:capturedArgs | Should -Contain 'Completed'
        }
        
        It 'Calls bd close multiple times for multiple issues' {
            Mock -CommandName 'bd' -MockWith { 
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                return 'Closed'
            }
            
            $result = Close-BeadsIssue -IssueId @('bd-a1b2', 'bd-f14c')
            
            Should -Invoke -CommandName 'bd' -Times 2 -Exactly
        }
    }
    
    Context 'Get-BeadsStats' {
        It 'Calls bd stats' {
            Mock -CommandName 'bd' -MockWith { 
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                return 'Total: 10, Open: 5, Closed: 5'
            }
            
            $result = Get-BeadsStats
            
            Should -Invoke -CommandName 'bd' -Times 1 -Exactly
            $script:capturedArgs | Should -Contain 'stats'
        }
    }
    
    Context 'Get-BeadsBlocked' {
        It 'Calls bd blocked' {
            Mock -CommandName 'bd' -MockWith { 
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                return 'bd-a1b2  [blocked]'
            }
            
            $result = Get-BeadsBlocked
            
            Should -Invoke -CommandName 'bd' -Times 1 -Exactly
            $script:capturedArgs | Should -Contain 'blocked'
        }
    }
}
