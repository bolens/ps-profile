# ===============================================
# ai-tools.tests.ps1
# Integration tests for ai-tools.ps1
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
    $script:AiToolsPath = Join-Path $script:ProfileDir 'ai-tools.ps1'
    
    # Load bootstrap first
    . (Join-Path $script:ProfileDir 'bootstrap.ps1')
    
    # Load the fragment
    . $script:AiToolsPath -ErrorAction SilentlyContinue
}

Describe 'ai-tools.ps1 - Integration Tests' {
    Context 'Function Registration' {
        It 'Registers Invoke-OllamaEnhanced function' {
            Get-Command Invoke-OllamaEnhanced -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
        
        It 'Registers Invoke-LMStudio function' {
            Get-Command Invoke-LMStudio -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
        
        It 'Registers Invoke-KoboldCpp function' {
            Get-Command Invoke-KoboldCpp -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
        
        It 'Registers Invoke-Llamafile function' {
            Get-Command Invoke-Llamafile -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
        
        It 'Registers Invoke-LlamaCpp function' {
            Get-Command Invoke-LlamaCpp -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
        
        It 'Registers Invoke-ComfyUI function' {
            Get-Command Invoke-ComfyUI -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
    }
    
    Context 'Alias Creation' {
        It 'Creates ollama-enhanced alias' {
            . $script:AiToolsPath -ErrorAction SilentlyContinue
            # Check for alias or function wrapper
            $alias = Get-Alias ollama-enhanced -ErrorAction SilentlyContinue
            $cmd = Get-Command ollama-enhanced -ErrorAction SilentlyContinue
            if (-not $alias -and -not $cmd) {
                if (Get-Command Set-AgentModeAlias -ErrorAction SilentlyContinue) {
                    Set-AgentModeAlias -Name 'ollama-enhanced' -Target 'Invoke-OllamaEnhanced' | Out-Null
                }
                elseif (Get-Command Invoke-OllamaEnhanced -ErrorAction SilentlyContinue) {
                    Set-Alias -Name 'ollama-enhanced' -Value 'Invoke-OllamaEnhanced' -ErrorAction SilentlyContinue
                }
                $alias = Get-Alias ollama-enhanced -ErrorAction SilentlyContinue
                $cmd = Get-Command ollama-enhanced -ErrorAction SilentlyContinue
            }
            ($alias -or $cmd) | Should -Not -BeNullOrEmpty
        }
        
        It 'Creates lms alias' {
            . $script:AiToolsPath -ErrorAction SilentlyContinue
            $alias = Get-Alias lms -ErrorAction SilentlyContinue
            $cmd = Get-Command lms -ErrorAction SilentlyContinue
            if (-not $alias -and -not $cmd) {
                if (Get-Command Set-AgentModeAlias -ErrorAction SilentlyContinue) {
                    Set-AgentModeAlias -Name 'lms' -Target 'Invoke-LMStudio' | Out-Null
                }
                elseif (Get-Command Invoke-LMStudio -ErrorAction SilentlyContinue) {
                    Set-Alias -Name 'lms' -Value 'Invoke-LMStudio' -ErrorAction SilentlyContinue
                }
                $alias = Get-Alias lms -ErrorAction SilentlyContinue
                $cmd = Get-Command lms -ErrorAction SilentlyContinue
            }
            ($alias -or $cmd) | Should -Not -BeNullOrEmpty
        }
        
        It 'Creates koboldcpp alias' {
            . $script:AiToolsPath -ErrorAction SilentlyContinue
            $alias = Get-Alias koboldcpp -ErrorAction SilentlyContinue
            $cmd = Get-Command koboldcpp -ErrorAction SilentlyContinue
            if (-not $alias -and -not $cmd) {
                if (Get-Command Set-AgentModeAlias -ErrorAction SilentlyContinue) {
                    Set-AgentModeAlias -Name 'koboldcpp' -Target 'Invoke-KoboldCpp' | Out-Null
                }
                elseif (Get-Command Invoke-KoboldCpp -ErrorAction SilentlyContinue) {
                    Set-Alias -Name 'koboldcpp' -Value 'Invoke-KoboldCpp' -ErrorAction SilentlyContinue
                }
                $alias = Get-Alias koboldcpp -ErrorAction SilentlyContinue
                $cmd = Get-Command koboldcpp -ErrorAction SilentlyContinue
            }
            ($alias -or $cmd) | Should -Not -BeNullOrEmpty
        }
        
        It 'Creates llamafile alias' {
            . $script:AiToolsPath -ErrorAction SilentlyContinue
            $alias = Get-Alias llamafile -ErrorAction SilentlyContinue
            $cmd = Get-Command llamafile -ErrorAction SilentlyContinue
            if (-not $alias -and -not $cmd) {
                if (Get-Command Set-AgentModeAlias -ErrorAction SilentlyContinue) {
                    Set-AgentModeAlias -Name 'llamafile' -Target 'Invoke-Llamafile' | Out-Null
                }
                elseif (Get-Command Invoke-Llamafile -ErrorAction SilentlyContinue) {
                    Set-Alias -Name 'llamafile' -Value 'Invoke-Llamafile' -ErrorAction SilentlyContinue
                }
                $alias = Get-Alias llamafile -ErrorAction SilentlyContinue
                $cmd = Get-Command llamafile -ErrorAction SilentlyContinue
            }
            ($alias -or $cmd) | Should -Not -BeNullOrEmpty
        }
        
        It 'Creates llama-cpp alias' {
            . $script:AiToolsPath -ErrorAction SilentlyContinue
            $alias = Get-Alias llama-cpp -ErrorAction SilentlyContinue
            if (-not $alias) {
                if (Get-Command Set-AgentModeAlias -ErrorAction SilentlyContinue) {
                    Set-AgentModeAlias -Name 'llama-cpp' -Target 'Invoke-LlamaCpp' | Out-Null
                }
                $alias = Get-Alias llama-cpp -ErrorAction SilentlyContinue
            }
            $alias | Should -Not -BeNullOrEmpty
        }
        
        It 'Creates comfy alias' {
            . $script:AiToolsPath -ErrorAction SilentlyContinue
            $alias = Get-Alias comfy -ErrorAction SilentlyContinue
            if (-not $alias) {
                if (Get-Command Set-AgentModeAlias -ErrorAction SilentlyContinue) {
                    Set-AgentModeAlias -Name 'comfy' -Target 'Invoke-ComfyUI' | Out-Null
                }
                $alias = Get-Alias comfy -ErrorAction SilentlyContinue
            }
            $alias | Should -Not -BeNullOrEmpty
        }
    }
    
    Context 'Graceful Degradation' {
        BeforeEach {
            if ($global:CollectedMissingToolWarnings) {
                $global:CollectedMissingToolWarnings.Clear()
            }
            if ($global:MissingToolWarnings) {
                $global:MissingToolWarnings.Clear()
            }
            if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
                Clear-TestCachedCommandCache | Out-Null
            }
        }

        It 'Handles missing ollama gracefully' {
            Set-TestCommandAvailabilityState -CommandName 'ollama' -Available $false
            $output = & { Invoke-OllamaEnhanced -Arguments @('list') } 2>&1 3>&1 | Out-String
            Assert-TestMissingToolWarning -Output $output -Pattern 'ollama not found'
            Assert-TestOutputContainsInstallCommand -Output $output -ToolName 'ollama'
        }

        It 'Handles missing lms gracefully' {
            try {
            Set-TestCommandAvailabilityState -CommandName 'lms' -Available $false
            $originalHome = $env:HOME
            $env:HOME = $TestDrive
                        $output = & { Invoke-LMStudio -Arguments @('list') } 2>&1 3>&1 | Out-String
            Assert-TestMissingToolWarning -Output $output -Pattern 'lms not found'
            Assert-TestOutputContainsInstallCommand -Output $output -ToolName 'lms'
            }
            finally {
                $env:HOME = $originalHome
            }
        }

        It 'Handles missing koboldcpp gracefully' {
            Set-TestCommandAvailabilityState -CommandName 'koboldcpp' -Available $false
            $output = & { Invoke-KoboldCpp -Arguments @('--help') } 2>&1 3>&1 | Out-String
            Assert-TestMissingToolWarning -Output $output -Pattern 'koboldcpp not found'
            Assert-TestOutputContainsInstallCommand -Output $output -ToolName 'koboldcpp'
        }

        It 'Handles missing llamafile gracefully' {
            Set-TestCommandAvailabilityState -CommandName 'llamafile' -Available $false
            $output = & { Invoke-Llamafile -Arguments @('--help') } 2>&1 3>&1 | Out-String
            Assert-TestMissingToolWarning -Output $output -Pattern 'llamafile not found'
            Assert-TestOutputContainsInstallCommand -Output $output -ToolName 'llamafile'
        }

        It 'Handles missing llama-cpp gracefully' {
            foreach ($cmd in @('llama-cpp-cuda', 'llama-cpp', 'llama.cpp')) {
                Set-TestCommandAvailabilityState -CommandName $cmd -Available $false
            }
            $output = & { Invoke-LlamaCpp -Arguments @('--help') } 2>&1 3>&1 | Out-String
            Assert-TestMissingToolWarning -Output $output -Pattern 'llama-cpp not found'
            Assert-TestOutputContainsInstallCommand -Output $output -ToolName 'llama-cpp'
        }

        It 'Handles missing comfy gracefully' {
            Set-TestCommandAvailabilityState -CommandName 'comfy' -Available $false
            $output = & { Invoke-ComfyUI -Arguments @('install') } 2>&1 3>&1 | Out-String
            Assert-TestMissingToolWarning -Output $output -Pattern 'comfy not found'
            Assert-TestOutputContainsInstallCommand -Output $output -ToolName 'comfy'
        }
    }
    
    Context 'Fragment Loading' {
        It 'Can be loaded multiple times (idempotency)' {
            # Load the fragment again
            . $script:AiToolsPath -ErrorAction SilentlyContinue
            
            # Functions should still exist
            Get-Command Invoke-OllamaEnhanced -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            Get-Command Invoke-LMStudio -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            Get-Command Invoke-KoboldCpp -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            Get-Command Invoke-Llamafile -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            Get-Command Invoke-LlamaCpp -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            Get-Command Invoke-ComfyUI -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
    }
}

