. (Join-Path $PSScriptRoot '..\TestSupport.ps1')

Describe 'Environment Variable Integration Tests' {
    BeforeAll {
        $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
        . (Join-Path $script:ProfileDir '05-utilities.ps1')
    }

    BeforeEach {
        . (Join-Path $script:ProfileDir '01-env.ps1')
    }

    Context 'Environment defaults and helpers' {
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

        It 'Get-EnvVar handles non-existent variables' {
            $nonExistent = "NON_EXISTENT_VAR_$(Get-Random)"
            $result = Get-EnvVar -Name $nonExistent
            ($result -eq $null -or $result -eq '') | Should -Be $true
        }

        It 'Set-EnvVar handles null values for deletion' {
            $tempVar = "TEST_DELETE_$(Get-Random)"
            try {
                Set-EnvVar -Name $tempVar -Value 'test'
                $before = Get-EnvVar -Name $tempVar
                $before | Should -Be 'test'

                Set-EnvVar -Name $tempVar -Value $null
                $after = Get-EnvVar -Name $tempVar
                ($after -eq $null -or $after -eq '') | Should -Be $true
            }
            finally {
                Set-EnvVar -Name $tempVar -Value $null
            }
        }
    }
}
