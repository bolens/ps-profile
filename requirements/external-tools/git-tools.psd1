@{
    # Git Tools
    ExternalTools = @{
        'gh' = @{
            Version        = 'latest'
            Description    = 'GitHub CLI'
            Required       = $false
            InstallCommand = @{
                Windows = 'scoop install gh'
                Linux   = 'See: https://github.com/cli/cli/blob/trunk/docs/install_linux.md'
                MacOS   = 'brew install gh'
            }
        }
    }
}

