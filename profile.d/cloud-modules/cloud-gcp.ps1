# ===============================================
# cloud-gcp.ps1
# GCP cloud helpers
# ===============================================
# Tier: standard
# Dependencies: bootstrap, env, gcloud
<#
.SYNOPSIS
    GCP cloud helpers
.DESCRIPTION
    Set-GcpProject wrapper.
.NOTES
    Loaded by cloud-enhanced.ps1 or directly.
#>
try {
    if (Get-Command Test-FragmentLoaded -ErrorAction SilentlyContinue) {
        if (Test-FragmentLoaded -FragmentName 'cloud-gcp') { return }
    }
    # ===============================================
    # Set-GcpProject - Switch GCP project
    # ===============================================

    <#
    .SYNOPSIS
        Switches the active GCP project.
    

    .DESCRIPTION
        Changes the active Google Cloud Platform project for the current session.
        Uses gcloud to list and set projects.
    

    .PARAMETER ProjectId
        Project ID to switch to.
    

    .PARAMETER List
        List all available projects instead of switching.
    

    .OUTPUTS
        System.String. Project information or list of projects.

    .EXAMPLE
        Set-GcpProject -ProjectId "my-project-id"
        
        Switches to the specified project.
    

    .EXAMPLE
        Set-GcpProject -List
        
        Lists all available projects.
    #>
    function Set-GcpProject {
        [CmdletBinding()]
        [OutputType([string])]
        param(
            [string]$ProjectId,
            
            [switch]$List
        )

        if (-not (Test-CachedCommand 'gcloud')) {
            Invoke-MissingToolWarning -ToolName 'gcloud'
            return
        }

        if (Get-Command Invoke-WithWideEvent -ErrorAction SilentlyContinue) {
            return Invoke-WithWideEvent -OperationName 'cloud.gcp.project.manage' -Context @{
                action     = if ($List) { 'list' } elseif ($ProjectId) { 'set' } else { 'show' }
                project_id = $ProjectId
            } -ScriptBlock {
                if ($List) {
                    $output = & gcloud projects list 2>&1
                    if ($LASTEXITCODE -ne 0) {
                        throw "Failed to list projects. Exit code: $LASTEXITCODE"
                    }
                    return $output
                }
                elseif ($ProjectId) {
                    $output = & gcloud config set project $ProjectId 2>&1
                    if ($LASTEXITCODE -ne 0) {
                        throw "Failed to switch project. Exit code: $LASTEXITCODE"
                    }
                    Write-Host "Switched to project: $ProjectId" -ForegroundColor Green
                    return $output
                }
                else {
                    # Show current project
                    $output = & gcloud config get-value project 2>&1
                    if ($LASTEXITCODE -ne 0) {
                        throw "Failed to get current project. Exit code: $LASTEXITCODE"
                    }
                    return $output
                }
            }
        }
        else {
            try {
                if ($List) {
                    $output = & gcloud projects list 2>&1
                    if ($LASTEXITCODE -eq 0) {
                        return $output
                    }
                    else {
                        Write-Error "Failed to list projects. Exit code: $LASTEXITCODE"
                    }
                }
                elseif ($ProjectId) {
                    $output = & gcloud config set project $ProjectId 2>&1
                    if ($LASTEXITCODE -eq 0) {
                        Write-Host "Switched to project: $ProjectId" -ForegroundColor Green
                        return $output
                    }
                    else {
                        Write-Error "Failed to switch project. Exit code: $LASTEXITCODE"
                    }
                }
                else {
                    # Show current project
                    $output = & gcloud config get-value project 2>&1
                    if ($LASTEXITCODE -eq 0) {
                        return $output
                    }
                    else {
                        Write-Error "Failed to get current project. Exit code: $LASTEXITCODE"
                    }
                }
            }
            catch {
                Write-Error "Failed to run gcloud command: $_"
            }
        }
    }
    if (Get-Command Set-FragmentLoaded -ErrorAction SilentlyContinue) {
        Set-FragmentLoaded -FragmentName 'cloud-gcp'
    }
}
catch {
    if (Get-Command Write-ProfileError -ErrorAction SilentlyContinue) {
        Write-ProfileError -FragmentName 'cloud-gcp' -ErrorRecord $_
    }
    else {
        Write-Error "Failed to load cloud-gcp: "
    }
}
