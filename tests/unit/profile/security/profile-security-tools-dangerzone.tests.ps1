# ===============================================
# profile-security-tools-dangerzone.tests.ps1
# Unit tests for Invoke-DangerzoneConvert function
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
    . (Join-Path $script:ProfileDir 'security-tools.ps1')

    $script:TestRoot = New-TestTempDirectory -Prefix 'DangerzoneTest'
    $script:TestFile = Join-Path $script:TestRoot 'test-file.pdf'
    Set-Content -Path $script:TestFile -Value 'PDF content'
}

Describe 'security-tools.ps1 - Invoke-DangerzoneConvert' {
    BeforeEach {
        Clear-TestCommandInvocationCapture

        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }

        Mark-TestCommandsUnavailable -CommandNames 'dangerzone'
    }

    Context 'Invoke-DangerzoneConvert' {
        It 'Returns null when dangerzone is not available' {
            $result = Invoke-DangerzoneConvert -InputPath $script:TestFile -ErrorAction SilentlyContinue

            $result | Should -BeNullOrEmpty
        }

        It 'Returns error when input file does not exist' {
            Setup-CapturingCommandMock -CommandName 'dangerzone' -Output 'Conversion results'

            $result = Invoke-DangerzoneConvert -InputPath (Join-Path $script:TestRoot 'Missing.pdf') -ErrorAction SilentlyContinue

            $result | Should -BeNullOrEmpty
        }

        It 'Calls dangerzone with correct arguments when tool is available' {
            Setup-CapturingCommandMock -CommandName 'dangerzone' -Output 'Conversion results'

            $outputPath = Join-Path $script:TestRoot 'output.safe.pdf'
            $result = Invoke-DangerzoneConvert -InputPath $script:TestFile -OutputPath $outputPath -ErrorAction SilentlyContinue

            $result | Should -Not -BeNullOrEmpty
            $global:TestCommandInvocationCaptures.Count | Should -Be 1
            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain '--input'
            $args | Should -Contain $script:TestFile
            $args | Should -Contain '--output'
            $args | Should -Contain $outputPath
        }

        It 'Generates default output path when not specified' {
            Setup-CapturingCommandMock -CommandName 'dangerzone' -Output 'Conversion results'

            $testPdf = Join-Path $script:TestRoot 'test.pdf'
            Set-Content -Path $testPdf -Value 'PDF content'

            Invoke-DangerzoneConvert -InputPath $testPdf -ErrorAction SilentlyContinue | Out-Null

            $expectedOutput = Join-Path $script:TestRoot 'test.safe.pdf'
            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain '--input'
            $args | Should -Contain $testPdf
            $args | Should -Contain '--output'
            $args | Should -Contain $expectedOutput
        }

        It 'Handles dangerzone execution errors gracefully' {
            Set-TestCommandThrowingMock -CommandName 'dangerzone' -Message 'Execution failed'

            $result = $null
                        $result = Invoke-DangerzoneConvert -InputPath $script:TestFile -ErrorAction SilentlyContinue
        }
        catch {
            $result = $null

            $result | Should -BeNullOrEmpty
        }

        It 'Tests dangerzone with custom output path' {
            Setup-CapturingCommandMock -CommandName 'dangerzone' -Output 'Conversion results'

            $outputPath = Join-Path $script:TestRoot 'output.pdf'
            Invoke-DangerzoneConvert -InputPath $script:TestFile -OutputPath $outputPath -ErrorAction SilentlyContinue | Out-Null

            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain '--input'
            $args | Should -Contain $script:TestFile
            $args | Should -Contain '--output'
            $args | Should -Contain $outputPath
        }

        It 'Tests dangerzone default output path generation' {
            Setup-CapturingCommandMock -CommandName 'dangerzone' -Output 'Conversion results'

            Invoke-DangerzoneConvert -InputPath $script:TestFile -ErrorAction SilentlyContinue | Out-Null

            $expectedOutput = Join-Path $script:TestRoot 'test-file.safe.pdf'
            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain '--input'
            $args | Should -Contain $script:TestFile
            $args | Should -Contain '--output'
            $args | Should -Contain $expectedOutput
        }

        It 'Handles dangerzone input file not found' {
            Setup-CapturingCommandMock -CommandName 'dangerzone' -Output 'Conversion results'

            $result = Invoke-DangerzoneConvert -InputPath (Join-Path $script:TestRoot 'Missing.pdf') -ErrorAction SilentlyContinue

            $result | Should -BeNullOrEmpty
        }

        It 'Adds Docker requirement to dangerzone install hint when not present' {
            $script:MissingToolWarningCaptures = [System.Collections.Generic.List[hashtable]]::new()
            $originalHint = Get-Command Get-PreferenceAwareInstallHint -ErrorAction SilentlyContinue
            $originalWarning = Get-Command Write-MissingToolWarning -ErrorAction SilentlyContinue

            function global:Get-PreferenceAwareInstallHint {
                param(
                    [string]$ToolName,
                    [string]$ToolType,
                    [string]$DefaultInstallCommand
                )
                return 'Install with: scoop install dangerzone'
            }

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
                $result = Invoke-DangerzoneConvert -InputPath $script:TestFile -ErrorAction SilentlyContinue

                $result | Should -BeNullOrEmpty
                $script:MissingToolWarningCaptures.Count | Should -Be 1
                $script:MissingToolWarningCaptures[0].Tool | Should -Be 'dangerzone'
                $script:MissingToolWarningCaptures[0].InstallHint | Should -Match 'requires Docker'
            }
            finally {
                Remove-Item Function:\Get-PreferenceAwareInstallHint -Force -ErrorAction SilentlyContinue
                Remove-Item Function:\global:Get-PreferenceAwareInstallHint -Force -ErrorAction SilentlyContinue
                Remove-Item Function:\Write-MissingToolWarning -Force -ErrorAction SilentlyContinue
                Remove-Item Function:\global:Write-MissingToolWarning -Force -ErrorAction SilentlyContinue
                if ($originalHint) {
                    Set-Item -Path Function:\global:Get-PreferenceAwareInstallHint -Value $originalHint.ScriptBlock -Force
                }
                if ($originalWarning) {
                    Set-Item -Path Function:\global:Write-MissingToolWarning -Value $originalWarning.ScriptBlock -Force
                }
            }
        }

        It 'Does not add Docker requirement when already present in install hint' {
            $script:MissingToolWarningCaptures = [System.Collections.Generic.List[hashtable]]::new()
            $originalHint = Get-Command Get-PreferenceAwareInstallHint -ErrorAction SilentlyContinue
            $originalWarning = Get-Command Write-MissingToolWarning -ErrorAction SilentlyContinue

            function global:Get-PreferenceAwareInstallHint {
                param(
                    [string]$ToolName,
                    [string]$ToolType,
                    [string]$DefaultInstallCommand
                )
                return 'Install with: scoop install dangerzone (requires Docker)'
            }

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
                Invoke-DangerzoneConvert -InputPath $script:TestFile -ErrorAction SilentlyContinue | Out-Null

                $script:MissingToolWarningCaptures.Count | Should -Be 1
                ($script:MissingToolWarningCaptures[0].InstallHint -split 'requires Docker').Count | Should -Be 2
            }
            finally {
                Remove-Item Function:\Get-PreferenceAwareInstallHint -Force -ErrorAction SilentlyContinue
                Remove-Item Function:\global:Get-PreferenceAwareInstallHint -Force -ErrorAction SilentlyContinue
                Remove-Item Function:\Write-MissingToolWarning -Force -ErrorAction SilentlyContinue
                Remove-Item Function:\global:Write-MissingToolWarning -Force -ErrorAction SilentlyContinue
                if ($originalHint) {
                    Set-Item -Path Function:\global:Get-PreferenceAwareInstallHint -Value $originalHint.ScriptBlock -Force
                }
                if ($originalWarning) {
                    Set-Item -Path Function:\global:Write-MissingToolWarning -Value $originalWarning.ScriptBlock -Force
                }
            }
        }

        It 'Tests dangerzone install hint Docker check when Docker already mentioned' {
            $script:MissingToolWarningCaptures = [System.Collections.Generic.List[hashtable]]::new()
            $originalHint = Get-Command Get-PreferenceAwareInstallHint -ErrorAction SilentlyContinue
            $originalWarning = Get-Command Write-MissingToolWarning -ErrorAction SilentlyContinue

            function global:Get-PreferenceAwareInstallHint {
                param(
                    [string]$ToolName,
                    [string]$ToolType,
                    [string]$DefaultInstallCommand
                )
                return 'Install with: scoop install dangerzone (requires Docker)'
            }

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
                Invoke-DangerzoneConvert -InputPath $script:TestFile -ErrorAction SilentlyContinue | Out-Null

                $script:MissingToolWarningCaptures[0].InstallHint | Should -Be 'Install with: scoop install dangerzone (requires Docker)'
            }
            finally {
                Remove-Item Function:\Get-PreferenceAwareInstallHint -Force -ErrorAction SilentlyContinue
                Remove-Item Function:\global:Get-PreferenceAwareInstallHint -Force -ErrorAction SilentlyContinue
                Remove-Item Function:\Write-MissingToolWarning -Force -ErrorAction SilentlyContinue
                Remove-Item Function:\global:Write-MissingToolWarning -Force -ErrorAction SilentlyContinue
                if ($originalHint) {
                    Set-Item -Path Function:\global:Get-PreferenceAwareInstallHint -Value $originalHint.ScriptBlock -Force
                }
                if ($originalWarning) {
                    Set-Item -Path Function:\global:Write-MissingToolWarning -Value $originalWarning.ScriptBlock -Force
                }
            }
        }

        It 'Tests dangerzone install hint Docker append when not mentioned' {
            $script:MissingToolWarningCaptures = [System.Collections.Generic.List[hashtable]]::new()
            $originalHint = Get-Command Get-PreferenceAwareInstallHint -ErrorAction SilentlyContinue
            $originalWarning = Get-Command Write-MissingToolWarning -ErrorAction SilentlyContinue

            function global:Get-PreferenceAwareInstallHint {
                param(
                    [string]$ToolName,
                    [string]$ToolType,
                    [string]$DefaultInstallCommand
                )
                return 'Install with: scoop install dangerzone'
            }

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
                Invoke-DangerzoneConvert -InputPath $script:TestFile -ErrorAction SilentlyContinue | Out-Null

                $script:MissingToolWarningCaptures[0].InstallHint | Should -Be 'Install with: scoop install dangerzone (requires Docker)'
            }
            finally {
                Remove-Item Function:\Get-PreferenceAwareInstallHint -Force -ErrorAction SilentlyContinue
                Remove-Item Function:\global:Get-PreferenceAwareInstallHint -Force -ErrorAction SilentlyContinue
                Remove-Item Function:\Write-MissingToolWarning -Force -ErrorAction SilentlyContinue
                Remove-Item Function:\global:Write-MissingToolWarning -Force -ErrorAction SilentlyContinue
                if ($originalHint) {
                    Set-Item -Path Function:\global:Get-PreferenceAwareInstallHint -Value $originalHint.ScriptBlock -Force
                }
                if ($originalWarning) {
                    Set-Item -Path Function:\global:Write-MissingToolWarning -Value $originalWarning.ScriptBlock -Force
                }
            }
        }

        It 'Tests dangerzone stderr output handling' {
            Setup-CapturingCommandMock -CommandName 'dangerzone' -OnInvoke {
                [Console]::Error.WriteLine('Warning message')
                return 'Conversion results'
            }

            $result = Invoke-DangerzoneConvert -InputPath $script:TestFile -ErrorAction SilentlyContinue

            $result | Should -Not -BeNullOrEmpty
            $global:TestCommandInvocationCaptures.Count | Should -Be 1
        }

        It 'Tests dangerzone catch block error handling' {
            Set-TestCommandThrowingMock -CommandName 'dangerzone' -Message 'dangerzone not found'

            { Invoke-DangerzoneConvert -InputPath $script:TestFile -ErrorAction Stop } | Should -Throw
        }

        It 'Tests dangerzone Write-Error message format' {
            Set-TestCommandThrowingMock -CommandName 'dangerzone' -Message 'dangerzone not found'

            { Invoke-DangerzoneConvert -InputPath $script:TestFile -ErrorAction Stop } | Should -Throw '*dangerzone*'
        }
    }
}
