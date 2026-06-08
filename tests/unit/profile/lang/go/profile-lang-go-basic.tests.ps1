# ===============================================
# profile-lang-go-basic.tests.ps1
# Behavioral unit tests for Go language helper functions
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
    $fragmentIdempotencyPath = Get-TestPath -RelativePath 'scripts/lib/fragment/FragmentIdempotency.psm1' -StartPath $PSScriptRoot -EnsureExists
    Import-Module $fragmentIdempotencyPath -DisableNameChecking -ErrorAction Stop -Force
    . (Join-Path $script:ProfileDir 'bootstrap.ps1')
    . (Join-Path $script:ProfileDir 'lang-go-basic.ps1')
}

Describe 'lang-go-basic.ps1 - Invoke-GoRun' {
    BeforeEach {
        Clear-TestCommandInvocationCapture
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }
        Mark-TestCommandsUnavailable -CommandNames 'go'
    }

    Context 'Tool not available' {
        It 'Does not invoke go when the binary is missing' {
            Invoke-GoRun 'main.go' -ErrorAction SilentlyContinue | Out-Null

            $global:TestCommandInvocationCaptures.Count | Should -Be 0
        }
    }

    Context 'Tool available' {
        It 'Forwards arguments to go run' {
            Setup-CapturingCommandMock -CommandName 'go' -Output 'program output'

            $result = Invoke-GoRun 'main.go' -ErrorAction SilentlyContinue

            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain 'run'
            $args | Should -Contain 'main.go'
            $result | Should -Be 'program output'
        }
    }
}

Describe 'lang-go-basic.ps1 - Build-GoProgram' {
    BeforeEach {
        Clear-TestCommandInvocationCapture
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }
        Mark-TestCommandsUnavailable -CommandNames 'go'
    }

    It 'Does not invoke go when the binary is missing' {
        Build-GoProgram '-o', 'myapp' -ErrorAction SilentlyContinue | Out-Null

        $global:TestCommandInvocationCaptures.Count | Should -Be 0
    }

    It 'Calls go build with forwarded arguments' {
        Setup-CapturingCommandMock -CommandName 'go' -Output 'build ok'

        Build-GoProgram '-o', 'myapp' -ErrorAction SilentlyContinue | Out-Null

        $args = Get-TestCommandInvocationArgsFlat
        $args | Should -Contain 'build'
        $args | Should -Contain '-o'
        $args | Should -Contain 'myapp'
    }
}

Describe 'lang-go-basic.ps1 - Invoke-GoModule and Test-GoPackage' {
    BeforeEach {
        Clear-TestCommandInvocationCapture
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }
        Mark-TestCommandsUnavailable -CommandNames 'go'
    }

    It 'Does not invoke go mod when the binary is missing' {
        Invoke-GoModule 'tidy' -ErrorAction SilentlyContinue | Out-Null

        $global:TestCommandInvocationCaptures.Count | Should -Be 0
    }

    It 'Invoke-GoModule calls go mod with subcommands' {
        Setup-CapturingCommandMock -CommandName 'go' -Output 'mod tidy complete'

        Invoke-GoModule 'tidy' -ErrorAction SilentlyContinue | Out-Null

        $args = Get-TestCommandInvocationArgsFlat
        $args | Should -Contain 'mod'
        $args | Should -Contain 'tidy'
    }

    It 'Does not invoke go test when the binary is missing' {
        Test-GoPackage '-v', './...' -ErrorAction SilentlyContinue | Out-Null

        $global:TestCommandInvocationCaptures.Count | Should -Be 0
    }

    It 'Test-GoPackage calls go test with forwarded flags' {
        Setup-CapturingCommandMock -CommandName 'go' -Output 'ok'

        Test-GoPackage '-v', './...' -ErrorAction SilentlyContinue | Out-Null

        $args = Get-TestCommandInvocationArgsFlat
        $args | Should -Contain 'test'
        $args | Should -Contain '-v'
        $args | Should -Contain './...'
    }
}

Describe 'lang-go-basic.ps1 - dependency and install helpers' {
    BeforeEach {
        Clear-TestCommandInvocationCapture
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }
        Mark-TestCommandsUnavailable -CommandNames 'go'
    }

    It 'Does not invoke go get when the binary is missing' {
        Update-GoDependencies -ErrorAction SilentlyContinue | Out-Null

        $global:TestCommandInvocationCaptures.Count | Should -Be 0
    }

    It 'Update-GoDependencies runs go get -u ./...' {
        Setup-CapturingCommandMock -CommandName 'go' -Output 'updated'

        Update-GoDependencies -ErrorAction SilentlyContinue | Out-Null

        $args = Get-TestCommandInvocationArgsFlat
        $args | Should -Contain 'get'
        $args | Should -Contain '-u'
        $args | Should -Contain './...'
    }

    It 'Update-GoTools installs golang.org/x/tools commands at latest' {
        Setup-CapturingCommandMock -CommandName 'go' -Output 'tools updated'

        Update-GoTools -ErrorAction SilentlyContinue | Out-Null

        $args = Get-TestCommandInvocationArgsFlat
        $args | Should -Contain 'install'
        ($args -join ' ') | Should -Match 'golang\.org/x/tools/cmd/\.\.\.@latest'
    }

    It 'Does not invoke go install for tools when the binary is missing' {
        Update-GoTools -ErrorAction SilentlyContinue | Out-Null

        $global:TestCommandInvocationCaptures.Count | Should -Be 0
    }

    It 'Does not invoke go mod edit when the binary is missing' {
        Remove-GoDependency 'github.com/example/pkg' -ErrorAction SilentlyContinue | Out-Null

        $global:TestCommandInvocationCaptures.Count | Should -Be 0
    }

    It 'Remove-GoDependency drops packages and runs go mod tidy' {
        Setup-CapturingCommandMock -CommandName 'go' -Output 'ok'

        Remove-GoDependency 'github.com/example/pkg' -ErrorAction SilentlyContinue | Out-Null

        $global:TestCommandInvocationCaptures.Count | Should -Be 2
        $global:TestCommandInvocationCaptures[0] | Should -Contain 'mod'
        $global:TestCommandInvocationCaptures[0] | Should -Contain 'edit'
        $global:TestCommandInvocationCaptures[0] | Should -Contain '-droprequire'
        $global:TestCommandInvocationCaptures[0] | Should -Contain 'github.com/example/pkg'
        $global:TestCommandInvocationCaptures[1] | Should -Contain 'mod'
        $global:TestCommandInvocationCaptures[1] | Should -Contain 'tidy'
    }

    It 'Does not invoke go install when the binary is missing' {
        Install-GoPackage 'golang.org/x/tools/gopls@latest' -ErrorAction SilentlyContinue | Out-Null

        $global:TestCommandInvocationCaptures.Count | Should -Be 0
    }

    It 'Install-GoPackage forwards package paths to go install' {
        Setup-CapturingCommandMock -CommandName 'go' -Output 'installed'

        Install-GoPackage 'golang.org/x/tools/gopls@latest' -ErrorAction SilentlyContinue | Out-Null

        $args = Get-TestCommandInvocationArgsFlat
        $args | Should -Contain 'install'
        $args | Should -Contain 'golang.org/x/tools/gopls@latest'
    }
}

Describe 'lang-go-basic.ps1 - fragment idempotency' {
    It 'Skips re-initialization when lang-go-basic is already loaded' {
        Test-FragmentLoaded -FragmentName 'lang-go-basic' | Should -Be $true

        { . (Join-Path $script:ProfileDir 'lang-go-basic.ps1') } | Should -Not -Throw
        Get-Command Invoke-GoRun -ErrorAction Stop | Should -Not -BeNullOrEmpty
    }
}

Describe 'lang-go-basic.ps1 - aliases' {
    It 'Registers go helper aliases that resolve to profile functions' {
        (Get-Alias go-run -ErrorAction SilentlyContinue).ResolvedCommandName | Should -Be 'Invoke-GoRun'
        (Get-Alias go-build -ErrorAction SilentlyContinue).ResolvedCommandName | Should -Be 'Build-GoProgram'
        (Get-Alias go-mod -ErrorAction SilentlyContinue).ResolvedCommandName | Should -Be 'Invoke-GoModule'
        (Get-Alias go-test -ErrorAction SilentlyContinue).ResolvedCommandName | Should -Be 'Test-GoPackage'
        (Get-Alias go-update -ErrorAction SilentlyContinue).ResolvedCommandName | Should -Be 'Update-GoDependencies'
        (Get-Alias go-tools-update -ErrorAction SilentlyContinue).ResolvedCommandName | Should -Be 'Update-GoTools'
        (Get-Alias go-install -ErrorAction SilentlyContinue).ResolvedCommandName | Should -Be 'Install-GoPackage'
        (Get-Alias go-remove -ErrorAction SilentlyContinue).ResolvedCommandName | Should -Be 'Remove-GoDependency'
    }
}
