

Describe 'File Listing Functions Integration Tests' {
    BeforeAll {
        $testSupportPath = Get-TestSupportPath -StartPath $PSScriptRoot
        if (-not (Test-Path -LiteralPath $testSupportPath)) {
            throw "TestSupport file not found at: $testSupportPath"
        }
        . $testSupportPath

        $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
        Initialize-TestProfile -ProfileDir $script:ProfileDir -LoadBootstrap

        $listingModule = Join-Path $script:ProfileDir 'files-modules' 'navigation' 'files-listing.ps1'
        if (-not (Test-Path -LiteralPath $listingModule)) {
            throw "File listing module not found at: $listingModule"
        }
        $null = . $listingModule

        # Avoid eza --git / bat in tests (can hang or block on large repos / TTY).
        Set-TestCommandAvailabilityState -CommandName 'eza' -Available $false
        Set-TestCommandAvailabilityState -CommandName 'bat' -Available $false
    }

    Context 'File listing functions' {
        It 'Get-ChildItemDetailed (ll) function is available' {
            Get-Command Get-ChildItemDetailed -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            (Get-Command ll -ErrorAction SilentlyContinue).ResolvedCommandName | Should -Be 'Get-ChildItemDetailed'
        }

        It 'Get-ChildItemAll (la) function is available' {
            Get-Command Get-ChildItemAll -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            (Get-Command la -ErrorAction SilentlyContinue).ResolvedCommandName | Should -Be 'Get-ChildItemAll'
        }

        It 'Get-ChildItemVisible (lx) function is available' {
            Get-Command Get-ChildItemVisible -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            (Get-Command lx -ErrorAction SilentlyContinue).ResolvedCommandName | Should -Be 'Get-ChildItemVisible'
        }

        It 'Get-DirectoryTree (tree) function is available' {
            Get-Command Get-DirectoryTree -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            $treeCommand = Get-Command tree -ErrorAction SilentlyContinue
            if ($treeCommand -and $treeCommand.CommandType -eq 'Application') {
                Set-ItResult -Inconclusive -Because 'A system tree executable shadows the profile tree alias on this platform'
            }
            else {
                $treeCommand.ResolvedCommandName | Should -Be 'Get-DirectoryTree'
            }
        }

        It 'Show-FileContent (bat-cat) function is available' {
            Get-Command Show-FileContent -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            (Get-Command bat-cat -ErrorAction SilentlyContinue).ResolvedCommandName | Should -Be 'Show-FileContent'
        }

        It 'Get-ChildItemDetailed lists directory contents' {
            try {
            $testDir = Join-Path $TestDrive 'test_listing'
            New-Item -ItemType Directory -Path $testDir -Force | Out-Null
            New-Item -ItemType File -Path (Join-Path $testDir 'test.txt') -Force | Out-Null

            Push-Location $testDir
                        { Get-ChildItemDetailed | Out-Null } | Should -Not -Throw
            }
            finally {
                Pop-Location
            }
        }

        It 'Get-DirectoryTree displays directory structure' {
            try {
            $testDir = Join-Path $TestDrive 'test_tree'
            New-Item -ItemType Directory -Path $testDir -Force | Out-Null
            New-Item -ItemType Directory -Path (Join-Path $testDir 'subdir') -Force | Out-Null
            New-Item -ItemType File -Path (Join-Path $testDir 'file.txt') -Force | Out-Null

            Push-Location $testDir
                        { Get-DirectoryTree | Out-Null } | Should -Not -Throw
            }
            finally {
                Pop-Location
            }
        }

        It 'Show-FileContent handles file input' {
            $testFile = Join-Path $TestDrive 'test_content.txt'
            Set-Content -Path $testFile -Value 'test content'

            { Show-FileContent $testFile | Out-Null } | Should -Not -Throw
        }
    }
}
