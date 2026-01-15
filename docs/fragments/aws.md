# aws.ps1

AWS CLI helpers fragment.

## Overview

This fragment provides PowerShell functions and aliases for common AWS CLI operations. Functions check for AWS CLI availability and gracefully degrade when the tool is not installed. Enhanced functions provide credential management, connection testing, resource listing, and cost estimation capabilities.

## Functions

### Invoke-Aws

Executes AWS CLI commands.

**Syntax:**

```powershell
Invoke-Aws [<Arguments>] [<CommonParameters>]
```

**Parameters:**

- `Arguments` (ValueFromRemainingArguments): Arguments to pass to AWS CLI.

**Examples:**

```powershell
# List S3 buckets
Invoke-Aws s3 ls

# Describe EC2 instances
Invoke-Aws ec2 describe-instances

# List Lambda functions
Invoke-Aws lambda list-functions
```

**Supported Tools:**

- `aws` - AWS CLI (required)

**Notes:**

- Wrapper function for AWS CLI that checks for command availability
- Returns output from AWS CLI command
- Returns nothing and displays warning if AWS CLI is not installed

---

### Set-AwsProfile

Sets the AWS profile environment variable.

**Syntax:**

```powershell
Set-AwsProfile [-ProfileName] <string> [<CommonParameters>]
```

**Parameters:**

- `-ProfileName` (Mandatory): Name of the AWS profile to use.

**Examples:**

```powershell
# Set profile to production
Set-AwsProfile -ProfileName "production"

# Set profile to development
Set-AwsProfile "development"
```

**Supported Tools:**

- `aws` - AWS CLI (required)

**Notes:**

- Sets `$env:AWS_PROFILE` environment variable
- Returns nothing on success

---

### Set-AwsRegion

Sets the AWS region environment variable.

**Syntax:**

```powershell
Set-AwsRegion [-Region] <string> [<CommonParameters>]
```

**Parameters:**

- `-Region` (Mandatory): AWS region name (e.g., "us-east-1", "eu-west-1").

**Examples:**

```powershell
# Set region to us-east-1
Set-AwsRegion -Region "us-east-1"

# Set region to eu-west-1
Set-AwsRegion "eu-west-1"
```

**Supported Tools:**

- `aws` - AWS CLI (required)

**Notes:**

- Sets `$env:AWS_REGION` environment variable
- Returns nothing on success

---

### Get-AwsCredentials

Lists configured AWS credential profiles.

**Syntax:**

```powershell
Get-AwsCredentials [-ShowKeys] [<CommonParameters>]
```

**Parameters:**

- `-ShowKeys` (Switch): Show access key IDs (partially masked) for each profile.

**Examples:**

```powershell
# List all configured profiles
Get-AwsCredentials

# List profiles with masked access keys
Get-AwsCredentials -ShowKeys
```

**Output:**

Returns an array of objects with the following properties:

- `ProfileName` (string): Profile name
- `AccessKeyId` (string): Partially masked access key ID (only when `-ShowKeys` is used)

**Supported Tools:**

- `aws` - AWS CLI (required)

**Notes:**

- Reads from `~/.aws/credentials` file
- Falls back to `aws configure list-profiles` if credentials file doesn't exist
- Returns empty array if no profiles are found

---

### Test-AwsConnection

Tests AWS connectivity and credentials.

**Syntax:**

```powershell
Test-AwsConnection [-Profile <string>] [<CommonParameters>]
```

**Parameters:**

- `-Profile` (Optional): AWS profile to test. Uses current profile if not specified.

**Examples:**

```powershell
# Test connection with current profile
Test-AwsConnection

# Test connection with specific profile
Test-AwsConnection -Profile "production"
```

**Output:**

Returns `$true` if connection is successful, `$false` otherwise.

**Supported Tools:**

- `aws` - AWS CLI (required)

**Notes:**

- Uses `aws sts get-caller-identity` to test authentication
- Displays account and user information on success
- Returns `$false` if credentials are invalid or missing

---

### Get-AwsResources

Lists AWS resources by type.

**Syntax:**

```powershell
Get-AwsResources -Service <string> -Action <string> [<CommonParameters>]
```

**Parameters:**

- `-Service` (Mandatory): AWS service name (e.g., 'ec2', 's3', 'lambda').
- `-Action` (Mandatory): Service action to list resources (e.g., 'describe-instances', 'list-buckets').

**Examples:**

```powershell
# List EC2 instances
Get-AwsResources -Service 'ec2' -Action 'describe-instances'

# List S3 buckets
Get-AwsResources -Service 's3' -Action 'list-buckets'

# List Lambda functions
Get-AwsResources -Service 'lambda' -Action 'list-functions'
```

**Output:**

Returns parsed JSON output from AWS CLI, or raw output if JSON parsing fails.

**Supported Tools:**

- `aws` - AWS CLI (required)

**Notes:**

- Attempts to parse output as JSON
- Falls back to raw output if JSON parsing fails
- Returns nothing on error

---

### Export-AwsCredentials

Exports AWS credentials to environment variables.

**Syntax:**

```powershell
Export-AwsCredentials [-Profile <string>] [-ExportToEnv] [<CommonParameters>]
```

**Parameters:**

- `-Profile` (Optional): AWS profile name to export. Uses current profile if not specified.
- `-ExportToEnv` (Switch): Export to environment variables (default). If false, only displays values.

**Examples:**

```powershell
# Export current profile credentials
Export-AwsCredentials

# Export specific profile credentials
Export-AwsCredentials -Profile "production"

# Display credentials without exporting
Export-AwsCredentials -ExportToEnv:$false
```

**Output:**

Returns an object with the following properties:

- `AccessKeyId` (string): AWS access key ID
- `SecretAccessKey` (string): AWS secret access key
- `Region` (string): AWS region (if configured)

**Supported Tools:**

- `aws` - AWS CLI (required)

**Notes:**

- Exports to `$env:AWS_ACCESS_KEY_ID`, `$env:AWS_SECRET_ACCESS_KEY`, and `$env:AWS_REGION`
- Useful for scripts that need AWS credentials but don't use profiles
- Returns nothing on error

---

### Switch-AwsAccount

Switches AWS account/profile quickly.

**Syntax:**

```powershell
Switch-AwsAccount -ProfileName <string> [-SkipTest] [<CommonParameters>]
```

**Parameters:**

- `-ProfileName` (Mandatory): Name of the AWS profile to switch to.
- `-SkipTest` (Switch): Skip connection test after switching.

**Examples:**

```powershell
# Switch to production profile and test connection
Switch-AwsAccount -ProfileName "production"

# Switch to dev profile without testing
Switch-AwsAccount -ProfileName "dev" -SkipTest
```

**Output:**

Returns `$true` if switch (and test, if not skipped) is successful, `$false` otherwise.

**Supported Tools:**

- `aws` - AWS CLI (required)

**Notes:**

- Combines `Set-AwsProfile` and `Test-AwsConnection` for convenience
- Verifies connectivity after switching unless `-SkipTest` is used
- Returns `$false` if profile switch or connection test fails

---

### Get-AwsCosts

Gets AWS cost information.

**Syntax:**

```powershell
Get-AwsCosts [-StartDate <string>] [-EndDate <string>] [-Service <string>] [<CommonParameters>]
```

**Parameters:**

- `-StartDate` (Optional): Start date for cost query (YYYY-MM-DD format). Defaults to first day of current month.
- `-EndDate` (Optional): End date for cost query (YYYY-MM-DD format). Defaults to today.
- `-Service` (Optional): Service name to filter costs (e.g., 'EC2', 'S3', 'Lambda').

**Examples:**

```powershell
# Get costs for current month
Get-AwsCosts

# Get costs for specific date range
Get-AwsCosts -StartDate "2024-01-01" -EndDate "2024-01-31"

# Get EC2 costs for current month
Get-AwsCosts -Service "EC2"
```

**Output:**

Returns cost information from AWS Cost Explorer API as JSON object, or `$null` if Cost Explorer is not available or lacks permissions.

**Supported Tools:**

- `aws` - AWS CLI (required)
- AWS Cost Explorer API access (requires IAM permissions)

**Notes:**

- Requires `ce:GetCostAndUsage` IAM permission
- Cost Explorer must be enabled in your AWS account
- Returns `$null` if Cost Explorer is not available or you lack permissions
- Defaults to current month if dates are not specified

---

## Aliases

The following aliases are available:

- `aws` → `Invoke-Aws`
- `aws-profile` → `Set-AwsProfile`
- `aws-region` → `Set-AwsRegion`
- `aws-credentials` → `Get-AwsCredentials`
- `aws-test` → `Test-AwsConnection`
- `aws-switch` → `Switch-AwsAccount`

## Installation

Install AWS CLI via Scoop:

```powershell
scoop install aws
```

Or download from: https://aws.amazon.com/cli/

## Configuration

Configure AWS credentials:

```powershell
aws configure
```

Or set up profiles:

```powershell
aws configure --profile production
```

## Graceful Degradation

All functions gracefully handle missing tools:

- Functions return `$null` or empty results when AWS CLI is not installed
- Warning messages are displayed with installation hints
- No errors are thrown for missing tools (unless `-ErrorAction Stop` is used)

## Performance

- Fragment load time: < 1000ms
- Function execution: < 1000ms (for credential parsing and file operations)
- Idempotent: Safe to load multiple times

## See Also

- [cloud-enhanced.ps1](cloud-enhanced.md) - Enhanced cloud provider functions
- [azure.ps1](azure.md) - Azure CLI helpers
- [gcloud.ps1](gcloud.md) - Google Cloud CLI helpers
