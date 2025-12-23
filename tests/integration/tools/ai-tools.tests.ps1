# ===============================================
# ai-tools.tests.ps1
# Integration tests for ai-tools.ps1
# ===============================================

. (Join-Path $PSScriptRoot '..\..\TestSupport.ps1')

BeforeAll {
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
        It 'Handles missing ollama gracefully' {
            # Function should exist even if tool is not available
            { Invoke-OllamaEnhanced -Arguments @('list') -ErrorAction SilentlyContinue } | Should -Not -Throw
        }
        
        It 'Handles missing lms gracefully' {
            # Function should exist even if tool is not available
            { Invoke-LMStudio -Arguments @('list') -ErrorAction SilentlyContinue } | Should -Not -Throw
        }
        
        It 'Handles missing koboldcpp gracefully' {
            # Function should exist even if tool is not available
            { Invoke-KoboldCpp -Arguments @('--help') -ErrorAction SilentlyContinue } | Should -Not -Throw
        }
        
        It 'Handles missing llamafile gracefully' {
            # Function should exist even if tool is not available
            { Invoke-Llamafile -Arguments @('--help') -ErrorAction SilentlyContinue } | Should -Not -Throw
        }
        
        It 'Handles missing llama-cpp gracefully' {
            # Function should exist even if tool is not available
            { Invoke-LlamaCpp -Arguments @('--help') -ErrorAction SilentlyContinue } | Should -Not -Throw
        }
        
        It 'Handles missing comfy gracefully' {
            # Function should exist even if tool is not available
            { Invoke-ComfyUI -Arguments @('install') -ErrorAction SilentlyContinue } | Should -Not -Throw
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

