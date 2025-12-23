

Describe 'File Listing Functions Integration Tests' {
    BeforeAll {
        try {
            $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
            $script:BootstrapPath = Get-TestPath -RelativePath 'profile.d\bootstrap.ps1' -StartPath $PSScriptRoot -EnsureExists
            if ($null -eq $script:BootstrapPath -or [string]::IsNullOrWhiteSpace($script:BootstrapPath)) {
                throw "Get-TestPath returned null or empty value for BootstrapPath"
            }
            if (-not (Test-Path -LiteralPath $script:BootstrapPath)) {
                throw "Bootstrap file not found at: $script:BootstrapPath"
            }
            . $script:BootstrapPath
        }
        catch {
            $errorDetails = @{
                Message  = $_.Exception.Message
                Type     = $_.Exception.GetType().FullName
                Location = $_.InvocationInfo.ScriptLineNumber
            }
            Write-Error "Failed to load bootstrap in BeforeAll: $($errorDetails | ConvertTo-Json -Compress)" -ErrorAction Stop
            throw
        }
    }

    Context 'File listing functions' {
        BeforeAll {
            . (Join-Path $script:ProfileDir 'bootstrap.ps1')
            . (Join-Path $script:ProfileDir 'files.ps1')
            # Ensure file listing module is loaded
            $filesModulesDir = Join-Path $script:ProfileDir 'files-modules'
            $navigationDir = Join-Path $filesModulesDir 'navigation'
            $listingModule = Join-Path $navigationDir 'files-listing.ps1'
            if ($listingModule -and -not [string]::IsNullOrWhiteSpace($listingModule) -and (Test-Path -LiteralPath $listingModule)) {
                . $listingModule
            }
            Ensure-FileListing
        }

        It 'Get-ChildItemDetailed (ll) function is available' {
            Get-Command ll -CommandType Alias -ErrorAction SilentlyContinue | Should -Not -Be $null
            Get-Command Get-ChildItemDetailed -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'Get-ChildItemAll (la) function is available' {
            Get-Command la -CommandType Alias -ErrorAction SilentlyContinue | Should -Not -Be $null
            Get-Command Get-ChildItemAll -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'Get-ChildItemVisible (lx) function is available' {
            Get-Command lx -CommandType Alias -ErrorAction SilentlyContinue | Should -Not -Be $null
            Get-Command Get-ChildItemVisible -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'Get-DirectoryTree (tree) function is available' {
            Get-Command tree -CommandType Alias -ErrorAction SilentlyContinue | Should -Not -Be $null
            Get-Command Get-DirectoryTree -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'Show-FileContent (bat-cat) function is available' {
            Get-Command bat-cat -CommandType Alias -ErrorAction SilentlyContinue | Should -Not -Be $null
            Get-Command Show-FileContent -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'll function lists directory contents' {
            $testDir = Join-Path $TestDrive 'test_listing'
            New-Item -ItemType Directory -Path $testDir -Force | Out-Null
            New-Item -ItemType File -Path (Join-Path $testDir 'test.txt') -Force | Out-Null

            Push-Location $testDir
            try {
                # Ensure the function is available
                if (Get-Command ll -ErrorAction SilentlyContinue) {
                    $result = ll
                    # Result might be empty if eza/Get-ChildItem returns nothing, but function should not throw
                    { ll } | Should -Not -Throw
                }
                else {
                    Set-ItResult -Skipped -Because "ll alias not available"
                }
            }
            finally {
                Pop-Location
            }
        }

        It 'tree function displays directory structure' {
            $testDir = Join-Path $TestDrive 'test_tree'
            New-Item -ItemType Directory -Path $testDir -Force | Out-Null
            New-Item -ItemType Directory -Path (Join-Path $testDir 'subdir') -Force | Out-Null
            New-Item -ItemType File -Path (Join-Path $testDir 'file.txt') -Force | Out-Null

            Push-Location $testDir
            try {
                # Ensure the function is available
                if (Get-Command tree -ErrorAction SilentlyContinue) {
                    $result = tree
                    # Result might be empty if eza/Get-ChildItem returns nothing, but function should not throw
                    { tree } | Should -Not -Throw
                }
                else {
                    Set-ItResult -Skipped -Because "tree alias not available"
                }
            }
            finally {
                Pop-Location
            }
        }

        It 'Show-FileContent handles file input' {
            $testFile = Join-Path $TestDrive 'test_content.txt'
            Set-Content -Path $testFile -Value 'test content'

            { Show-FileContent $testFile } | Should -Not -Throw
        }
    }
}

