. (Join-Path $PSScriptRoot '..\TestSupport.ps1')

BeforeAll {
    $script:RepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:LibPath = Get-TestPath -RelativePath 'scripts\lib' -StartPath $PSScriptRoot -EnsureExists
    $script:ParallelPath = Join-Path $script:LibPath 'parallel' 'Parallel.psm1'
    
    # Import the module under test
    Import-Module $script:ParallelPath -DisableNameChecking -ErrorAction Stop -Force
}

AfterAll {
    Remove-Module Parallel -ErrorAction SilentlyContinue -Force
    
    # Clean up any remaining jobs
    Get-Job | Remove-Job -Force -ErrorAction SilentlyContinue
}

Describe 'Parallel Module Functions' {
    Context 'Invoke-Parallel' {
        It 'Returns empty array for empty input' {
            $result = @() | Invoke-Parallel -ScriptBlock { $_ }
            $result | Should -Not -BeNull
            $result | Should -BeOfType [array]
            $result.Count | Should -Be 0
        }

        It 'Processes single item' {
            $items = @(1)
            $result = $items | Invoke-Parallel -ScriptBlock { $_ * 2 }
            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -Be 1
            $result[0] | Should -Be 2
        }

        It 'Processes multiple items' {
            $items = @(1, 2, 3, 4, 5)
            $result = $items | Invoke-Parallel -ScriptBlock { $_ * 2 }
            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -Be 5
            $result | Should -Contain 2
            $result | Should -Contain 4
            $result | Should -Contain 6
            $result | Should -Contain 8
            $result | Should -Contain 10
        }

        It 'Respects ThrottleLimit' {
            $items = @(1..10)
            $result = $items | Invoke-Parallel -ScriptBlock { Start-Sleep -Milliseconds 100; $_ } -ThrottleLimit 2
            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -Be 10
        }

        It 'Handles scriptblock with parameters' {
            $items = @(1, 2, 3)
            $scriptBlock = { param($item) $item * 2 }
            $result = $items | Invoke-Parallel -ScriptBlock $scriptBlock
            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -Be 3
        }

        It 'Handles scriptblock using $_' {
            $items = @(1, 2, 3)
            $scriptBlock = { $_ * 3 }
            $result = $items | Invoke-Parallel -ScriptBlock $scriptBlock
            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -Be 3
        }

        It 'Handles scriptblock using $PSItem' {
            $items = @(1, 2, 3)
            $scriptBlock = { $PSItem * 4 }
            $result = $items | Invoke-Parallel -ScriptBlock $scriptBlock
            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -Be 3
        }

        It 'Handles errors gracefully' {
            $items = @(1, 2, 3)
            $scriptBlock = { 
                if ($_ -eq 2) { throw "Error for item 2" }
                $_
            }
            # Should not throw, but may have warnings
            { $items | Invoke-Parallel -ScriptBlock $scriptBlock } | Should -Not -Throw
        }

        It 'Accepts TimeoutSeconds parameter' {
            $items = @(1, 2, 3)
            $result = $items | Invoke-Parallel -ScriptBlock { $_ } -TimeoutSeconds 60
            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -Be 3
        }

        It 'Processes string items' {
            $items = @('a', 'b', 'c')
            $result = $items | Invoke-Parallel -ScriptBlock { $_.ToUpper() }
            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -Be 3
            $result | Should -Contain 'A'
            $result | Should -Contain 'B'
            $result | Should -Contain 'C'
        }

        It 'Processes objects' {
            $items = @(
                [PSCustomObject]@{ Name = 'Item1'; Value = 1 },
                [PSCustomObject]@{ Name = 'Item2'; Value = 2 }
            )
            $result = $items | Invoke-Parallel -ScriptBlock { $_.Name }
            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -Be 2
            $result | Should -Contain 'Item1'
            $result | Should -Contain 'Item2'
        }
    }
}

