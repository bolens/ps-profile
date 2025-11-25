Describe "Modern CLI Tools" {
    BeforeAll {
        # Source TestSupport.ps1 for helper functions
        . "$PSScriptRoot\..\TestSupport.ps1"

        # Load bootstrap first to get Test-HasCommand
        $global:__psprofile_fragment_loaded = @{}
        . "$PSScriptRoot\..\..\profile.d\00-bootstrap.ps1"

        # Load the modern CLI tools fragment with guard clearing
        . "$PSScriptRoot\..\..\profile.d\54-modern-cli.ps1"
    }

    Context "bat function" {
        BeforeEach {
            # Mock external bat command to avoid hanging
            Mock -CommandName 'Get-Command' -ParameterFilter { $Name -eq 'bat' -and $CommandType -eq 'Application' } -MockWith { $null }
        }

        It "Executes without error when function exists" {
            { bat --help } | Should -Not -Throw
        }

        It "Function is defined" {
            Get-Command bat -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
    }

    Context "fd function" {
        BeforeEach {
            # Mock external fd command to avoid hanging
            Mock -CommandName 'Get-Command' -ParameterFilter { $Name -eq 'fd' -and $CommandType -eq 'Application' } -MockWith { $null }
        }

        It "Executes without error when function exists" {
            { fd --help } | Should -Not -Throw
        }

        It "Function is defined" {
            Get-Command fd -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
    }

    Context "http function" {
        BeforeEach {
            # Mock external http command to avoid hanging
            Mock -CommandName 'Get-Command' -ParameterFilter { $Name -eq 'http' -and $CommandType -eq 'Application' } -MockWith { $null }
        }

        It "Executes without error when function exists" {
            { http --help } | Should -Not -Throw
        }

        It "Function is defined" {
            Get-Command http -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
    }

    Context "zoxide function" {
        BeforeEach {
            # Mock external zoxide command to avoid hanging
            Mock -CommandName 'Get-Command' -ParameterFilter { $Name -eq 'zoxide' -and $CommandType -eq 'Application' } -MockWith { $null }
        }

        It "Executes without error when function exists" {
            { zoxide --help } | Should -Not -Throw
        }

        It "Function is defined" {
            Get-Command zoxide -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
    }

    Context "delta function" {
        BeforeEach {
            # Mock external delta command to avoid hanging
            Mock -CommandName 'Get-Command' -ParameterFilter { $Name -eq 'delta' -and $CommandType -eq 'Application' } -MockWith { $null }
        }

        It "Executes without error when function exists" {
            { delta --help } | Should -Not -Throw
        }

        It "Function is defined" {
            Get-Command delta -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
    }

    Context "tldr function" {
        BeforeEach {
            # Mock external tldr command to avoid hanging
            Mock -CommandName 'Get-Command' -ParameterFilter { $Name -eq 'tldr' -and $CommandType -eq 'Application' } -MockWith { $null }
        }

        It "Executes without error when function exists" {
            { tldr --help } | Should -Not -Throw
        }

        It "Function is defined" {
            Get-Command tldr -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
    }

    Context "procs function" {
        BeforeEach {
            # Mock external procs command to avoid hanging
            Mock -CommandName 'Get-Command' -ParameterFilter { $Name -eq 'procs' -and $CommandType -eq 'Application' } -MockWith { $null }
        }

        It "Executes without error when function exists" {
            { procs --help } | Should -Not -Throw
        }

        It "Function is defined" {
            Get-Command procs -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
    }

    Context "dust function" {
        BeforeEach {
            # Mock external dust command to avoid hanging
            Mock -CommandName 'Get-Command' -ParameterFilter { $Name -eq 'dust' -and $CommandType -eq 'Application' } -MockWith { $null }
        }

        It "Executes without error when function exists" {
            { dust --help } | Should -Not -Throw
        }

        It "Function is defined" {
            Get-Command dust -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
    }
}
