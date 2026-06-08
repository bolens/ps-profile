# ===============================================
# profile-modern-cli-enhanced.tests.ps1
# Unit tests for enhanced modern-cli functions
# ===============================================

BeforeAll {
    . (Join-Path $PSScriptRoot '..\TestSupport.ps1')
    $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
    . (Join-Path $script:ProfileDir 'bootstrap.ps1')
    . (Join-Path $script:ProfileDir 'modern-cli.ps1')

    $script:TestSearchDir = New-TestTempDirectory -Prefix 'ModernCliSearch'
    $script:TestBatFile = Join-Path (New-TestTempDirectory -Prefix 'ModernCliBat') 'test.txt'
    Set-Content -Path $script:TestBatFile -Value 'test content'
    $script:TestBatPs1File = Join-Path (Split-Path $script:TestBatFile -Parent) 'test.ps1'
    Set-Content -Path $script:TestBatPs1File -Value 'function test {}'
    $script:ZoxideTargetPath = New-TestTempDirectory -Prefix 'ZoxideTarget'
}

function global:Reset-TestModernCliCommandAvailability {
    $managedCommands = @('fd', 'rg', 'zoxide', 'bat')

    Clear-TestCachedCommandCache | Out-Null

    foreach ($command in $managedCommands) {
        Remove-Item -Path "Function:\$command" -Force -ErrorAction SilentlyContinue
        Remove-Item -Path "Function:\global:$command" -Force -ErrorAction SilentlyContinue

        if ($global:AssumedAvailableCommands) {
            $removed = $null
            $null = $global:AssumedAvailableCommands.TryRemove($command, [ref]$removed)
        }

        $cacheKey = $command.ToLowerInvariant()
        $global:TestCachedCommandCache[$cacheKey] = [pscustomobject]@{
            Result  = $false
            Expires = (Get-Date).AddHours(24)
        }
    }
}

function global:Get-TestModernCliInvocationArgs {
    Get-TestCommandInvocationArgsFlat
}

Describe 'modern-cli.ps1 - Enhanced Functions' {
    BeforeEach {
        Clear-TestCommandInvocationCapture
        Reset-TestModernCliCommandAvailability
    }

    Context 'Find-WithFd' {
        It 'Returns empty array when fd is not available' {
            $result = Find-WithFd -Pattern 'test' -ErrorAction SilentlyContinue

            $result | Should -BeNullOrEmpty
        }

        It 'Calls fd with correct arguments' {
            Setup-CapturingCommandMock -CommandName 'fd' -Output "file1.txt`nfile2.txt"

            $result = Find-WithFd -Pattern 'test' -ErrorAction SilentlyContinue

            $args = Get-TestModernCliInvocationArgs
            $args | Should -Contain '--ignore-case'
            $args | Should -Contain 'test'
            $result | Should -Not -BeNullOrEmpty
        }

        It 'Adds type filter when specified' {
            Setup-CapturingCommandMock -CommandName 'fd' -Output 'file1.txt'

            Find-WithFd -Pattern 'test' -Type f -ErrorAction SilentlyContinue | Out-Null

            $args = Get-TestModernCliInvocationArgs
            $args | Should -Contain '--type'
            $args | Should -Contain 'f'
        }

        It 'Adds extension filter when specified' {
            Setup-CapturingCommandMock -CommandName 'fd' -Output 'file1.ps1'

            Find-WithFd -Pattern 'test' -Extension 'ps1' -ErrorAction SilentlyContinue | Out-Null

            $args = Get-TestModernCliInvocationArgs
            $args | Should -Contain '--extension'
            $args | Should -Contain 'ps1'
        }

        It 'Adds hidden flag when specified' {
            Setup-CapturingCommandMock -CommandName 'fd' -Output ''

            Find-WithFd -Pattern 'test' -Hidden -ErrorAction SilentlyContinue | Out-Null

            $args = Get-TestModernCliInvocationArgs
            $args | Should -Contain '--hidden'
        }

        It 'Handles case-sensitive search' {
            Setup-CapturingCommandMock -CommandName 'fd' -Output ''

            Find-WithFd -Pattern 'Test' -CaseSensitive -ErrorAction SilentlyContinue | Out-Null

            $args = Get-TestModernCliInvocationArgs
            $args | Should -Not -Contain '--ignore-case'
        }
    }

    Context 'Grep-WithRipgrep' {
        It 'Returns empty string when rg is not available' {
            $result = Grep-WithRipgrep -Pattern 'test' -ErrorAction SilentlyContinue

            @($result).Count | Should -Be 0
        }

        It 'Calls rg with correct arguments' {
            Setup-CapturingCommandMock -CommandName 'rg' -Output 'match found'

            $result = Grep-WithRipgrep -Pattern 'test' -ErrorAction SilentlyContinue

            $args = Get-TestModernCliInvocationArgs
            $args | Should -Contain '--ignore-case'
            $args | Should -Contain '--line-number'
            $args | Should -Contain 'test'
            $result | Should -Be 'match found'
        }

        It 'Adds context lines when specified' {
            Setup-CapturingCommandMock -CommandName 'rg' -Output 'match with context'

            Grep-WithRipgrep -Pattern 'test' -Context 3 -ErrorAction SilentlyContinue | Out-Null

            $args = Get-TestModernCliInvocationArgs
            $args | Should -Contain '-C'
            $args | Should -Contain '3'
        }

        It 'Adds file type filter when specified' {
            Setup-CapturingCommandMock -CommandName 'rg' -Output 'match'

            Grep-WithRipgrep -Pattern 'test' -FileType 'ps1' -ErrorAction SilentlyContinue | Out-Null

            $args = Get-TestModernCliInvocationArgs
            $args | Should -Contain '-t'
            $args | Should -Contain 'ps1'
        }

        It 'Handles exit code 1 (no matches) as valid' {
            Setup-CapturingCommandMock -CommandName 'rg' -Output '' -ExitCode 1

            $result = Grep-WithRipgrep -Pattern 'nonexistent' -ErrorAction SilentlyContinue

            $result | Should -BeNullOrEmpty
        }

        It 'Adds files-with-matches flag when specified' {
            Setup-CapturingCommandMock -CommandName 'rg' -Output 'file1.ps1'

            Grep-WithRipgrep -Pattern 'test' -FilesWithMatches -ErrorAction SilentlyContinue | Out-Null

            $args = Get-TestModernCliInvocationArgs
            $args | Should -Contain '-l'
        }
    }

    Context 'Navigate-WithZoxide' {
        It 'Returns null when zoxide is not available' {
            $result = Navigate-WithZoxide -Query 'test' -ErrorAction SilentlyContinue

            $result | Should -BeNullOrEmpty
        }

        It 'Adds current directory to zoxide database' {
            Setup-CapturingCommandMock -CommandName 'zoxide' -Output (Get-Location).Path

            $result = Navigate-WithZoxide -Add -ErrorAction SilentlyContinue

            $args = Get-TestModernCliInvocationArgs
            $args | Should -Contain 'add'
            $result | Should -Not -BeNullOrEmpty
        }

        It 'Queries zoxide for directory' {
            Setup-CapturingCommandMock -CommandName 'zoxide' -OnInvoke {
                param([object[]]$Arguments)
                if ($Arguments[0] -eq 'query') {
                    Write-Output $script:ZoxideTargetPath
                }
            }

            $result = Navigate-WithZoxide -Query 'Documents' -ErrorAction SilentlyContinue

            $args = Get-TestModernCliInvocationArgs
            $args | Should -Contain 'query'
            $args | Should -Contain 'Documents'
            $result | Should -Be $script:ZoxideTargetPath
        }

        It 'Adds interactive flag when specified' {
            Setup-CapturingCommandMock -CommandName 'zoxide' -OnInvoke {
                param([object[]]$Arguments)
                if ($Arguments[0] -eq 'query') {
                    Write-Output $script:ZoxideTargetPath
                }
            }

            Navigate-WithZoxide -Query 'test' -Interactive -ErrorAction SilentlyContinue | Out-Null

            $args = Get-TestModernCliInvocationArgs
            $args | Should -Contain '--interactive'
        }

        It 'Queries all directories when QueryAll specified' {
            Setup-CapturingCommandMock -CommandName 'zoxide' -Output "path1`npath2"

            $result = Navigate-WithZoxide -QueryAll -ErrorAction SilentlyContinue

            $args = Get-TestModernCliInvocationArgs
            $args | Should -Contain 'query'
            @($result).Count | Should -BeGreaterThan 0
        }

        It 'Warns when no query specified' {
            Set-TestCommandAvailabilityState -CommandName 'zoxide'

            $result = Navigate-WithZoxide -ErrorAction SilentlyContinue

            @($result)[-1] | Should -BeNullOrEmpty
        }
    }

    Context 'View-WithBat' {
        It 'Returns when bat is not available' {
            View-WithBat -Path $script:TestBatFile -ErrorAction SilentlyContinue | Out-Null
        }

        It 'Calls bat with correct arguments' {
            Setup-CapturingCommandMock -CommandName 'bat' -Output 'rendered'

            View-WithBat -Path $script:TestBatFile -ErrorAction SilentlyContinue | Out-Null

            $args = Get-TestModernCliInvocationArgs
            $args | Should -Contain '--paging=never'
            $args | Should -Contain '--wrap=never'
            $args | Should -Contain $script:TestBatFile
        }

        It 'Adds language when specified' {
            Setup-CapturingCommandMock -CommandName 'bat' -Output 'rendered'

            View-WithBat -Path $script:TestBatPs1File -Language 'powershell' -ErrorAction SilentlyContinue | Out-Null

            $args = Get-TestModernCliInvocationArgs
            $args | Should -Contain '--language'
            $args | Should -Contain 'powershell'
        }

        It 'Disables line numbers when specified' {
            Setup-CapturingCommandMock -CommandName 'bat' -Output 'rendered'

            View-WithBat -Path $script:TestBatFile -LineNumbers:$false -ErrorAction SilentlyContinue | Out-Null

            $args = Get-TestModernCliInvocationArgs
            $args | Should -Contain '--no-line-numbers'
        }

        It 'Adds plain flag when specified' {
            Setup-CapturingCommandMock -CommandName 'bat' -Output 'rendered'

            View-WithBat -Path $script:TestBatFile -Plain -ErrorAction SilentlyContinue | Out-Null

            $args = Get-TestModernCliInvocationArgs
            $args | Should -Contain '--plain'
        }

        It 'Warns when file does not exist' {
            Set-TestCommandAvailabilityState -CommandName 'bat'
            $missingFile = Join-Path (New-TestTempDirectory -Prefix 'BatMissing') 'nonexistent.txt'

            View-WithBat -Path $missingFile -ErrorAction SilentlyContinue | Out-Null

            Get-TestModernCliInvocationArgs | Should -BeNullOrEmpty
        }
    }
}
