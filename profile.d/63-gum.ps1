# ===============================================
# 63-gum.ps1
# Terminal UI helpers with gum
# ===============================================

# Gum utility functions
# Requires: gum (https://github.com/charmbracelet/gum)

# Confirm with gum
<#
.SYNOPSIS
    Shows a confirmation prompt using gum.
.DESCRIPTION
    Displays an interactive confirmation dialog using gum. Returns true if confirmed, false otherwise.
#>
function Invoke-GumConfirm {
    param([string]$Prompt = "Continue?")
    gum confirm $Prompt
    return $LASTEXITCODE -eq 0
}
Set-Alias -Name confirm -Value Invoke-GumConfirm -Option AllScope -Force

# Choose from list
<#
.SYNOPSIS
    Shows an interactive selection menu using gum.
.DESCRIPTION
    Displays a list of options for the user to choose from using gum's interactive chooser.
#>
function Invoke-GumChoose {
    param([string[]]$Options, [string]$Prompt = "Choose:")
    if ($Options) {
        $Options | gum choose --header $Prompt
    }
}
Set-Alias -Name choose -Value Invoke-GumChoose -Option AllScope -Force

# Input with gum
<#
.SYNOPSIS
    Shows an input prompt using gum.
.DESCRIPTION
    Displays an interactive input field using gum with optional placeholder text.
#>
function Invoke-GumInput {
    param([string]$Prompt = "Input:", [string]$Placeholder = "")
    gum input --prompt "$Prompt " --placeholder $Placeholder
}
Set-Alias -Name input -Value Invoke-GumInput -Option AllScope -Force

# Spin with gum
<#
.SYNOPSIS
    Shows a spinner while executing a script block using gum.
.DESCRIPTION
    Displays a spinning indicator with a title while executing the provided script block.
#>
function Invoke-GumSpin {
    param([string]$Title = "Working...", [scriptblock]$Script)
    if ($Script) {
        gum spin --title $Title -- $Script
    }
}
Set-Alias -Name spin -Value Invoke-GumSpin -Option AllScope -Force

# Style text
<#
.SYNOPSIS
    Styles text output using gum.
.DESCRIPTION
    Applies foreground and background colors to text using gum's styling capabilities.
#>
function Invoke-GumStyle {
    param([string]$Text, [string]$Foreground = "", [string]$Background = "")
    $args = @()
    if ($Foreground) { $args += "--foreground", $Foreground }
    if ($Background) { $args += "--background", $Background }
    $Text | gum style @args
}
Set-Alias -Name style -Value Invoke-GumStyle -Option AllScope -Force
