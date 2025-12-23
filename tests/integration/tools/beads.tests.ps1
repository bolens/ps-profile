# ===============================================
# beads.tests.ps1
# Integration tests for beads.ps1
# ===============================================

. (Join-Path $PSScriptRoot '..\..\TestSupport.ps1')

BeforeAll {
    $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
    $script:BeadsPath = Join-Path $script:ProfileDir 'beads.ps1'
    
    # Load bootstrap first
    . (Join-Path $script:ProfileDir 'bootstrap.ps1')
    
    # Load the fragment
    . $script:BeadsPath -ErrorAction SilentlyContinue
}

Describe 'beads.ps1 - Integration Tests' {
    Context 'Function Registration' {
        It 'Registers Invoke-Beads function' {
            Get-Command Invoke-Beads -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
        
        It 'Function has correct parameters' {
            $cmd = Get-Command Invoke-Beads -ErrorAction SilentlyContinue
            $cmd | Should -Not -BeNullOrEmpty
            $cmd.Parameters.ContainsKey('Arguments') | Should -Be $true
        }
    }
    
    Context 'Alias Creation' {
        It 'Creates bd alias' {
            . $script:BeadsPath -ErrorAction SilentlyContinue
            # Check for alias or function wrapper
            $alias = Get-Alias bd -ErrorAction SilentlyContinue
            if (-not $alias) {
                # May be registered as function wrapper
                $func = Get-Command bd -ErrorAction SilentlyContinue
                $func | Should -Not -BeNullOrEmpty
            }
        }
    }
    
    Context 'Idempotency' {
        It 'Can be loaded multiple times without errors' {
            { . $script:BeadsPath -ErrorAction Stop } | Should -Not -Throw
            { . $script:BeadsPath -ErrorAction Stop } | Should -Not -Throw
        }
        
        It 'Function remains available after multiple loads' {
            . $script:BeadsPath -ErrorAction SilentlyContinue
            . $script:BeadsPath -ErrorAction SilentlyContinue
            
            Get-Command Invoke-Beads -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
    }
    
    Context 'Error Handling' {
        It 'Handles missing bd command gracefully' {
            # Clear any cached command availability
            if (Get-Variable -Name 'TestCachedCommandCache' -Scope Global -ErrorAction SilentlyContinue) {
                $null = $global:TestCachedCommandCache.TryRemove('bd', [ref]$null)
            }
            
            Mock Get-Command -ParameterFilter { $Name -eq 'bd' } -MockWith { return $null }
            Mock-CommandAvailabilityPester -CommandName 'bd' -Available $false
            
            $result = Invoke-Beads -Arguments @('ready') -ErrorAction SilentlyContinue
            
            $result | Should -BeNullOrEmpty
        }
    }
}
    Context 'Helper Function Registration' {
        It 'Registers Initialize-Beads function' {
            Get-Command Initialize-Beads -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
        
        It 'Registers Get-BeadsReady function' {
            Get-Command Get-BeadsReady -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
        
        It 'Registers New-BeadsIssue function' {
            Get-Command New-BeadsIssue -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
        
        It 'Registers Get-BeadsIssue function' {
            Get-Command Get-BeadsIssue -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
        
        It 'Registers Get-BeadsIssues function' {
            Get-Command Get-BeadsIssues -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
        
        It 'Registers Update-BeadsIssue function' {
            Get-Command Update-BeadsIssue -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
        
        It 'Registers Close-BeadsIssue function' {
            Get-Command Close-BeadsIssue -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
        
        It 'Registers Get-BeadsStats function' {
            Get-Command Get-BeadsStats -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
        
        It 'Registers Get-BeadsBlocked function' {
            Get-Command Get-BeadsBlocked -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
    }
    
    Context 'Helper Function Parameters' {
        It 'Initialize-Beads has correct parameters' {
            $cmd = Get-Command Initialize-Beads -ErrorAction SilentlyContinue
            $cmd.Parameters.ContainsKey('Contributor') | Should -Be $true
            $cmd.Parameters.ContainsKey('Team') | Should -Be $true
            $cmd.Parameters.ContainsKey('Quiet') | Should -Be $true
        }
        
        It 'Get-BeadsReady has correct parameters' {
            $cmd = Get-Command Get-BeadsReady -ErrorAction SilentlyContinue
            $cmd.Parameters.ContainsKey('Limit') | Should -Be $true
            $cmd.Parameters.ContainsKey('Priority') | Should -Be $true
            $cmd.Parameters.ContainsKey('Json') | Should -Be $true
        }
        
        It 'New-BeadsIssue has correct parameters' {
            $cmd = Get-Command New-BeadsIssue -ErrorAction SilentlyContinue
            $cmd.Parameters.ContainsKey('Title') | Should -Be $true
            $cmd.Parameters['Title'].Attributes.Mandatory | Should -Be $true
            $cmd.Parameters.ContainsKey('Priority') | Should -Be $true
            $cmd.Parameters.ContainsKey('Type') | Should -Be $true
        }
        
        It 'Get-BeadsIssue has correct parameters' {
            $cmd = Get-Command Get-BeadsIssue -ErrorAction SilentlyContinue
            $cmd.Parameters.ContainsKey('IssueId') | Should -Be $true
            $cmd.Parameters['IssueId'].Attributes.Mandatory | Should -Be $true
        }
        
        It 'Update-BeadsIssue has correct parameters' {
            $cmd = Get-Command Update-BeadsIssue -ErrorAction SilentlyContinue
            $cmd.Parameters.ContainsKey('IssueId') | Should -Be $true
            $cmd.Parameters['IssueId'].Attributes.Mandatory | Should -Be $true
            $cmd.Parameters.ContainsKey('Status') | Should -Be $true
        }
        
        It 'Close-BeadsIssue has correct parameters' {
            $cmd = Get-Command Close-BeadsIssue -ErrorAction SilentlyContinue
            $cmd.Parameters.ContainsKey('IssueId') | Should -Be $true
            $cmd.Parameters['IssueId'].Attributes.Mandatory | Should -Be $true
            $cmd.Parameters.ContainsKey('Reason') | Should -Be $true
        }
    }
    
    Context 'Helper Functions Idempotency' {
        It 'All helper functions remain available after multiple loads' {
            . $script:BeadsPath -ErrorAction SilentlyContinue
            . $script:BeadsPath -ErrorAction SilentlyContinue
            
            Get-Command Initialize-Beads -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            Get-Command Get-BeadsReady -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            Get-Command New-BeadsIssue -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            Get-Command Get-BeadsIssue -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            Get-Command Get-BeadsIssues -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            Get-Command Update-BeadsIssue -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            Get-Command Close-BeadsIssue -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            Get-Command Get-BeadsStats -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            Get-Command Get-BeadsBlocked -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
    }
}
