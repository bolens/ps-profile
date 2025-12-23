@{
    # Other Tools
    ExternalTools = @{
        'ollama'     = @{
            Version        = 'latest'
            Description    = 'AI model runner'
            Required       = $false
            InstallCommand = @{
                Windows = 'See: https://ollama.ai/download'
                Linux   = 'See: https://ollama.ai/download'
                MacOS   = 'brew install ollama'
            }
        }
        'ngrok'      = @{
            Version        = 'latest'
            Description    = 'Tunneling tool'
            Required       = $false
            InstallCommand = @{
                Windows = 'scoop install ngrok'
                Linux   = 'See: https://ngrok.com/download'
                MacOS   = 'brew install ngrok/ngrok/ngrok'
            }
        }
        'firebase'   = @{
            Version        = 'latest'
            Description    = 'Firebase CLI'
            Required       = $false
            InstallCommand = @{
                Windows = 'npm install -g firebase-tools'
                Linux   = 'npm install -g firebase-tools'
                MacOS   = 'npm install -g firebase-tools'
            }
        }
        'tailscale'  = @{
            Version        = 'latest'
            Description    = 'VPN tool'
            Required       = $false
            InstallCommand = @{
                Windows = 'scoop install tailscale'
                Linux   = 'See: https://tailscale.com/download/linux'
                MacOS   = 'brew install tailscale'
            }
        }
        'starship'   = @{
            Version        = 'latest'
            Description    = 'Cross-shell prompt framework'
            Required       = $false
            InstallCommand = @{
                Windows = 'scoop install starship'
                Linux   = 'See: https://starship.rs/guide/#%F0%9F%9A%80-installation'
                MacOS   = 'brew install starship'
            }
        }
        'oh-my-posh' = @{
            Version        = 'latest'
            Description    = 'Prompt framework for PowerShell'
            Required       = $false
            InstallCommand = @{
                Windows = 'scoop install oh-my-posh'
                Linux   = 'See: https://ohmyposh.dev/docs/installation'
                MacOS   = 'brew install oh-my-posh'
            }
        }
    }
}

