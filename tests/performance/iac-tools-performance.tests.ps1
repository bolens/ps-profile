# ===============================================
# iac-tools-performance.tests.ps1
# Performance tests for terraform.ps1 fragment
# ===============================================

BeforeAll {
    . (Join-Path $PSScriptRoot '..\TestSupport.ps1')
    $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
    $script:TerraformPath = Join-Path $script:ProfileDir 'terraform.ps1'
    $script:MaxFragmentLoadTimeMs = Get-PerformanceThreshold -EnvironmentVariable 'PS_PROFILE_TERRAFORM_MAX_LOAD_MS' -Default 3000
    $script:MaxRepeatLoadTimeMs = Get-PerformanceThreshold -EnvironmentVariable 'PS_PROFILE_TERRAFORM_MAX_REPEAT_LOAD_MS' -Default 2500
    $script:MaxFunctionCheckTimeMs = Get-PerformanceThreshold -EnvironmentVariable 'PS_PROFILE_TERRAFORM_MAX_FUNCTION_MS' -Default 1000

    . (Join-Path $script:ProfileDir 'bootstrap.ps1')
    . (Join-Path $script:ProfileDir 'env.ps1')
}

Describe 'terraform.ps1 - Performance Tests' {
    Context 'Fragment Load Time' {
        It 'Loads fragment in under threshold' {
            $sw = [System.Diagnostics.Stopwatch]::StartNew()
            . $script:TerraformPath
            $sw.Stop()

            $sw.ElapsedMilliseconds | Should -BeLessThan $script:MaxFragmentLoadTimeMs
        }

        It 'Loads fragment consistently across multiple loads' {
            $times = @()
            for ($i = 0; $i -lt 3; $i++) {
                $sw = [System.Diagnostics.Stopwatch]::StartNew()
                . $script:TerraformPath
                $sw.Stop()
                $times += $sw.ElapsedMilliseconds
            }

            $times | ForEach-Object { $_ | Should -BeLessThan $script:MaxRepeatLoadTimeMs }
        }
    }

    Context 'Function Registration Performance' {
        BeforeAll {
            . $script:TerraformPath
        }

        It 'Registers all functions quickly' {
            $sw = [System.Diagnostics.Stopwatch]::StartNew()

            $functions = @(
                'Invoke-Terraform',
                'Get-TerraformPlan',
                'Invoke-TerraformApply'
            )

            foreach ($func in $functions) {
                Get-Command -Name $func -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            }

            $sw.Stop()
            $sw.ElapsedMilliseconds | Should -BeLessThan $script:MaxFunctionCheckTimeMs
        }
    }

    Context 'Idempotency Check Overhead' {
        It 'Idempotency check has minimal overhead' {
            . $script:TerraformPath

            $sw = [System.Diagnostics.Stopwatch]::StartNew()
            . $script:TerraformPath
            $sw.Stop()

            $sw.ElapsedMilliseconds | Should -BeLessThan $script:MaxRepeatLoadTimeMs
        }
    }
}
