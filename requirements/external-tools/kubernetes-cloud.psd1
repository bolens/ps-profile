@{
    # Kubernetes & Cloud Tools
    ExternalTools = @{
        'kubectl'   = @{
            Version        = 'latest'
            Description    = 'Kubernetes command-line tool'
            Required       = $false
            InstallCommand = @{
                Windows = 'scoop install kubectl'
                Linux   = 'See: https://kubernetes.io/docs/tasks/tools/'
                MacOS   = 'brew install kubectl'
            }
        }
        'helm'      = @{
            Version        = 'latest'
            Description    = 'Kubernetes package manager'
            Required       = $false
            InstallCommand = @{
                Windows = 'scoop install helm'
                Linux   = 'See: https://helm.sh/docs/intro/install/'
                MacOS   = 'brew install helm'
            }
        }
        'terraform' = @{
            Version        = 'latest'
            Description    = 'Infrastructure as code tool'
            Required       = $false
            InstallCommand = @{
                Windows = 'scoop install terraform'
                Linux   = 'See: https://www.terraform.io/downloads'
                MacOS   = 'brew install terraform'
            }
        }
        'aws'       = @{
            Version        = 'latest'
            Description    = 'AWS CLI'
            Required       = $false
            InstallCommand = @{
                Windows = 'scoop install aws'
                Linux   = 'See: https://aws.amazon.com/cli/'
                MacOS   = 'brew install awscli'
            }
        }
        'az'        = @{
            Version        = 'latest'
            Description    = 'Azure CLI'
            Required       = $false
            InstallCommand = @{
                Windows = 'scoop install azure-cli'
                Linux   = 'See: https://learn.microsoft.com/en-us/cli/azure/install-azure-cli'
                MacOS   = 'brew install azure-cli'
            }
        }
        'azd'       = @{
            Version        = 'latest'
            Description    = 'Azure Developer CLI'
            Required       = $false
            InstallCommand = @{
                Windows = 'scoop install azure-developer-cli'
                Linux   = 'See: https://learn.microsoft.com/en-us/azure/developer/azure-developer-cli/install-azd'
                MacOS   = 'brew install azure/azd/azd'
            }
        }
        'gcloud'    = @{
            Version        = 'latest'
            Description    = 'Google Cloud CLI'
            Required       = $false
            InstallCommand = @{
                Windows = 'See: https://cloud.google.com/sdk/docs/install'
                Linux   = 'See: https://cloud.google.com/sdk/docs/install'
                MacOS   = 'brew install google-cloud-sdk'
            }
        }
    }
}

