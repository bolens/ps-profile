# ===============================================
# profile-beads.tests.ps1
# Unit tests for Invoke-Beads function
# ===============================================

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
    $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
    . (Join-Path $script:ProfileDir 'bootstrap.ps1')
    . (Join-Path $script:ProfileDir 'beads.ps1')
}

Describe 'beads.ps1 - Invoke-Beads' {
    BeforeEach {
        Clear-TestCommandInvocationCapture

        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }

        Mark-TestCommandsUnavailable -CommandNames 'bd'
    }

    Context 'Tool not available' {
        It 'Returns null when bd is not available' {
            $result = Invoke-Beads 'ready' -ErrorAction SilentlyContinue

            $result | Should -BeNullOrEmpty
        }

        It 'Shows installation hint when bd is not available' {
            $script:MissingToolWarningCaptures = [System.Collections.Generic.List[hashtable]]::new()
            $originalWarning = Get-Command Write-MissingToolWarning -ErrorAction SilentlyContinue

            function global:Write-MissingToolWarning {
                param(
                    [string]$Tool,
                    [string]$InstallHint
                )
                $null = $script:MissingToolWarningCaptures.Add(@{
                        Tool        = $Tool
                        InstallHint = $InstallHint
                    })
            }

            try {
                Invoke-Beads 'ready' -ErrorAction SilentlyContinue | Out-Null

                $script:MissingToolWarningCaptures.Count | Should -Be 1
            }
            finally {
                Remove-Item Function:\Write-MissingToolWarning -Force -ErrorAction SilentlyContinue
                Remove-Item Function:\global:Write-MissingToolWarning -Force -ErrorAction SilentlyContinue
                if ($originalWarning) {
                    Set-Item -Path Function:\global:Write-MissingToolWarning -Value $originalWarning.ScriptBlock -Force
                }
            }
        }
    }

    Context 'Tool available' {
        It 'Calls bd with correct arguments' {
            Setup-CapturingCommandMock -CommandName 'bd' -Output 'bd-a1b2  [task] Fix bug'

            $result = Invoke-Beads 'ready'

            $result | Should -Not -BeNullOrEmpty
            $global:TestCommandInvocationCaptures.Count | Should -Be 1
            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain 'ready'
        }

        It 'Handles bd init command' {
            Setup-CapturingCommandMock -CommandName 'bd' -Output 'Beads initialized successfully'

            $result = Invoke-Beads 'init'

            $result | Should -Not -BeNullOrEmpty
            $global:TestCommandInvocationCaptures.Count | Should -Be 1
        }

        It 'Handles bd create command' {
            Setup-CapturingCommandMock -CommandName 'bd' -Output 'bd-f14c  [task] Fix bug'

            $result = Invoke-Beads 'create', 'Fix bug', '-p', '1'

            $result | Should -Not -BeNullOrEmpty
            $global:TestCommandInvocationCaptures.Count | Should -Be 1
        }

        It 'Handles bd execution errors' {
            Set-TestCommandThrowingMock -CommandName 'bd' -Message 'bd: command failed'

            $result = $null
            try {
                $result = Invoke-Beads 'invalid-command' -ErrorAction SilentlyContinue
            }
            catch {
                $result = $null
            }

            $result | Should -BeNullOrEmpty
        }
    }
}

Describe 'beads.ps1 - Helper Functions' {
    BeforeEach {
        Clear-TestCommandInvocationCapture

        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }

        Setup-CapturingCommandMock -CommandName 'bd' -Output 'bd output'
    }

    Context 'Initialize-Beads' {
        It 'Calls bd init with no arguments' {
            Initialize-Beads | Out-Null

            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain 'init'
        }

        It 'Calls bd init with --contributor flag' {
            Initialize-Beads -Contributor | Out-Null

            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain '--contributor'
        }

        It 'Calls bd init with --quiet flag' {
            Initialize-Beads -Quiet | Out-Null

            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain '--quiet'
        }
    }

    Context 'Get-BeadsReady' {
        It 'Calls bd ready with no arguments' {
            Get-BeadsReady | Out-Null

            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain 'ready'
        }

        It 'Calls bd ready with --limit' {
            Get-BeadsReady -Limit 10 | Out-Null

            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain '--limit'
            $args | Should -Contain '10'
        }

        It 'Calls bd ready with --priority' {
            Get-BeadsReady -Priority 1 | Out-Null

            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain '--priority'
            $args | Should -Contain '1'
        }

        It 'Calls bd ready with --json' {
            Get-BeadsReady -Json | Out-Null

            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain '--json'
        }
    }

    Context 'New-BeadsIssue' {
        It 'Calls bd create with title' {
            New-BeadsIssue -Title 'Fix bug' | Out-Null

            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain 'create'
            $args | Should -Contain 'Fix bug'
        }

        It 'Calls bd create with priority and type' {
            New-BeadsIssue -Title 'Fix bug' -Priority 1 -Type bug | Out-Null

            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain '-p'
            $args | Should -Contain '1'
            $args | Should -Contain '-t'
            $args | Should -Contain 'bug'
        }

        It 'Calls bd create with description' {
            New-BeadsIssue -Title 'Fix bug' -Description 'Detailed description' | Out-Null

            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain '-d'
            $args | Should -Contain 'Detailed description'
        }
    }

    Context 'Get-BeadsIssue' {
        It 'Calls bd show with issue ID' {
            Get-BeadsIssue -IssueId 'bd-a1b2' | Out-Null

            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain 'show'
            $args | Should -Contain 'bd-a1b2'
        }

        It 'Calls bd show with --json' {
            Get-BeadsIssue -IssueId 'bd-a1b2' -Json | Out-Null

            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain '--json'
        }
    }

    Context 'Get-BeadsIssues' {
        It 'Calls bd list with no arguments' {
            Get-BeadsIssues | Out-Null

            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain 'list'
        }

        It 'Calls bd list with --status filter' {
            Get-BeadsIssues -Status 'open' | Out-Null

            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain '--status'
            $args | Should -Contain 'open'
        }

        It 'Calls bd list with --label filter' {
            Get-BeadsIssues -Labels 'urgent,backend' | Out-Null

            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain '--label'
            $args | Should -Contain 'urgent,backend'
        }
    }

    Context 'Update-BeadsIssue' {
        It 'Calls bd update with issue ID and status' {
            Update-BeadsIssue -IssueId 'bd-a1b2' -Status 'in_progress' | Out-Null

            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain 'update'
            $args | Should -Contain 'bd-a1b2'
            $args | Should -Contain '--status'
            $args | Should -Contain 'in_progress'
        }

        It 'Calls bd update with priority' {
            Update-BeadsIssue -IssueId 'bd-a1b2' -Priority 0 | Out-Null

            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain '--priority'
            $args | Should -Contain '0'
        }
    }

    Context 'Close-BeadsIssue' {
        It 'Calls bd close with issue ID' {
            Close-BeadsIssue -IssueId 'bd-a1b2' | Out-Null

            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain 'close'
            $args | Should -Contain 'bd-a1b2'
        }

        It 'Calls bd close with reason' {
            Close-BeadsIssue -IssueId 'bd-a1b2' -Reason 'Completed' | Out-Null

            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain '--reason'
            $args | Should -Contain 'Completed'
        }

        It 'Calls bd close multiple times for multiple issues' {
            Close-BeadsIssue -IssueId @('bd-a1b2', 'bd-f14c') | Out-Null

            $global:TestCommandInvocationCaptures.Count | Should -Be 2
        }
    }

    Context 'Get-BeadsStats' {
        It 'Calls bd stats' {
            Get-BeadsStats | Out-Null

            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain 'stats'
        }
    }

    Context 'Get-BeadsBlocked' {
        It 'Calls bd blocked' {
            Get-BeadsBlocked | Out-Null

            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain 'blocked'
        }
    }
}
