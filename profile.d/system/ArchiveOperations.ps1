# ===============================================
# ArchiveOperations.ps1
# Archive operation utilities
# ===============================================

# unzip equivalent
<#
.SYNOPSIS
    Extracts ZIP archives.
.DESCRIPTION
    Extracts files from ZIP archives to specified destinations.
#>
function Expand-ArchiveCustom { Expand-Archive @args }
Set-Alias -Name unzip -Value Expand-ArchiveCustom -ErrorAction SilentlyContinue

# zip equivalent
<#
.SYNOPSIS
    Creates ZIP archives.
.DESCRIPTION
    Compresses files and directories into ZIP archives.
#>
function Compress-ArchiveCustom { & Compress-Archive @args }
Set-Alias -Name zip -Value Compress-ArchiveCustom -ErrorAction SilentlyContinue

