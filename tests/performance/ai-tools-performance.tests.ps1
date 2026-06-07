# ===============================================
# ai-tools-performance.tests.ps1
# Performance tests for ai-tools.ps1
# ===============================================

BeforeAll {
    . (Join-Path $PSScriptRoot '..\TestSupport.ps1')
    $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
    $script:AiToolsPath = Join-Path $script:ProfileDir 'ai-tools.ps1'
    Initialize-FragmentPerformanceThresholds -Prefix 'AI_TOOLS'

    . (Join-Path $script:ProfileDir 'bootstrap.ps1')
    
    # Load the fragment
    . $script:AiToolsPath -ErrorAction SilentlyContinue
}

Describe 'ai-tools.ps1 - Performance Tests' {
    Context 'Fragment Load Time' {
        It 'Loads fragment in under 500ms' {
            $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
            . $script:AiToolsPath -ErrorAction SilentlyContinue
            $stopwatch.Stop()
            
            $stopwatch.ElapsedMilliseconds | Should -BeLessThan $script:MaxFragmentLoadTimeMs
        }
    }
    
    Context 'Function Registration' {
        It 'Functions are registered quickly' {
            $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
            
            $functions = @(
                'Invoke-OllamaEnhanced',
                'Invoke-LMStudio',
                'Invoke-KoboldCpp',
                'Invoke-Llamafile',
                'Invoke-LlamaCpp',
                'Invoke-ComfyUI'
            )
            
            foreach ($func in $functions) {
                Get-Command $func -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            }
            
            $stopwatch.Stop()
            $stopwatch.ElapsedMilliseconds | Should -BeLessThan $script:MaxFunctionExecTimeMs
        }
    }
    
    Context 'Alias Resolution' {
        It 'Alias resolution is fast' {
            # Ensure fragment is loaded
            . $script:AiToolsPath -ErrorAction SilentlyContinue
            
            # Ensure aliases exist
            $aliasMappings = @{
                'ollama-enhanced' = 'Invoke-OllamaEnhanced'
                'lms'             = 'Invoke-LMStudio'
                'koboldcpp'       = 'Invoke-KoboldCpp'
                'llamafile'       = 'Invoke-Llamafile'
                'llama-cpp'       = 'Invoke-LlamaCpp'
                'comfy'           = 'Invoke-ComfyUI'
            }
            
            foreach ($aliasName in $aliasMappings.Keys) {
                if (-not (Get-Alias $aliasName -ErrorAction SilentlyContinue)) {
                    if (Get-Command Set-AgentModeAlias -ErrorAction SilentlyContinue) {
                        Set-AgentModeAlias -Name $aliasName -Target $aliasMappings[$aliasName] | Out-Null
                    }
                }
            }
            
            $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
            
            foreach ($aliasName in $aliasMappings.Keys) {
                $resolved = Get-Alias $aliasName -ErrorAction SilentlyContinue
                if ($resolved) {
                    $resolved | Should -Not -BeNullOrEmpty
                }
            }

            $stopwatch.Stop()
            $stopwatch.ElapsedMilliseconds | Should -BeLessThan $script:MaxLookupTimeMs
        }
    }
    
    Context 'Idempotency Performance' {
        It 'Repeated loading is fast' {
            # Load once
            . $script:AiToolsPath -ErrorAction SilentlyContinue
            
            # Load again and measure
            $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
            . $script:AiToolsPath -ErrorAction SilentlyContinue
            $stopwatch.Stop()
            
            # Idempotent loading should be very fast
            $stopwatch.ElapsedMilliseconds | Should -BeLessThan $script:MaxFragmentLoadTimeMs
        }
    }
}

