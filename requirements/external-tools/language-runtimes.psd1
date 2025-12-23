@{
    # Language Runtimes & Package Managers
    ExternalTools = @{
        'bun'    = @{
            Version        = 'latest'
            Description    = 'JavaScript runtime and package manager'
            Required       = $false
            InstallCommand = @{
                Windows = 'scoop install bun'
                Linux   = 'See: https://bun.sh/docs/installation'
                MacOS   = 'brew install bun'
            }
        }
        'deno'   = @{
            Version        = 'latest'
            Description    = 'JavaScript/TypeScript runtime'
            Required       = $false
            InstallCommand = @{
                Windows = 'scoop install deno'
                Linux   = 'See: https://deno.land/manual/getting_started/installation'
                MacOS   = 'brew install deno'
            }
        }
        'go'     = @{
            Version        = 'latest'
            Description    = 'Go programming language'
            Required       = $false
            InstallCommand = @{
                Windows = 'scoop install go'
                Linux   = 'apt install golang-go'
                MacOS   = 'brew install go'
            }
        }
        'rustup' = @{
            Version        = 'latest'
            Description    = 'Rust toolchain installer'
            Required       = $false
            InstallCommand = @{
                Windows = 'scoop install rustup'
                Linux   = 'See: https://rustup.rs/'
                MacOS   = 'brew install rustup-init'
            }
        }
        'uv'     = @{
            Version        = 'latest'
            Description    = 'Python package manager'
            Required       = $false
            InstallCommand = @{
                Windows = 'scoop install uv'
                Linux   = 'See: https://github.com/astral-sh/uv'
                MacOS   = 'brew install uv'
            }
        }
        'pixi'   = @{
            Version        = 'latest'
            Description    = 'Package management tool'
            Required       = $false
            InstallCommand = @{
                Windows = 'scoop install pixi'
                Linux   = 'See: https://github.com/prefix-dev/pixi'
                MacOS   = 'brew install pixi'
            }
        }
    }
}

