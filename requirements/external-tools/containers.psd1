@{
    # Container Tools
    ExternalTools = @{
        'docker'         = @{
            Version        = 'latest'
            Description    = 'Container engine'
            Required       = $false
            InstallCommand = @{
                Windows = 'scoop install docker'
                Linux   = 'apt install docker.io'
                MacOS   = 'brew install docker'
            }
        }
        'podman'         = @{
            Version        = 'latest'
            Description    = 'Container engine alternative to Docker'
            Required       = $false
            InstallCommand = @{
                Windows = 'scoop install podman'
                Linux   = 'apt install podman'
                MacOS   = 'brew install podman'
            }
        }
        'docker-compose' = @{
            Version        = 'latest'
            Description    = 'Docker Compose standalone (legacy)'
            Required       = $false
            InstallCommand = @{
                Windows = 'scoop install docker-compose'
                Linux   = 'apt install docker-compose'
                MacOS   = 'brew install docker-compose'
            }
        }
        'podman-compose' = @{
            Version        = 'latest'
            Description    = 'Podman Compose standalone'
            Required       = $false
            InstallCommand = @{
                Windows = 'pip install podman-compose'
                Linux   = 'pip install podman-compose'
                MacOS   = 'pip install podman-compose'
            }
        }
        'lazydocker'     = @{
            Version        = 'latest'
            Description    = 'Terminal UI for Docker'
            Required       = $false
            InstallCommand = @{
                Windows = 'scoop install lazydocker'
                Linux   = 'See: https://github.com/jesseduffield/lazydocker'
                MacOS   = 'brew install lazydocker'
            }
        }
    }
}

