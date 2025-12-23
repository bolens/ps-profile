@{
    # Specialized Format Conversion Tools
    # Dependencies for QR Code, Barcode, JWT, and other specialized format conversions
    ExternalTools = @{
        'qrcode'        = @{
            Version        = 'latest'
            Description    = 'QR code generation library (for QR code format conversions)'
            Required       = $false
            InstallCommand = @{
                Windows = 'pnpm add -g qrcode'
                Linux   = 'pnpm add -g qrcode'
                MacOS   = 'pnpm add -g qrcode'
            }
        }
        'jsonwebtoken'  = @{
            Version        = 'latest'
            Description    = 'JWT encoding/decoding library (for JWT format conversions)'
            Required       = $false
            InstallCommand = @{
                Windows = 'pnpm add -g jsonwebtoken'
                Linux   = 'pnpm add -g jsonwebtoken'
                MacOS   = 'pnpm add -g jsonwebtoken'
            }
        }
        'jsbarcode'     = @{
            Version        = 'latest'
            Description    = 'JavaScript barcode generation library (for barcode format conversions)'
            Required       = $false
            InstallCommand = @{
                Windows = 'pnpm add -g jsbarcode'
                Linux   = 'pnpm add -g jsbarcode'
                MacOS   = 'pnpm add -g jsbarcode'
            }
        }
        'canvas'        = @{
            Version        = 'latest'
            Description    = 'Node.js canvas library (required for barcode image generation)'
            Required       = $false
            InstallCommand = @{
                Windows = 'pnpm add -g canvas'
                Linux   = 'pnpm add -g canvas (may require system dependencies: apt install build-essential libcairo2-dev libpango1.0-dev libjpeg-dev libgif-dev librsvg2-dev)'
                MacOS   = 'pnpm add -g canvas (may require: brew install pkg-config cairo pango libpng jpeg giflib librsvg)'
            }
        }
        'ubjson'        = @{
            Version        = 'latest'
            Description    = 'Universal Binary JSON library (for UBJSON format conversions)'
            Required       = $false
            InstallCommand = @{
                Windows = 'pnpm add -g ubjson'
                Linux   = 'pnpm add -g ubjson'
                MacOS   = 'pnpm add -g ubjson'
            }
        }
        'ion-python'    = @{
            Version        = 'latest'
            Description    = 'Amazon Ion format library (for Ion format conversions)'
            Required       = $false
            InstallCommand = @{
                Windows = 'uv pip install ion-python'
                Linux   = 'uv pip install ion-python'
                MacOS   = 'uv pip install ion-python'
            }
        }
        'pyodbc'        = @{
            Version        = 'latest'
            Description    = 'ODBC database connector (for Microsoft Access database conversions)'
            Required       = $false
            InstallCommand = @{
                Windows = 'uv pip install pyodbc'
                Linux   = 'uv pip install pyodbc (may require: apt install unixodbc-dev)'
                MacOS   = 'uv pip install pyodbc (may require: brew install unixodbc)'
            }
        }
        'dbfread'       = @{
            Version        = 'latest'
            Description    = 'DBF file reader (for DBF format conversions)'
            Required       = $false
            InstallCommand = @{
                Windows = 'uv pip install dbfread'
                Linux   = 'uv pip install dbfread'
                MacOS   = 'uv pip install dbfread'
            }
        }
        'dbf'           = @{
            Version        = 'latest'
            Description    = 'DBF file reader/writer (for DBF format conversions)'
            Required       = $false
            InstallCommand = @{
                Windows = 'uv pip install dbf'
                Linux   = 'uv pip install dbf'
                MacOS   = 'uv pip install dbf'
            }
        }
        'pyreadstat'    = @{
            Version        = 'latest'
            Description    = 'Statistical file reader (for Stata, SPSS, SAS format conversions)'
            Required       = $false
            InstallCommand = @{
                Windows = 'uv pip install pyreadstat'
                Linux   = 'uv pip install pyreadstat'
                MacOS   = 'uv pip install pyreadstat'
            }
        }
        'pandas'        = @{
            Version        = 'latest'
            Description    = 'Data analysis library (for Stata, SPSS, SAS format conversions)'
            Required       = $false
            InstallCommand = @{
                Windows = 'uv pip install pandas'
                Linux   = 'uv pip install pandas'
                MacOS   = 'uv pip install pandas'
            }
        }
        'polars'        = @{
            Version        = 'latest'
            Description    = 'Fast data frame library (alternative to pandas for Stata, SPSS, SAS format conversions)'
            Required       = $false
            InstallCommand = @{
                Windows = 'uv pip install polars'
                Linux   = 'uv pip install polars'
                MacOS   = 'uv pip install polars'
            }
        }
        'scipy'         = @{
            Version        = 'latest'
            Description    = 'Scientific computing library (for Matlab format conversions)'
            Required       = $false
            InstallCommand = @{
                Windows = 'uv pip install scipy'
                Linux   = 'uv pip install scipy'
                MacOS   = 'uv pip install scipy'
            }
        }
        'astropy'       = @{
            Version        = 'latest'
            Description    = 'Astronomy library (for FITS format conversions)'
            Required       = $false
            InstallCommand = @{
                Windows = 'uv pip install astropy'
                Linux   = 'uv pip install astropy'
                MacOS   = 'uv pip install astropy'
            }
        }
        'pyarrow'       = @{
            Version        = 'latest'
            Description    = 'Apache Arrow library (for ORC, Delta, Iceberg, Parquet format conversions)'
            Required       = $false
            InstallCommand = @{
                Windows = 'uv pip install pyarrow'
                Linux   = 'uv pip install pyarrow'
                MacOS   = 'uv pip install pyarrow'
            }
        }
        'delta-spark'   = @{
            Version        = 'latest'
            Description    = 'Delta Lake library (for Delta Lake format conversions)'
            Required       = $false
            InstallCommand = @{
                Windows = 'uv pip install delta-spark'
                Linux   = 'uv pip install delta-spark'
                MacOS   = 'uv pip install delta-spark'
            }
        }
        'deltalake'     = @{
            Version        = 'latest'
            Description    = 'Delta Lake library (alternative, for Delta Lake format conversions)'
            Required       = $false
            InstallCommand = @{
                Windows = 'uv pip install deltalake'
                Linux   = 'uv pip install deltalake'
                MacOS   = 'uv pip install deltalake'
            }
        }
        'pyiceberg'     = @{
            Version        = 'latest'
            Description    = 'Apache Iceberg library (for Iceberg format conversions)'
            Required       = $false
            InstallCommand = @{
                Windows = 'uv pip install pyiceberg'
                Linux   = 'uv pip install pyiceberg'
                MacOS   = 'uv pip install pyiceberg'
            }
        }
        'python-snappy' = @{
            Version        = 'latest'
            Description    = 'Snappy compression library (for Snappy compression conversions)'
            Required       = $false
            InstallCommand = @{
                Windows = 'uv pip install python-snappy'
                Linux   = 'uv pip install python-snappy (may require: apt install libsnappy-dev)'
                MacOS   = 'uv pip install python-snappy (may require: brew install snappy)'
            }
        }
        'fastparquet'   = @{
            Version        = 'latest'
            Description    = 'Fast Parquet library (alternative to pyarrow for Parquet format conversions)'
            Required       = $false
            InstallCommand = @{
                Windows = 'uv pip install fastparquet'
                Linux   = 'uv pip install fastparquet'
                MacOS   = 'uv pip install fastparquet'
            }
        }
        'xarray'        = @{
            Version        = 'latest'
            Description    = 'Scientific data library (alternative to netCDF4/h5py for scientific format conversions)'
            Required       = $false
            InstallCommand = @{
                Windows = 'uv pip install xarray'
                Linux   = 'uv pip install xarray'
                MacOS   = 'uv pip install xarray'
            }
        }
        'jsonc'         = @{
            Version        = 'latest'
            Description    = 'JSON with Comments library (for JSONC format conversions)'
            Required       = $false
            InstallCommand = @{
                Windows = 'pnpm add -g jsonc'
                Linux   = 'pnpm add -g jsonc'
                MacOS   = 'pnpm add -g jsonc'
            }
        }
    }
}
