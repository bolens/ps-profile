# Set-AzureSubscription

## Synopsis

Switches the active Azure subscription.

## Description

Changes the active Azure subscription for the current session. Uses Azure CLI to list and set subscriptions.

## Signature

```powershell
Set-AzureSubscription
```

## Parameters

### -SubscriptionId

Subscription ID or name to switch to.

### -List

List all available subscriptions instead of switching.


## Outputs

System.String. Subscription information or list of subscriptions.


## Examples

### Example 1

`powershell
Set-AzureSubscription -SubscriptionId "my-subscription-id"
        
        Switches to the specified subscription.
``

### Example 2

`powershell
Set-AzureSubscription -List
        
        Lists all available subscriptions.
``

## Source

Defined in: ..\profile.d\cloud-enhanced.ps1
