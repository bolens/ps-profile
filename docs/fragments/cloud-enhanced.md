# cloud-enhanced.ps1

Enhanced cloud tools and infrastructure fragment.

## Overview

The `cloud-enhanced.ps1` fragment provides enhanced wrapper functions for cloud platforms and infrastructure tools, building on existing `aws.ps1`, `azure.ps1`, and `gcloud.ps1` modules:

- **Azure**: Subscription management and switching
- **GCP**: Project switching and management
- **Doppler**: Secrets management
- **Heroku**: Deployment helpers
- **Vercel**: Deployment helpers
- **Netlify**: Deployment helpers

## Dependencies

- `bootstrap.ps1` - Core bootstrap functions
- `env.ps1` - Environment configuration
- `aws.ps1` - AWS CLI support (optional)
- `azure.ps1` - Azure CLI support (optional)
- `gcloud.ps1` - Google Cloud SDK support (optional)

## Functions

### Set-AzureSubscription

Switches the active Azure subscription.

**Syntax:**

```powershell
Set-AzureSubscription [-SubscriptionId <string>] [-List] [<CommonParameters>]
```

**Parameters:**

- `SubscriptionId` - Subscription ID or name to switch to.
- `List` - List all available subscriptions instead of switching.

**Examples:**

```powershell
# List all available subscriptions
Set-AzureSubscription -List

# Switch to a specific subscription
Set-AzureSubscription -SubscriptionId "my-subscription-id"

# Show current subscription
Set-AzureSubscription
```

**Installation:**

```powershell
scoop install azure-cli
```

---

### Set-GcpProject

Switches the active GCP project.

**Syntax:**

```powershell
Set-GcpProject [-ProjectId <string>] [-List] [<CommonParameters>]
```

**Parameters:**

- `ProjectId` - Project ID to switch to.
- `List` - List all available projects instead of switching.

**Examples:**

```powershell
# List all available projects
Set-GcpProject -List

# Switch to a specific project
Set-GcpProject -ProjectId "my-project-id"

# Show current project
Set-GcpProject
```

**Installation:**

```powershell
scoop install gcloud
```

---

### Get-DopplerSecrets

Retrieves secrets from Doppler.

**Syntax:**

```powershell
Get-DopplerSecrets [-Project <string>] [-Config <string>] [-Secret <string>] [-OutputFormat <string>] [<CommonParameters>]
```

**Parameters:**

- `Project` - Doppler project name.
- `Config` - Doppler config name (e.g., dev, staging, prod).
- `Secret` - Specific secret name to retrieve. If not specified, returns all secrets.
- `OutputFormat` - Output format: json, env, shell. Defaults to env.

**Examples:**

```powershell
# Get all secrets from a project and config
Get-DopplerSecrets -Project "my-project" -Config "dev"

# Get a specific secret
Get-DopplerSecrets -Project "my-project" -Config "prod" -Secret "API_KEY"

# Get secrets in JSON format
Get-DopplerSecrets -Project "my-project" -Config "dev" -OutputFormat "json"
```

**Installation:**

```powershell
scoop install doppler
```

---

### Deploy-Heroku

Deploys to Heroku.

**Syntax:**

```powershell
Deploy-Heroku -AppName <string> [-Action <string>] [-Branch <string>] [<CommonParameters>]
```

**Parameters:**

- `AppName` (Required) - Heroku app name.
- `Action` - Action to perform: deploy, logs, status, restart. Defaults to deploy.
- `Branch` - Git branch to deploy. Defaults to main.

**Examples:**

```powershell
# Deploy the current git repository to Heroku
Deploy-Heroku -AppName "my-app"

# Show Heroku application logs
Deploy-Heroku -AppName "my-app" -Action "logs"

# Check Heroku app status
Deploy-Heroku -AppName "my-app" -Action "status"

# Restart Heroku app
Deploy-Heroku -AppName "my-app" -Action "restart"
```

**Installation:**

```powershell
scoop install heroku-cli
```

---

### Deploy-Vercel

Deploys to Vercel.

**Syntax:**

```powershell
Deploy-Vercel [-Action <string>] [-ProjectPath <string>] [-Production] [<CommonParameters>]
```

**Parameters:**

- `Action` - Action to perform: deploy, list, remove. Defaults to deploy.
- `ProjectPath` - Path to the project directory. Defaults to current directory.
- `Production` - Deploy to production environment.

**Examples:**

```powershell
# Deploy the current project to Vercel
Deploy-Vercel

# Deploy to production environment
Deploy-Vercel -Production

# List Vercel deployments
Deploy-Vercel -Action "list"

# Remove a Vercel deployment
Deploy-Vercel -Action "remove"
```

**Installation:**

```powershell
npm install -g vercel
```

---

### Deploy-Netlify

Deploys to Netlify.

**Syntax:**

```powershell
Deploy-Netlify [-Action <string>] [-ProjectPath <string>] [-Production] [<CommonParameters>]
```

**Parameters:**

- `Action` - Action to perform: deploy, status, open. Defaults to deploy.
- `ProjectPath` - Path to the project directory. Defaults to current directory.
- `Production` - Deploy to production environment.

**Examples:**

```powershell
# Deploy the current project to Netlify
Deploy-Netlify

# Deploy to production environment
Deploy-Netlify -Production

# Check Netlify deployment status
Deploy-Netlify -Action "status"

# Open Netlify site in browser
Deploy-Netlify -Action "open"
```

**Installation:**

```powershell
npm install -g netlify-cli
```

---

## Error Handling

All functions gracefully degrade when tools are not installed:

- Functions check for tool availability using `Test-CachedCommand`
- Missing tools display installation hints using `Write-MissingToolWarning`
- Functions return `$null` when tools are unavailable
- No errors are thrown for missing tools (graceful degradation)

## Installation

Install required tools using Scoop or npm:

```powershell
# Install cloud CLI tools
scoop install azure-cli gcloud doppler heroku-cli

# Install Node.js-based tools
npm install -g vercel netlify-cli

# Or install individually
scoop install azure-cli    # Azure CLI
scoop install gcloud       # Google Cloud SDK
scoop install doppler      # Secrets management
scoop install heroku-cli   # Heroku CLI
npm install -g vercel      # Vercel CLI
npm install -g netlify-cli # Netlify CLI
```

## Testing

The fragment includes comprehensive test coverage:

- **Unit tests**: Individual function tests with mocking
- **Integration tests**: Fragment loading and function registration
- **Performance tests**: Load time and function execution performance

Run tests:

```powershell
# Run unit tests
pwsh -NoProfile -File scripts/utils/code-quality/analyze-coverage.ps1 -Path profile.d/cloud-enhanced.ps1

# Run integration tests
Invoke-Pester tests/integration/tools/cloud-enhanced.tests.ps1

# Run performance tests
Invoke-Pester tests/performance/cloud-enhanced-performance.tests.ps1
```

## Notes

- All functions are idempotent and can be safely called multiple times
- Functions use `Set-AgentModeFunction` for registration
- This module enhances existing cloud modules (aws.ps1, azure.ps1, gcloud.ps1)
- Azure and GCP functions require authentication before use
- Heroku deployments use git push to heroku remote
- Vercel and Netlify require npm/node.js to be installed
- Doppler secrets can be exported in multiple formats for different use cases
