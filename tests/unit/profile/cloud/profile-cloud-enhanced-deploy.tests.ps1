# ===============================================
# profile-cloud-enhanced-deploy.tests.ps1
# Unit tests for deployment functions (Doppler, Heroku, Vercel, Netlify)
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
    . (Join-Path $script:ProfileDir 'bootstrap.ps1')
    . (Join-Path $script:ProfileDir 'cloud-enhanced.ps1')

    $script:TestProjectPath = New-TestTempDirectory -Prefix 'CloudDeployProject'
}

Describe 'cloud-enhanced.ps1 - Get-DopplerSecrets' {
    BeforeEach {
        Clear-TestCommandInvocationCapture

        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }

        Set-TestCommandAvailabilityState -CommandName 'doppler' -Available $false
        Remove-Item -Path 'Function:\doppler' -Force -ErrorAction SilentlyContinue
        Remove-Item -Path 'Function:\global:doppler' -Force -ErrorAction SilentlyContinue
    }

    Context 'Tool not available' {
        It 'Returns null when doppler is not available' {
            $result = Get-DopplerSecrets -Project 'my-project' -ErrorAction SilentlyContinue

            $result | Should -BeNullOrEmpty
        }
    }

    Context 'Tool available' {
        It 'Calls doppler with project and config' {
            Setup-CapturingCommandMock -CommandName 'doppler' -Output 'SECRET=value'

            $result = Get-DopplerSecrets -Project 'my-project' -Config 'dev' -ErrorAction SilentlyContinue

            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain 'secrets'
            $args | Should -Contain 'get'
            $args | Should -Contain '--project'
            $args | Should -Contain 'my-project'
            $args | Should -Contain '--config'
            $args | Should -Contain 'dev'
            $result | Should -Not -BeNullOrEmpty
        }

        It 'Calls doppler with JSON format' {
            Setup-CapturingCommandMock -CommandName 'doppler' -Output '{"SECRET": "value"}'

            Get-DopplerSecrets -Project 'my-project' -OutputFormat 'json' -ErrorAction SilentlyContinue | Out-Null

            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain '--format'
            $args | Should -Contain 'json'
        }
    }
}

Describe 'cloud-enhanced.ps1 - Deploy-Heroku' {
    BeforeEach {
        Clear-TestCommandInvocationCapture

        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }

        foreach ($command in @('heroku', 'git')) {
            Set-TestCommandAvailabilityState -CommandName $command -Available $false
            Remove-Item -Path "Function:\$command" -Force -ErrorAction SilentlyContinue
            Remove-Item -Path "Function:\global:$command" -Force -ErrorAction SilentlyContinue
        }
    }

    Context 'Tool not available' {
        It 'Returns null when heroku is not available' {
            $result = Deploy-Heroku -AppName 'my-app' -ErrorAction SilentlyContinue

            $result | Should -BeNullOrEmpty
        }
    }

    Context 'Tool available' {
        It 'Deploys using git push for deploy action' {
            Set-TestCommandAvailabilityState -CommandName 'heroku'
            Setup-CapturingCommandMock -CommandName 'git' -Output 'Deployed'

            $result = Deploy-Heroku -AppName 'my-app' -Action 'deploy' -ErrorAction SilentlyContinue

            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain 'push'
            $args | Should -Contain 'heroku'
            $result | Should -Not -BeNullOrEmpty
        }

        It 'Calls heroku logs for logs action' {
            Setup-CapturingCommandMock -CommandName 'heroku' -Output 'Log output'

            $result = Deploy-Heroku -AppName 'my-app' -Action 'logs' -ErrorAction SilentlyContinue

            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain 'logs'
            $args | Should -Contain '--tail'
            $args | Should -Contain 'my-app'
            $result | Should -Not -BeNullOrEmpty
        }
    }
}

Describe 'cloud-enhanced.ps1 - Deploy-Vercel' {
    BeforeEach {
        Clear-TestCommandInvocationCapture

        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }

        Set-TestCommandAvailabilityState -CommandName 'vercel' -Available $false
        Remove-Item -Path 'Function:\vercel' -Force -ErrorAction SilentlyContinue
        Remove-Item -Path 'Function:\global:vercel' -Force -ErrorAction SilentlyContinue
    }

    Context 'Tool not available' {
        It 'Returns null when vercel is not available' {
            $result = Deploy-Vercel -ErrorAction SilentlyContinue

            $result | Should -BeNullOrEmpty
        }
    }

    Context 'Tool available' {
        It 'Calls vercel deploy' {
            Setup-CapturingCommandMock -CommandName 'vercel' -Output 'Deployed'

            $result = Deploy-Vercel -ProjectPath $script:TestProjectPath -ErrorAction SilentlyContinue

            $result | Should -Be 'Deployed'
            $global:TestCommandInvocationCaptures.Count | Should -Be 1
        }

        It 'Calls vercel with --prod for production' {
            Setup-CapturingCommandMock -CommandName 'vercel' -Output 'Deployed'

            Deploy-Vercel -ProjectPath $script:TestProjectPath -Production -ErrorAction SilentlyContinue | Out-Null

            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain '--prod'
        }
    }
}

Describe 'cloud-enhanced.ps1 - Deploy-Netlify' {
    BeforeEach {
        Clear-TestCommandInvocationCapture

        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }

        Set-TestCommandAvailabilityState -CommandName 'netlify' -Available $false
        Remove-Item -Path 'Function:\netlify' -Force -ErrorAction SilentlyContinue
        Remove-Item -Path 'Function:\global:netlify' -Force -ErrorAction SilentlyContinue
    }

    Context 'Tool not available' {
        It 'Returns null when netlify is not available' {
            $result = Deploy-Netlify -ErrorAction SilentlyContinue

            $result | Should -BeNullOrEmpty
        }
    }

    Context 'Tool available' {
        It 'Calls netlify deploy' {
            Setup-CapturingCommandMock -CommandName 'netlify' -Output 'Deployed'

            $result = Deploy-Netlify -ProjectPath $script:TestProjectPath -ErrorAction SilentlyContinue

            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain 'deploy'
            $result | Should -Not -BeNullOrEmpty
        }

        It 'Calls netlify status for status action' {
            Setup-CapturingCommandMock -CommandName 'netlify' -Output 'Status'

            Deploy-Netlify -ProjectPath $script:TestProjectPath -Action 'status' -ErrorAction SilentlyContinue | Out-Null

            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain 'status'
        }
    }
}
