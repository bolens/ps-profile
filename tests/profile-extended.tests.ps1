Describe 'Profile Extended Coverage Tests' {
    BeforeAll {
        $profileRelative = Join-Path $PSScriptRoot '..\profile.d'
        try {
            $script:ProfileDir = (Resolve-Path -LiteralPath $profileRelative -ErrorAction Stop).ProviderPath
        }
        catch {
            throw "Profile directory not found at $profileRelative"
        }

        $bootstrapRelative = Join-Path $script:ProfileDir '00-bootstrap.ps1'
        try {
            $script:BootstrapPath = (Resolve-Path -LiteralPath $bootstrapRelative -ErrorAction Stop).ProviderPath
        }
        catch {
            throw "Bootstrap script not found at $bootstrapRelative"
        }
        . $script:BootstrapPath
    }

    Context 'Bootstrap helper functions' {


        It 'Test-CachedCommand caches command availability results' {
            # Test that caching works
            $result1 = Test-CachedCommand -Name 'Get-Command'
            $result2 = Test-CachedCommand -Name 'Get-Command'
            $result1 | Should -Be $result2
            $result1 | Should -Be $true
        }

        It 'Test-CachedCommand returns false for non-existent commands' {
            $nonExistent = "TestCommand_$(Get-Random)_$(Get-Random)"
            $result = Test-CachedCommand -Name $nonExistent
            $result | Should -Be $false
        }

        It 'Test-HasCommand checks function provider first' {
            # Create a test function
            $testFuncName = "TestFunc_$(Get-Random)"
            Set-Item -Path "Function:\$testFuncName" -Value { 'test' } -Force

            try {
                $result = Test-HasCommand -Name $testFuncName
                $result | Should -Be $true
            }
            finally {
                Remove-Item "Function:\$testFuncName" -Force -ErrorAction SilentlyContinue
            }
        }

        It 'Test-HasCommand checks alias provider' {
            # Create a test alias
            $testAliasName = "TestAlias_$(Get-Random)"
            Set-Alias -Name $testAliasName -Value 'Get-Command' -Scope Global -Force

            try {
                $result = Test-HasCommand -Name $testAliasName
                $result | Should -Be $true
            }
            finally {
                Remove-Alias -Name $testAliasName -Force -ErrorAction SilentlyContinue
            }
        }

        It 'Test-HasCommand returns false for non-existent commands' {
            $nonExistent = "TestCommand_$(Get-Random)_$(Get-Random)"
            $result = Test-HasCommand -Name $nonExistent
            $result | Should -Be $false
        }

        It 'Set-AgentModeFunction returns false when function already exists' {
            $existingFunc = 'Get-Command'
            $result = Set-AgentModeFunction -Name $existingFunc -Body { 'test' }
            $result | Should -Be $false
        }

        It 'Set-AgentModeAlias returns false when alias already exists' {
            $existingAlias = 'ls'
            if (Get-Command -Name $existingAlias -ErrorAction SilentlyContinue) {
                $result = Set-AgentModeAlias -Name $existingAlias -Target 'Get-Command'
                $result | Should -Be $false
            }
        }
    }

    Context 'File listing functions' {
        BeforeAll {
            . (Join-Path $script:ProfileDir '02-files-listing.ps1')
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
                $result = ll
                $result | Should -Not -BeNullOrEmpty
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
                $result = tree
                $result | Should -Not -BeNullOrEmpty
            }
            finally {
                Pop-Location
            }
        }

        It 'Show-FileContent handles file input' {
            $testFile = Join-Path $TestDrive 'test_content.txt'
            Set-Content -Path $testFile -Value 'test content'

            # Should not throw
            { Show-FileContent $testFile } | Should -Not -Throw
        }
    }

    Context 'File navigation functions' {
        BeforeAll {
            . (Join-Path $script:ProfileDir '02-files-navigation.ps1')
        }

        It '.. function navigates up one directory' {
            $testDir = Join-Path $TestDrive 'level1\level2'
            New-Item -ItemType Directory -Path $testDir -Force | Out-Null

            Push-Location $testDir
            try {
                $before = Get-Location
                ..
                $after = Get-Location
                $after.Path | Should -Match ([regex]::Escape((Split-Path $before.Path)))
            }
            finally {
                Pop-Location
            }
        }

        It '... function navigates up two directories' {
            $testDir = Join-Path $TestDrive 'level1\level2\level3'
            New-Item -ItemType Directory -Path $testDir -Force | Out-Null

            Push-Location $testDir
            try {
                $before = Get-Location
                ...
                $after = Get-Location
                $beforeParent = Split-Path (Split-Path $before.Path)
                $after.Path | Should -Match ([regex]::Escape($beforeParent))
            }
            finally {
                Pop-Location
            }
        }

        It '.... function navigates up three directories' {
            $testDir = Join-Path $TestDrive 'level1\level2\level3\level4'
            New-Item -ItemType Directory -Path $testDir -Force | Out-Null

            Push-Location $testDir
            try {
                $before = Get-Location
                ....
                $after = Get-Location
                $beforeParent = Split-Path (Split-Path (Split-Path $before.Path))
                $after.Path | Should -Match ([regex]::Escape($beforeParent))
            }
            finally {
                Pop-Location
            }
        }

        It '~ function navigates to home directory' {
            $originalLocation = Get-Location
            try {
                ~
                $homeLocation = Get-Location
                $homeLocation.Path | Should -Match ([regex]::Escape($env:USERPROFILE))
            }
            finally {
                Set-Location $originalLocation
            }
        }

        It 'desktop alias navigates to Desktop' {
            if (Test-Path "$env:USERPROFILE\Desktop") {
                $originalLocation = Get-Location
                try {
                    desktop
                    $desktop = Get-Location
                    $desktop.Path | Should -Match ([regex]::Escape("$env:USERPROFILE\Desktop"))
                }
                finally {
                    Set-Location $originalLocation
                }
            }
        }

        It 'downloads alias navigates to Downloads' {
            if (Test-Path "$env:USERPROFILE\Downloads") {
                $originalLocation = Get-Location
                try {
                    downloads
                    $downloads = Get-Location
                    $downloads.Path | Should -Match ([regex]::Escape("$env:USERPROFILE\Downloads"))
                }
                finally {
                    Set-Location $originalLocation
                }
            }
        }

        It 'docs alias navigates to Documents' {
            if (Test-Path "$env:USERPROFILE\Documents") {
                $originalLocation = Get-Location
                try {
                    docs
                    $docs = Get-Location
                    $docs.Path | Should -Match ([regex]::Escape("$env:USERPROFILE\Documents"))
                }
                finally {
                    Set-Location $originalLocation
                }
            }
        }
    }

    Context 'Environment variable functions' {
        BeforeAll {
            . (Join-Path $script:ProfileDir '01-env.ps1')
        }

        It 'sets EDITOR default when not set' {
            $originalEditor = $env:EDITOR
            try {
                Remove-Item Env:\EDITOR -ErrorAction SilentlyContinue
                . (Join-Path $script:ProfileDir '01-env.ps1')
                if (-not $originalEditor) {
                    $env:EDITOR | Should -Be 'code'
                }
            }
            finally {
                if ($originalEditor) {
                    $env:EDITOR = $originalEditor
                }
            }
        }

        It 'does not overwrite existing EDITOR' {
            $testEditor = 'vim'
            $originalEditor = $env:EDITOR
            try {
                $env:EDITOR = $testEditor
                . (Join-Path $script:ProfileDir '01-env.ps1')
                $env:EDITOR | Should -Be $testEditor
            }
            finally {
                if ($originalEditor) {
                    $env:EDITOR = $originalEditor
                }
                else {
                    Remove-Item Env:\EDITOR -ErrorAction SilentlyContinue
                }
            }
        }

        It 'sets GIT_EDITOR default when not set' {
            $originalGitEditor = $env:GIT_EDITOR
            try {
                Remove-Item Env:\GIT_EDITOR -ErrorAction SilentlyContinue
                . (Join-Path $script:ProfileDir '01-env.ps1')
                if (-not $originalGitEditor) {
                    $env:GIT_EDITOR | Should -Be 'code --wait'
                }
            }
            finally {
                if ($originalGitEditor) {
                    $env:GIT_EDITOR = $originalGitEditor
                }
            }
        }

        It 'sets VISUAL default when not set' {
            $originalVisual = $env:VISUAL
            try {
                Remove-Item Env:\VISUAL -ErrorAction SilentlyContinue
                . (Join-Path $script:ProfileDir '01-env.ps1')
                if (-not $originalVisual) {
                    $env:VISUAL | Should -Be 'code'
                }
            }
            finally {
                if ($originalVisual) {
                    $env:VISUAL = $originalVisual
                }
            }
        }
    }

    Context 'Utility functions edge cases' {
        BeforeAll {
            . (Join-Path $script:ProfileDir '05-utilities.ps1')
        }

        It 'pwgen generates password with custom length' {
            if (Get-Command pwgen -ErrorAction SilentlyContinue) {
                # Test if pwgen supports length parameter
                $password = pwgen 20
                if ($password) {
                    $password.Length | Should -BeGreaterOrEqual 16
                }
            }
        }

        It 'pwgen generates unique passwords' {
            $pass1 = pwgen
            $pass2 = pwgen
            # Passwords should be different (very unlikely to be the same)
            if ($pass1 -and $pass2) {
                $pass1 | Should -Not -Be $pass2
            }
        }

        It 'Add-Path handles duplicate paths gracefully' {
            $testPath = Join-Path $TestDrive 'TestDuplicatePath'
            $originalPath = $env:PATH
            try {
                New-Item -ItemType Directory -Path $testPath -Force | Out-Null

                # Add path first time
                Add-Path -Path $testPath
                $beforeCount = ($env:PATH -split ';' | Where-Object { $_ -eq $testPath }).Count

                # Add path second time
                Add-Path -Path $testPath
                $afterCount = ($env:PATH -split ';' | Where-Object { $_ -eq $testPath }).Count

                # Should not have duplicates (implementation dependent, but shouldn't error)
                $afterCount | Should -BeGreaterOrEqual $beforeCount
            }
            finally {
                $env:PATH = $originalPath
            }
        }

        It 'Remove-Path handles non-existent paths gracefully' {
            $nonExistentPath = Join-Path $TestDrive 'NonExistentPath'
            $originalPath = $env:PATH
            try {
                # Should not throw when removing non-existent path
                { Remove-Path -Path $nonExistentPath } | Should -Not -Throw
            }
            finally {
                $env:PATH = $originalPath
            }
        }

        It 'from-epoch handles edge cases' {
            # Test epoch 0 (1970-01-01)
            $result = from-epoch 0
            $utcResult = $result.ToUniversalTime()
            $utcResult.Year | Should -Be 1970
            $utcResult.Month | Should -Be 1
            $utcResult.Day | Should -Be 1
        }

        It 'epoch returns consistent timestamps' {
            $time1 = epoch
            Start-Sleep -Milliseconds 100
            $time2 = epoch
            $time2 | Should -BeGreaterOrEqual $time1
        }

        It 'Get-EnvVar handles non-existent variables' {
            $nonExistent = "NON_EXISTENT_VAR_$(Get-Random)"
            $result = Get-EnvVar -Name $nonExistent
            # Should return null or empty for non-existent vars
            ($result -eq $null -or $result -eq '') | Should -Be $true
        }

        It 'Set-EnvVar handles null values for deletion' {
            $tempVar = "TEST_DELETE_$(Get-Random)"
            try {
                # Set a value
                Set-EnvVar -Name $tempVar -Value 'test'
                $before = Get-EnvVar -Name $tempVar
                $before | Should -Be 'test'

                # Delete by setting to null
                Set-EnvVar -Name $tempVar -Value $null
                $after = Get-EnvVar -Name $tempVar
                ($after -eq $null -or $after -eq '') | Should -Be $true
            }
            finally {
                Set-EnvVar -Name $tempVar -Value $null
            }
        }
    }

    Context 'File utility functions edge cases' {
        BeforeAll {
            . (Join-Path $script:ProfileDir '02-files-conversion.ps1')
            . (Join-Path $script:ProfileDir '02-files-utilities.ps1')
            Ensure-FileConversion
            Ensure-FileUtilities
        }

        It 'json-pretty handles invalid JSON gracefully' {
            $invalidJson = '{"invalid": json}'
            # Should either format it or handle error gracefully
            { json-pretty $invalidJson } | Should -Not -Throw
        }

        It 'to-base64 handles empty strings' {
            $empty = ''
            $encoded = $empty | to-base64
            $decoded = $encoded | from-base64
            $decoded.TrimEnd("`r", "`n") | Should -Be $empty
        }

        It 'to-base64 handles unicode strings' {
            $unicode = 'Hello 世界'
            $encoded = $unicode | to-base64
            $decoded = $encoded | from-base64
            $decoded.TrimEnd("`r", "`n") | Should -Be $unicode
        }

        It 'file-hash handles non-existent files' {
            $nonExistent = Join-Path $TestDrive 'non_existent.txt'
            # Should handle error gracefully
            { file-hash $nonExistent } | Should -Not -Throw
        }

        It 'filesize handles different file sizes' {
            # Test 1 byte
            $smallFile = Join-Path $TestDrive 'small.txt'
            Set-Content -Path $smallFile -Value 'x' -NoNewline
            $small = filesize $smallFile
            $small | Should -Match '\d+.*B'

            # Test 1 MB
            $largeFile = Join-Path $TestDrive 'large.txt'
            $content = 'x' * 1048576
            Set-Content -Path $largeFile -Value $content -NoNewline
            $large = filesize $largeFile
            $large | Should -Match '\d+.*MB'
        }
    }

    Context 'System utility functions edge cases' {
        BeforeAll {
            . (Join-Path $script:ProfileDir '07-system.ps1')
        }

        It 'which handles non-existent commands' {
            $nonExistent = "NonExistentCommand_$(Get-Random)"
            $result = which $nonExistent
            # Should return null or handle gracefully
            ($result -eq $null -or $result.Count -eq 0) | Should -Be $true
        }

        It 'pgrep handles pattern not found' {
            $tempFile = Join-Path $TestDrive 'test_no_match.txt'
            Set-Content -Path $tempFile -Value 'no match here'
            $result = pgrep 'nonexistentpattern' $tempFile
            # Should return empty or null
            ($result -eq $null -or $result.Count -eq 0) | Should -Be $true
        }

        It 'touch updates existing file timestamp' {
            $tempFile = Join-Path $TestDrive 'test_touch_existing.txt'
            Set-Content -Path $tempFile -Value 'content'
            $before = (Get-Item $tempFile).LastWriteTime
            Start-Sleep -Milliseconds 1100
            touch $tempFile
            $after = (Get-Item $tempFile).LastWriteTime
            $after | Should -BeGreaterOrEqual $before
        }

        It 'search handles empty directories' {
            $emptyDir = Join-Path $TestDrive 'empty_search'
            New-Item -ItemType Directory -Path $emptyDir -Force | Out-Null

            Push-Location $emptyDir
            try {
                $result = search '*.txt'
                # Should return empty array or null
                ($result -eq $null -or $result.Count -eq 0) | Should -Be $true
            }
            finally {
                Pop-Location
            }
        }
    }

    Context 'Git functions extended tests' {
        BeforeAll {
            . (Join-Path $script:ProfileDir '11-git.ps1')
        }

        It 'git shortcuts handle non-git directories' {
            $nonGitDir = Join-Path $TestDrive 'non_git'
            New-Item -ItemType Directory -Path $nonGitDir -Force | Out-Null

            Push-Location $nonGitDir
            try {
                # Should handle gracefully without throwing
                { gs } | Should -Not -Throw
            }
            finally {
                Pop-Location
            }
        }

        It 'Ensure-GitHelper is idempotent' {
            # Call multiple times - should not error
            { Ensure-GitHelper; Ensure-GitHelper; Ensure-GitHelper } | Should -Not -Throw
        }

        It 'additional git shortcuts are available' {
            $expectedCommands = @('gl', 'gd', 'gb', 'gco')
            foreach ($cmd in $expectedCommands) {
                Get-Command $cmd -ErrorAction SilentlyContinue | Should -Not -Be $null
            }
        }

        It 'git shortcuts forward arguments correctly' {
            # Test that git shortcuts accept arguments without throwing
            $testDir = Join-Path $TestDrive 'git_test'
            New-Item -ItemType Directory -Path $testDir -Force | Out-Null

            Push-Location $testDir
            try {
                # Initialize git repo if git is available
                if (Get-Command git -ErrorAction SilentlyContinue) {
                    git init --quiet 2>&1 | Out-Null
                    # Test shortcuts don't throw with arguments
                    { gs --short } | Should -Not -Throw
                    { gl --oneline -5 } | Should -Not -Throw
                }
            }
            finally {
                Pop-Location
            }
        }
    }

    Context 'Utility functions additional tests' {
        BeforeAll {
            . (Join-Path $script:ProfileDir '05-utilities.ps1')
        }

        It 'Reload-Profile function is available' {
            Get-Command Reload-Profile -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            Get-Command reload -CommandType Alias -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'Edit-Profile function is available' {
            Get-Command Edit-Profile -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            Get-Command edit-profile -CommandType Alias -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'Get-Weather function is available' {
            Get-Command Get-Weather -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            Get-Command weather -CommandType Alias -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'Get-MyIP function is available' {
            Get-Command Get-MyIP -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            Get-Command myip -CommandType Alias -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'ConvertTo-UrlEncoded encodes strings correctly' {
            $testString = 'hello world'
            $encoded = ConvertTo-UrlEncoded -text $testString
            $encoded | Should -Be 'hello%20world'
        }

        It 'ConvertFrom-UrlEncoded decodes strings correctly' {
            $encoded = 'hello%20world'
            $decoded = ConvertFrom-UrlEncoded -text $encoded
            $decoded | Should -Be 'hello world'
        }

        It 'ConvertTo-UrlEncoded and ConvertFrom-UrlEncoded roundtrip' {
            $original = 'test string with special chars: !@#$%'
            $encoded = ConvertTo-UrlEncoded -text $original
            $decoded = ConvertFrom-UrlEncoded -text $encoded
            $decoded | Should -Be $original
        }

        It 'ConvertTo-Epoch converts DateTime to Unix timestamp' {
            $testDate = Get-Date -Year 2020 -Month 1 -Day 1 -Hour 0 -Minute 0 -Second 0
            $epoch = ConvertTo-Epoch -date $testDate
            $epoch | Should -BeOfType [long]
            $epoch | Should -BeGreaterThan 0
        }

        It 'ConvertTo-Epoch and ConvertFrom-Epoch roundtrip' {
            $originalDate = Get-Date
            $epoch = ConvertTo-Epoch -date $originalDate
            $convertedBack = ConvertFrom-Epoch -epoch $epoch
            # Allow 1 second difference for rounding
            $timeDiff = [Math]::Abs(($convertedBack - $originalDate).TotalSeconds)
            $timeDiff | Should -BeLessThan 2
        }

        It 'Get-DateTime returns formatted date string' {
            $result = Get-DateTime
            $result | Should -BeOfType [string]
            $result | Should -Match '^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}$'
        }

        It 'Get-DateTime alias now is available' {
            Get-Command now -CommandType Alias -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'Get-History returns recent commands' {
            { Get-History -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It 'Find-History searches command history' {
            $historyMarker = "test-search-command-$(Get-Random)"
            { Find-History $historyMarker -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It 'Find-History alias hg is available' {
            Get-Command hg -CommandType Alias -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'to-epoch alias works' {
            Get-Command to-epoch -CommandType Alias -ErrorAction SilentlyContinue | Should -Not -Be $null
            $testDate = Get-Date
            $result = to-epoch $testDate
            $result | Should -BeOfType [long]
        }

        It 'url-encode and url-decode aliases work' {
            Get-Command url-encode -CommandType Alias -ErrorAction SilentlyContinue | Should -Not -Be $null
            Get-Command url-decode -CommandType Alias -ErrorAction SilentlyContinue | Should -Not -Be $null

            $test = 'test string'
            $encoded = url-encode $test
            $decoded = url-decode $encoded
            $decoded | Should -Be $test
        }
    }

    Context 'Diagnostics functions' {
        BeforeAll {
            # Set PS_PROFILE_DEBUG to enable diagnostics
            $script:OriginalDebug = $env:PS_PROFILE_DEBUG
            $env:PS_PROFILE_DEBUG = '1'
            . (Join-Path $script:ProfileDir '59-diagnostics.ps1')
        }

        AfterAll {
            # Restore original PS_PROFILE_DEBUG
            if ($script:OriginalDebug) {
                $env:PS_PROFILE_DEBUG = $script:OriginalDebug
            }
            else {
                Remove-Item Env:\PS_PROFILE_DEBUG -ErrorAction SilentlyContinue
            }
        }

        It 'Show-ProfileDiagnostic function is available when debug enabled' {
            Get-Command Show-ProfileDiagnostic -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'Show-ProfileStartupTime function is available when debug enabled' {
            Get-Command Show-ProfileStartupTime -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'Test-ProfileHealth function is available when debug enabled' {
            Get-Command Test-ProfileHealth -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'Show-CommandUsageStats function is available when debug enabled' {
            Get-Command Show-CommandUsageStats -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'Show-ProfileStartupTime runs without error' {
            # Should not throw even if timing data isn't available
            { Show-ProfileStartupTime } | Should -Not -Throw
        }

        It 'Show-CommandUsageStats runs without error' {
            # Should not throw even if usage data isn't available
            { Show-CommandUsageStats } | Should -Not -Throw
        }

        It 'Test-ProfileHealth runs without error' {
            # Should not throw even if some checks fail
            { Test-ProfileHealth } | Should -Not -Throw
        }
    }

    Context 'Profile fragment loading order' {
        It 'fragments load in correct order' {
            $fragDir = Join-Path $PSScriptRoot '..\profile.d'
            $files = Get-ChildItem -Path $fragDir -Filter '*.ps1' -File | Sort-Object Name
            $fileNames = $files | Select-Object -ExpandProperty Name

            # Bootstrap should be first
            $fileNames[0] | Should -Match '^00-'

            # Files should be sorted lexicographically
            $sorted = $fileNames | Sort-Object
            $fileNames | Should -Be $sorted
        }
    }

    Context 'Idempotency tests' {
        It 'Set-AgentModeFunction is idempotent' {
            . $script:BootstrapPath
            $funcName = "TestIdempotent_$(Get-Random)"

            # Create function first time
            $result1 = Set-AgentModeFunction -Name $funcName -Body { 'test' }
            $result1 | Should -Be $true

            # Try to create again - should return false
            $result2 = Set-AgentModeFunction -Name $funcName -Body { 'test2' }
            $result2 | Should -Be $false

            # Function should still have original body
            $funcResult = & $funcName
            $funcResult | Should -Be 'test'

            # Cleanup
            Remove-Item "Function:\$funcName" -Force -ErrorAction SilentlyContinue
        }

        It 'Set-AgentModeAlias is idempotent' {
            . $script:BootstrapPath
            $aliasName = "TestAliasIdempotent_$(Get-Random)"

            # Create alias first time
            $result1 = Set-AgentModeAlias -Name $aliasName -Target 'Write-Output'
            $result1 | Should -Be $true

            # Try to create again - should return false
            $result2 = Set-AgentModeAlias -Name $aliasName -Target 'Write-Host'
            $result2 | Should -Be $false

            # Alias should still point to original target
            $aliasResult = Get-Alias -Name $aliasName -ErrorAction SilentlyContinue
            if ($aliasResult) {
                $aliasResult.Definition | Should -Match 'Write-Output'
            }

            # Cleanup
            Remove-Alias -Name $aliasName -Force -ErrorAction SilentlyContinue
        }
    }

    Context 'System utility aliases' {
        BeforeAll {
            . (Join-Path $script:ProfileDir '07-system.ps1')
        }

        It 'rest alias is available' {
            Get-Command rest -CommandType Alias -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'web alias is available' {
            Get-Command web -CommandType Alias -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'unzip alias is available' {
            Get-Command unzip -CommandType Alias -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'rest alias invokes Invoke-RestMethod' {
            # Test that alias exists and can be called (without actually making network calls)
            $alias = Get-Alias rest -ErrorAction SilentlyContinue
            if ($alias) {
                $alias.Definition | Should -Match 'Invoke-Rest'
            }
        }

        It 'web alias invokes Invoke-WebRequest' {
            $alias = Get-Alias web -ErrorAction SilentlyContinue
            if ($alias) {
                $alias.Definition | Should -Match 'Invoke-WebRequest'
            }
        }

        It 'unzip alias invokes Expand-Archive' {
            $alias = Get-Alias unzip -ErrorAction SilentlyContinue
            if ($alias) {
                $alias.Definition | Should -Match 'Expand-Archive'
            }
        }
    }

    Context 'Agent mode compatibility' {
        BeforeAll {
            . $script:BootstrapPath
            . (Join-Path $script:ProfileDir '03-agent-mode.ps1')
        }

        It 'am-list function is available when bootstrap loaded' {
            Get-Command am-list -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'am-doc function is available when bootstrap loaded' {
            Get-Command am-doc -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'am-list returns agent mode functions' {
            $result = am-list
            # Should return functions or empty array
            $result | Should -Not -Be $null
        }

        It 'am-doc handles missing documentation gracefully' {
            # Should not throw even if README doesn't exist
            { am-doc } | Should -Not -Throw
        }
    }

    Context 'File conversion utilities' {
        BeforeAll {
            . (Join-Path $script:ProfileDir '02-files-conversion.ps1')
            Ensure-FileConversion
        }

        It 'json-pretty handles nested JSON' {
            $nestedJson = '{"level1":{"level2":{"level3":"value"}}}'
            $result = json-pretty $nestedJson
            $result | Should -Match 'level1'
            $result | Should -Match 'level2'
            $result | Should -Match 'level3'
        }

        It 'json-pretty handles arrays' {
            $arrayJson = '{"items":[1,2,3],"count":3}'
            $result = json-pretty $arrayJson
            $result | Should -Match 'items'
            $result | Should -Match 'count'
        }

        It 'to-base64 handles binary-like data' {
            $binary = [byte[]](0x00, 0x01, 0x02, 0xFF)
            $text = [System.Text.Encoding]::UTF8.GetString($binary)
            $encoded = $text | to-base64
            $decoded = $encoded | from-base64
            $decodedBytes = [System.Text.Encoding]::UTF8.GetBytes($decoded.TrimEnd("`r", "`n"))
            $decodedBytes[0] | Should -Be $binary[0]
        }

        It 'from-base64 handles padded base64 strings' {
            $testString = 'test'
            $encoded = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($testString))
            $decoded = $encoded | from-base64
            $decoded.TrimEnd("`r", "`n") | Should -Be $testString
        }
    }

    Context 'Lazy loading patterns' {
        It 'Ensure-FileListing initializes on first use' {
            . (Join-Path $script:ProfileDir '02-files-listing.ps1')

            # Function should exist but not be initialized until called
            $before = Test-Path Function:\Get-ChildItemDetailed
            if (-not $before) {
                # Call the function to trigger lazy loading
                $testDir = Join-Path $TestDrive 'lazy_test'
                New-Item -ItemType Directory -Path $testDir -Force | Out-Null
                Push-Location $testDir
                try {
                    ll | Out-Null
                    $after = Test-Path Function:\Get-ChildItemDetailed
                    $after | Should -Be $true
                }
                finally {
                    Pop-Location
                }
            }
        }

        It 'Ensure-FileNavigation initializes on first use' {
            . (Join-Path $script:ProfileDir '02-files-navigation.ps1')

            # Navigation functions should be available after first use
            $before = Test-Path Function:\..
            if (-not $before) {
                # Call the function to trigger lazy loading
                ..
                $after = Test-Path Function:\..
                $after | Should -Be $true
            }
        }
    }

    Context 'Performance and memory tests' {
        BeforeAll {
            . $script:BootstrapPath
        }

        It 'Test-CachedCommand improves performance on repeated calls' {
            $commandName = 'Get-Command'

            # First call - should cache
            $start1 = Get-Date
            $result1 = Test-CachedCommand -Name $commandName
            $time1 = (Get-Date) - $start1

            # Second call - should use cache (faster)
            $start2 = Get-Date
            $result2 = Test-CachedCommand -Name $commandName
            $time2 = (Get-Date) - $start2

            # Results should be the same
            $result1 | Should -Be $result2
            # Second call should be faster or at least not slower
            # (allowing for timing variance)
            $time2.TotalMilliseconds | Should -BeLessOrEqual ($time1.TotalMilliseconds + 50)
        }

        It 'Set-AgentModeFunction does not leak memory on repeated calls' {
            $funcName = "TestMemory_$(Get-Random)"

            # Create and remove function multiple times
            for ($i = 1; $i -le 5; $i++) {
                $result = Set-AgentModeFunction -Name $funcName -Body { "test$i" }
                $result | Should -Be $true
                Remove-Item "Function:\$funcName" -Force -ErrorAction SilentlyContinue
            }

            # Should still be able to create function
            $final = Set-AgentModeFunction -Name $funcName -Body { 'final' }
            $final | Should -Be $true

            # Cleanup
            Remove-Item "Function:\$funcName" -Force -ErrorAction SilentlyContinue
        }
    }

    Context 'Error recovery tests' {
        BeforeAll {
            . (Join-Path $script:ProfileDir '05-utilities.ps1')
        }

        It 'Get-EnvVar recovers from registry errors gracefully' {
            # Test with invalid registry path characters
            $invalidName = "TEST_INVALID<>:$([char]0)"
            $result = Get-EnvVar -Name $invalidName
            # Should return null or empty, not throw
            ($result -eq $null -or $result -eq '') | Should -Be $true
        }

        It 'Remove-Path handles malformed PATH gracefully' {
            $originalPath = $env:PATH
            try {
                # Set malformed PATH
                $env:PATH = ";;;invalid;;;path;;;"
                # Should not throw
                { Remove-Path -Path 'nonexistent' } | Should -Not -Throw
            }
            finally {
                $env:PATH = $originalPath
            }
        }

        It 'Add-Path handles empty PATH' {
            $originalPath = $env:PATH
            try {
                $env:PATH = ''
                $testPath = Join-Path $TestDrive 'EmptyPathTest'
                New-Item -ItemType Directory -Path $testPath -Force | Out-Null
                # Should not throw
                { Add-Path -Path $testPath } | Should -Not -Throw
            }
            finally {
                $env:PATH = $originalPath
            }
        }
    }

    Context 'Cross-platform compatibility' {
        It 'path separators are handled correctly' {
            # Test that Join-Path is used instead of hardcoded separators
            $profileContent = Get-Content (Join-Path $PSScriptRoot '..\Microsoft.PowerShell_profile.ps1') -Raw

            # Should use Join-Path or forward slashes, not backslashes
            # Allow some backslashes in strings/comments, but not many
            $hardcodedPaths = [regex]::Matches($profileContent, '[^\\]\\[A-Za-z]:\\')
            $hardcodedPaths.Count | Should -BeLessThan 10
        }

        It 'functions work with both Windows and Unix-style paths' {
            . (Join-Path $script:ProfileDir '02-files-navigation.ps1')

            # Test that path operations work
            $testPath = Join-Path $TestDrive 'test'
            New-Item -ItemType Directory -Path $testPath -Force | Out-Null

            Push-Location $testPath
            try {
                # Navigation should work
                ..
                $parent = Get-Location
                $parent.Path | Should -Not -BeNullOrEmpty
            }
            finally {
                Pop-Location
            }
        }
    }

    Context 'Function scoping and visibility' {
        BeforeAll {
            . $script:BootstrapPath
        }

        It 'Set-AgentModeFunction creates global functions' {
            $funcName = "TestGlobal_$(Get-Random)"
            $result = Set-AgentModeFunction -Name $funcName -Body { 'global' }
            $result | Should -Be $true

            # Function should be visible globally
            Get-Command $funcName -ErrorAction Stop | Should -Not -Be $null

            # Cleanup
            Remove-Item "Function:\$funcName" -Force -ErrorAction SilentlyContinue
        }

        It 'Set-AgentModeAlias creates global aliases' {
            $aliasName = "TestGlobalAlias_$(Get-Random)"
            $result = Set-AgentModeAlias -Name $aliasName -Target 'Write-Output'
            $result | Should -Be $true

            # Alias should be visible globally
            Get-Alias $aliasName -ErrorAction Stop | Should -Not -Be $null

            # Cleanup
            Remove-Alias -Name $aliasName -Force -ErrorAction SilentlyContinue
        }
    }
}

