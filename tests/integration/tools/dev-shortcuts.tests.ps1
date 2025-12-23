<#
.SYNOPSIS
    Integration tests for development shortcuts fragment (dev.ps1).

.DESCRIPTION
    Tests development shortcut functions (Docker, Podman, Node.js, Python, Cargo wrappers).
    These tests verify that functions are created correctly and are idempotent.
#>

Describe 'Development Shortcuts Integration Tests' {
    BeforeAll {
        try {
            $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
            if ($null -eq $script:ProfileDir -or [string]::IsNullOrWhiteSpace($script:ProfileDir)) {
                throw "Get-TestPath returned null or empty value for ProfileDir"
            }
            if (-not (Test-Path -LiteralPath $script:ProfileDir)) {
                throw "Profile directory not found at: $script:ProfileDir"
            }
            
            $bootstrapPath = Join-Path $script:ProfileDir 'bootstrap.ps1'
            if ($null -eq $bootstrapPath -or [string]::IsNullOrWhiteSpace($bootstrapPath)) {
                throw "BootstrapPath is null or empty"
            }
            if (-not (Test-Path -LiteralPath $bootstrapPath)) {
                throw "Bootstrap file not found at: $bootstrapPath"
            }
            . $bootstrapPath
        }
        catch {
            $errorDetails = @{
                Message  = $_.Exception.Message
                Type     = $_.Exception.GetType().FullName
                Location = $_.InvocationInfo.ScriptLineNumber
            }
            Write-Error "Failed to initialize development shortcuts tests in BeforeAll: $($errorDetails | ConvertTo-Json -Compress)" -ErrorAction Stop
            throw
        }
    }

    Context 'Development shortcuts (dev.ps1)' {
        BeforeAll {
            . (Join-Path $script:ProfileDir 'dev.ps1')
        }

        It 'Fragment is idempotent (can be loaded multiple times)' {
            # Load fragment again
            . (Join-Path $script:ProfileDir 'dev.ps1')
            # Functions should still exist
            Get-Command d -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        Context 'Docker shortcuts' {
            It 'Creates d function (docker wrapper)' {
                Get-Command d -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            }

            It 'Creates dc function (docker-compose wrapper)' {
                Get-Command dc -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            }

            It 'Creates dps function (docker ps wrapper)' {
                Get-Command dps -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            }

            It 'Creates di function (docker images wrapper)' {
                Get-Command di -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            }

            It 'Creates drm function (docker rm wrapper)' {
                Get-Command drm -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            }

            It 'Creates drmi function (docker rmi wrapper)' {
                Get-Command drmi -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            }

            It 'Creates dexec function (docker exec -it wrapper)' {
                Get-Command dexec -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            }

            It 'Creates dlogs function (docker logs wrapper)' {
                Get-Command dlogs -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            }
        }

        Context 'Podman shortcuts' {
            It 'Creates pd function (podman wrapper)' {
                Get-Command pd -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            }

            It 'Creates pps function (podman ps wrapper)' {
                Get-Command pps -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            }

            It 'Creates pi function (podman images wrapper)' {
                Get-Command pi -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            }

            It 'Creates prmi function (podman rmi wrapper)' {
                Get-Command prmi -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            }

            It 'Creates pdexec function (podman exec -it wrapper)' {
                Get-Command pdexec -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            }

            It 'Creates pdlogs function (podman logs wrapper)' {
                Get-Command pdlogs -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            }
        }

        Context 'Node.js shortcuts' {
            It 'Creates n function (npm wrapper)' {
                Get-Command n -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            }

            It 'Creates ni function (npm install wrapper)' {
                Get-Command ni -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            }

            It 'Creates nr function (npm run wrapper)' {
                Get-Command nr -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            }

            It 'Creates ns function (npm start wrapper)' {
                Get-Command ns -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            }

            It 'Creates nt function (npm test wrapper)' {
                Get-Command nt -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            }

            It 'Creates np function (npm publish wrapper)' {
                Get-Command np -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            }

            It 'Creates nb function (npm run build wrapper)' {
                Get-Command nb -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            }

            It 'Creates nrd function (npm run dev wrapper)' {
                Get-Command nrd -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            }
        }

        Context 'Python shortcuts' {
            It 'Creates py function (python wrapper)' {
                Get-Command py -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            }

            It 'Creates venv function (python virtual environment wrapper)' {
                Get-Command venv -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            }

            It 'Creates activate function (activate virtual environment)' {
                Get-Command activate -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            }

            It 'Creates req function (generate requirements.txt)' {
                Get-Command req -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            }

            It 'Creates pipi function (pip install wrapper)' {
                Get-Command pipi -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            }

            It 'Creates pipu function (pip install --upgrade wrapper)' {
                Get-Command pipu -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            }
        }

        Context 'Cargo/Rust shortcuts' {
            It 'Creates cr function (cargo run wrapper)' {
                Get-Command cr -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            }

            It 'Creates cb function (cargo build wrapper)' {
                Get-Command cb -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            }

            It 'Creates ct function (cargo test wrapper)' {
                Get-Command ct -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            }

            It 'Creates cc function (cargo check wrapper)' {
                Get-Command cc -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            }

            It 'Creates cu function (cargo update wrapper)' {
                Get-Command cu -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            }

            It 'Creates ca function (cargo add wrapper)' {
                Get-Command ca -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            }

            It 'Creates cw function (cargo watch -x run wrapper)' {
                Get-Command cw -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            }

            It 'Creates cd function (cargo doc --open wrapper)' {
                Get-Command cd -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            }

            It 'Creates cl function (cargo clippy wrapper)' {
                Get-Command cl -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            }

            It 'Creates cf function (cargo fmt wrapper)' {
                Get-Command cf -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            }

            It 'Creates ci function (cargo install wrapper)' {
                Get-Command ci -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            }
        }
    }
}

