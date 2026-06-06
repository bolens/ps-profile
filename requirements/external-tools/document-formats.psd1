@{
    # Document Format Conversion Tools
    # Dependencies for document format conversions (Markdown, RST, LaTeX, Textile, FB2, DjVu, etc.)
    ExternalTools = @{
        'pandoc'      = @{
            Version        = 'latest'
            Description    = 'Universal document converter (required for document format conversions: Markdown, RST, LaTeX, Textile, FB2, etc.)'
            Required       = $false
            InstallCommand = @{
                Windows = 'scoop install pandoc'
                Linux   = 'apt install pandoc'
                MacOS   = 'brew install pandoc'
            }
        }
        'calibre'     = @{
            Version        = 'latest'
            Description    = 'E-book management and conversion tool (required for FB2, MOBI/AZW conversions)'
            Required       = $false
            InstallCommand = @{
                Windows = 'scoop install calibre'
                Linux   = 'apt install calibre'
                MacOS   = 'brew install calibre'
            }
        }
        'djvulibre'   = @{
            Version        = 'latest'
            Description    = 'DjVu document format tools (djvutxt, djvused, c44, etc. - required for DjVu conversions)'
            Required       = $false
            InstallCommand = @{
                Windows = 'scoop install djvulibre'
                Linux   = 'apt install djvulibre-bin'
                MacOS   = 'brew install djvulibre'
            }
        }
        'ImageMagick' = @{
            Version        = 'latest'
            Description    = 'Image manipulation and conversion tool (required for image format conversions: WebP, AVIF, HEIC, ICO, BMP, TIFF, DjVu)'
            Required       = $false
            InstallCommand = @{
                Windows = 'scoop install imagemagick'
                Linux   = 'apt install imagemagick'
                MacOS   = 'brew install imagemagick'
            }
        }
        'notion2md'   = @{
            Version        = 'latest'
            Description    = 'Export Notion pages to Markdown via the Notion API (Export-NotionPageToMarkdown)'
            Required       = $false
            InstallCommand = @{
                Windows = 'pip install notion2md'
                Linux   = 'pip install notion2md'
                MacOS   = 'pip install notion2md'
            }
        }
        'notionify-cli' = @{
            Version        = 'latest'
            Description    = 'Bidirectional Markdown ↔ Notion conversion CLI (Invoke-NotionifyCli, Export-NotionPageToMarkdown)'
            Required       = $false
            InstallCommand = @{
                Windows = 'pip install notionify'
                Linux   = 'pip install notionify'
                MacOS   = 'pip install notionify'
            }
        }
        'notion2markdown' = @{
            Version        = 'latest'
            Description    = 'Export Notion pages and databases to Markdown with YAML front matter'
            Required       = $false
            InstallCommand = @{
                Windows = 'pip install notion2markdown'
                Linux   = 'pip install notion2markdown'
                MacOS   = 'pip install notion2markdown'
            }
        }
        'job'         = @{
            Version        = 'latest'
            Description    = 'Joplin-Obsidian bridge CLI for bidirectional note sync (Sync-JoplinObsidianNotes)'
            Required       = $false
            InstallCommand = @{
                Windows = 'pip install joplin-obsidian-bridge'
                Linux   = 'pip install joplin-obsidian-bridge'
                MacOS   = 'pip install joplin-obsidian-bridge'
            }
        }
    }
}

