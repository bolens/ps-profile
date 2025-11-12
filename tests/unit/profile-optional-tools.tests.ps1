#
# Tests for optional tool helper fragments (navi, gum).
#

. (Join-Path $PSScriptRoot '..\TestSupport.ps1')

BeforeAll {
    Import-TestCommonModule | Out-Null
    $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
    . (Join-Path $script:ProfileDir '00-bootstrap.ps1')
    $script:NaviFragmentPath = Join-Path $script:ProfileDir '62-navi.ps1'
    $script:GumFragmentPath = Join-Path $script:ProfileDir '63-gum.ps1'
    $script:OriginalTestHasCommand = Get-Command Test-HasCommand -ErrorAction SilentlyContinue
}

AfterAll {
    if ($script:OriginalTestHasCommand) {
        Set-Item -Path Function:Test-HasCommand -Value $script:OriginalTestHasCommand.ScriptBlock -Force
    }
    elseif (Get-Command Test-HasCommand -ErrorAction SilentlyContinue) {
        Remove-Item -Path Function:Test-HasCommand -Force
    }
}

Describe 'Profile optional tool helpers' {
    Context 'navi fragment' {
        BeforeEach {
            $script:naviCallHistory = [System.Collections.ArrayList]::new()
            foreach ($aliasName in 'cheats', 'navis', 'navib', 'navip') {
                if (Get-Alias -Name $aliasName -ErrorAction SilentlyContinue) {
                    Remove-Item -Path "Alias:$aliasName" -Force
                }
            }
            foreach ($functionName in 'Invoke-NaviSearch', 'Invoke-NaviBest', 'Invoke-NaviPrint') {
                if (Get-Command $functionName -ErrorAction SilentlyContinue) {
                    Remove-Item -Path "Function:$functionName" -Force
                }
            }
            if (Get-Command -Name navi -CommandType Function -ErrorAction SilentlyContinue) {
                Remove-Item -Path Function:navi -Force
            }
        }

        AfterEach {
            foreach ($aliasName in 'cheats', 'navis', 'navib', 'navip') {
                if (Get-Alias -Name $aliasName -ErrorAction SilentlyContinue) {
                    Remove-Item -Path "Alias:$aliasName" -Force
                }
            }
            foreach ($functionName in 'Invoke-NaviSearch', 'Invoke-NaviBest', 'Invoke-NaviPrint') {
                if (Get-Command $functionName -ErrorAction SilentlyContinue) {
                    Remove-Item -Path "Function:$functionName" -Force
                }
            }
            if (Get-Command -Name navi -CommandType Function -ErrorAction SilentlyContinue) {
                Remove-Item -Path Function:navi -Force
            }
            if ($script:OriginalTestHasCommand) {
                Set-Item -Path Function:Test-HasCommand -Value $script:OriginalTestHasCommand.ScriptBlock -Force
            }
            elseif (Get-Command Test-HasCommand -ErrorAction SilentlyContinue) {
                Remove-Item -Path Function:Test-HasCommand -Force
            }
        }

        It 'Invoke-NaviSearch forwards query when available' {
            Set-Item -Path Function:Test-HasCommand -Value { param($Name) $Name -eq 'navi' } -Force
            function global:navi {
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $null = $script:naviCallHistory.Add($Arguments)
            }

            . $script:NaviFragmentPath

            Invoke-NaviSearch -Query 'git status'
            $script:naviCallHistory.Count | Should -Be 1
            $firstCall = [object[]]$script:naviCallHistory[0]
            $firstCall | Should -Contain '--query'
            $firstCall | Should -Contain 'git status'

            Invoke-NaviSearch
            $script:naviCallHistory.Count | Should -Be 2
            $secondCall = [object[]]$script:naviCallHistory[1]
            $secondCall.Count | Should -Be 0
        }

        It 'Invoke-NaviBest toggles best flag and optional query' {
            Set-Item -Path Function:Test-HasCommand -Value { param($Name) $Name -eq 'navi' } -Force
            function global:navi {
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $null = $script:naviCallHistory.Add($Arguments)
            }

            . $script:NaviFragmentPath

            Invoke-NaviBest -Query 'deploy'
            $firstCall = [object[]]$script:naviCallHistory[0]
            $firstCall | Should -Contain '--best'
            $firstCall | Should -Contain '--query'
            $firstCall | Should -Contain 'deploy'

            Invoke-NaviBest
            $secondCall = [object[]]$script:naviCallHistory[1]
            $secondCall | Should -Contain '--best'
            $secondCall.Count | Should -Be 1
        }

        It 'Invoke-NaviPrint honours optional query' {
            Set-Item -Path Function:Test-HasCommand -Value { param($Name) $Name -eq 'navi' } -Force
            function global:navi {
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $null = $script:naviCallHistory.Add($Arguments)
            }

            . $script:NaviFragmentPath

            Invoke-NaviPrint -Query 'status'
            $firstCall = [object[]]$script:naviCallHistory[0]
            $firstCall | Should -Contain '--print'
            $firstCall | Should -Contain '--query'
            $firstCall | Should -Contain 'status'

            Invoke-NaviPrint
            $secondCall = [object[]]$script:naviCallHistory[1]
            $secondCall | Should -Contain '--print'
            $secondCall.Count | Should -Be 1
        }

        It 'warns when navi is unavailable' {
            function global:Test-HasCommand { param($Name) return $false }

            if (Get-Command -Name Clear-MissingToolWarnings -ErrorAction SilentlyContinue) {
                Clear-MissingToolWarnings -Tool 'navi' | Out-Null
            }

            $warnings = & {
                $WarningPreference = 'Continue'
                . $script:NaviFragmentPath
            } 3>&1

            ($warnings | ForEach-Object { $_.Message }) | Should -Contain 'navi not found. Install with: scoop install navi'
            Get-Command Invoke-NaviSearch -ErrorAction SilentlyContinue | Should -Be $null
        }
    }

    Context 'gum fragment' {
        BeforeAll {
            . $script:GumFragmentPath
        }

        BeforeEach {
            $script:GumReturnValue = $null
            $script:NextExitCode = $null
            $script:gumCallCount = 0
            $script:gumLastArgs = $null
            $script:gumPipeline = @()
            function global:gum {
                $script:gumPipeline = @()
                foreach ($item in $input) {
                    if ($null -ne $item) {
                        $script:gumPipeline += $item
                    }
                }
                $script:gumLastArgs = @($args)
                $script:gumCallCount++
                if ($null -ne $script:NextExitCode) {
                    $global:LASTEXITCODE = $script:NextExitCode
                }
                else {
                    $global:LASTEXITCODE = 0
                }
                if ($null -ne $script:GumReturnValue) {
                    return $script:GumReturnValue
                }
            }
        }

        AfterEach {
            if (Get-Command -Name gum -CommandType Function -ErrorAction SilentlyContinue) {
                Remove-Item -Path Function:gum -Force
            }
            $global:LASTEXITCODE = 0
        }

        It 'Invoke-GumConfirm reflects exit codes' {
            $script:GumReturnValue = $null

            $script:NextExitCode = 0
            Invoke-GumConfirm -Prompt 'Proceed?' | Should -Be $true
            $firstCallArgs = [object[]]$script:gumLastArgs
            $firstCallArgs[0] | Should -Be 'confirm'
            $firstCallArgs[1] | Should -Be 'Proceed?'

            $script:NextExitCode = 1
            Invoke-GumConfirm -Prompt 'Cancel?' | Should -Be $false
            $secondCallArgs = [object[]]$script:gumLastArgs
            $secondCallArgs[0] | Should -Be 'confirm'
            $secondCallArgs[1] | Should -Be 'Cancel?'
            $script:gumCallCount | Should -Be 2
        }

        It 'Invoke-GumChoose pipes options to gum choose' {
            $script:GumReturnValue = 'two'
            $options = @('one', 'two')
            $result = Invoke-GumChoose -Options $options -Prompt 'Pick'
            $result | Should -Be 'two'
            $script:gumPipeline.Count | Should -Be 2
            $script:gumPipeline[0] | Should -Be 'one'
            $script:gumPipeline[1] | Should -Be 'two'
            $lastArgs = [object[]]$script:gumLastArgs
            $lastArgs[0] | Should -Be 'choose'
            $lastArgs[1] | Should -Be '--header'
            $lastArgs[2] | Should -Be 'Pick'
            $script:gumCallCount | Should -Be 1
        }

        It 'Invoke-GumChoose skips invocation with no options' {
            Invoke-GumChoose -Prompt 'Nothing'
            $script:gumCallCount | Should -Be 0
        }

        It 'Invoke-GumSpin wraps scripts with gum spin' {
            $script:GumReturnValue = 'done'
            Invoke-GumSpin -Title 'Deploying' -Script { 'noop' } | Should -Be 'done'
            $callArgs = [object[]]$script:gumLastArgs
            $callArgs[0] | Should -Be 'spin'
            $callArgs | Should -Contain '--title'
            $callArgs | Should -Contain 'Deploying'
            $callArgs[-1] | Should -BeOfType [scriptblock]
            $script:gumCallCount | Should -Be 1
        }

        It 'Invoke-GumSpin does nothing without a script block' {
            Invoke-GumSpin -Title 'No work'
            $script:gumCallCount | Should -Be 0
        }

        It 'Invoke-GumStyle applies style arguments' {
            $script:GumReturnValue = 'styled'
            $result = Invoke-GumStyle -Text 'hello' -Foreground 'magenta' -Background 'cyan'
            $result | Should -Be 'styled'
            $script:gumPipeline.Count | Should -Be 1
            $script:gumPipeline[0] | Should -Be 'hello'
            $lastArgs = [object[]]$script:gumLastArgs
            $lastArgs[0] | Should -Be 'style'
            $lastArgs[1] | Should -Be '--foreground'
            $lastArgs[2] | Should -Be 'magenta'
            $lastArgs[3] | Should -Be '--background'
            $lastArgs[4] | Should -Be 'cyan'
            $script:gumCallCount | Should -Be 1
        }

        It 'Invoke-GumStyle supports minimalist usage' {
            $script:GumReturnValue = 'plain'
            $result = Invoke-GumStyle -Text 'plain'
            $result | Should -Be 'plain'
            $script:gumPipeline.Count | Should -Be 1
            $script:gumPipeline[0] | Should -Be 'plain'
            $lastArgs = [object[]]$script:gumLastArgs
            $lastArgs.Count | Should -Be 1
            $lastArgs[0] | Should -Be 'style'
            $script:gumCallCount | Should -Be 1
        }
    }
}
