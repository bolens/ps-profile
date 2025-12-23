@{
    # Modern CLI Tools
    ExternalTools = @{
        'bat'    = @{
            Version        = 'latest'
            Description    = 'Cat clone with syntax highlighting'
            Required       = $false
            InstallCommand = @{
                Windows = 'scoop install bat'
                Linux   = 'apt install bat'
                MacOS   = 'brew install bat'
            }
        }
        'fd'     = @{
            Version        = 'latest'
            Description    = 'Find files and directories'
            Required       = $false
            InstallCommand = @{
                Windows = 'scoop install fd'
                Linux   = 'apt install fd-find'
                MacOS   = 'brew install fd'
            }
        }
        'httpie' = @{
            Version        = 'latest'
            Description    = 'Command-line HTTP client (http command)'
            Required       = $false
            InstallCommand = @{
                Windows = 'scoop install httpie'
                Linux   = 'apt install httpie'
                MacOS   = 'brew install httpie'
            }
        }
        'zoxide' = @{
            Version        = 'latest'
            Description    = 'Smarter cd command'
            Required       = $false
            InstallCommand = @{
                Windows = 'scoop install zoxide'
                Linux   = 'See: https://github.com/ajeetdsouza/zoxide'
                MacOS   = 'brew install zoxide'
            }
        }
        'delta'  = @{
            Version        = 'latest'
            Description    = 'Syntax-highlighting pager for git'
            Required       = $false
            InstallCommand = @{
                Windows = 'scoop install git-delta'
                Linux   = 'apt install git-delta'
                MacOS   = 'brew install git-delta'
            }
        }
        'tldr'   = @{
            Version        = 'latest'
            Description    = 'Simplified man pages'
            Required       = $false
            InstallCommand = @{
                Windows = 'scoop install tldr'
                Linux   = 'npm install -g tldr'
                MacOS   = 'brew install tldr'
            }
        }
        'fzf'    = @{
            Version        = 'latest'
            Description    = 'Fuzzy finder'
            Required       = $false
            InstallCommand = @{
                Windows = 'scoop install fzf'
                Linux   = 'apt install fzf'
                MacOS   = 'brew install fzf'
            }
        }
        'rg'     = @{
            Version        = 'latest'
            Description    = 'ripgrep - fast text search tool'
            Required       = $false
            InstallCommand = @{
                Windows = 'scoop install ripgrep'
                Linux   = 'apt install ripgrep'
                MacOS   = 'brew install ripgrep'
            }
        }
        'eza'    = @{
            Version        = 'latest'
            Description    = 'Modern ls replacement'
            Required       = $false
            InstallCommand = @{
                Windows = 'scoop install eza'
                Linux   = 'See: https://github.com/eza-community/eza'
                MacOS   = 'brew install eza'
            }
        }
        'procs'  = @{
            Version        = 'latest'
            Description    = 'Modern replacement for ps'
            Required       = $false
            InstallCommand = @{
                Windows = 'scoop install procs'
                Linux   = 'See: https://github.com/dalance/procs'
                MacOS   = 'brew install procs'
            }
        }
        'dust'   = @{
            Version        = 'latest'
            Description    = 'More intuitive du command'
            Required       = $false
            InstallCommand = @{
                Windows = 'scoop install dust'
                Linux   = 'See: https://github.com/bootandy/dust'
                MacOS   = 'brew install dust'
            }
        }
        'bottom' = @{
            Version        = 'latest'
            Description    = 'System monitor (btm command)'
            Required       = $false
            InstallCommand = @{
                Windows = 'scoop install bottom'
                Linux   = 'See: https://github.com/ClementTsang/bottom'
                MacOS   = 'brew install bottom'
            }
        }
        'navi'   = @{
            Version        = 'latest'
            Description    = 'Interactive cheatsheet tool'
            Required       = $false
            InstallCommand = @{
                Windows = 'scoop install navi'
                Linux   = 'See: https://github.com/denisidoro/navi'
                MacOS   = 'brew install navi'
            }
        }
        'gum'    = @{
            Version        = 'latest'
            Description    = 'Terminal UI helpers'
            Required       = $false
            InstallCommand = @{
                Windows = 'scoop install gum'
                Linux   = 'See: https://github.com/charmbracelet/gum'
                MacOS   = 'brew install gum'
            }
        }
    }
}

