@{
    # File & Data Tools
    ExternalTools = @{
        'jq'     = @{
            Version        = 'latest'
            Description    = 'JSON processor'
            Required       = $false
            InstallCommand = @{
                Windows = 'scoop install jq'
                Linux   = 'apt install jq'
                MacOS   = 'brew install jq'
            }
        }
        'yq'     = @{
            Version        = 'latest'
            Description    = 'YAML processor'
            Required       = $false
            InstallCommand = @{
                Windows = 'scoop install yq'
                Linux   = 'See: https://github.com/mikefarah/yq'
                MacOS   = 'brew install yq'
            }
        }
        'rclone' = @{
            Version        = 'latest'
            Description    = 'Cloud storage sync tool'
            Required       = $false
            InstallCommand = @{
                Windows = 'scoop install rclone'
                Linux   = 'apt install rclone'
                MacOS   = 'brew install rclone'
            }
        }
        'mc'     = @{
            Version        = 'latest'
            Description    = 'MinIO client'
            Required       = $false
            InstallCommand = @{
                Windows = 'scoop install minio-client'
                Linux   = 'See: https://min.io/download#/linux'
                MacOS   = 'brew install minio/stable/mc'
            }
        }
        'zstd'   = @{
            Version        = '1.5.0'
            Description    = 'Zstandard compression tool for compression/decompression utilities'
            Required       = $false
            InstallCommand = @{
                Windows = 'scoop install zstd'
                Linux   = 'apt install zstd'
                MacOS   = 'brew install zstd'
            }
        }
    }
}

