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
Set-AgentModeAlias -Name 'unzip' -Target 'Expand-ArchiveCustom'
# zip equivalent
<#
.SYNOPSIS
    Creates ZIP archives.
.DESCRIPTION
    Compresses files and directories into ZIP archives.
#>
function Compress-ArchiveCustom { & Compress-Archive @args }
Set-AgentModeAlias -Name 'zip' -Target 'Compress-ArchiveCustom'