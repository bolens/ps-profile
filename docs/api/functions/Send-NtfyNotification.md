# Send-NtfyNotification

## Synopsis

Sends a push notification using ntfy.

## Description

Sends push notifications to devices using the ntfy service. Supports custom topics, priorities, and message formatting.

## Signature

```powershell
Send-NtfyNotification
```

## Parameters

### -Message

Notification message text.

### -Topic

Ntfy topic name. Defaults to a random topic if not specified.

### -Title

Optional notification title.

### -Priority

Notification priority: low, default, high, urgent. Defaults to default.

### -Server

Optional ntfy server URL. Defaults to ntfy.sh.


## Outputs

System.String. Notification delivery status.


## Examples

### Example 1

`powershell
Send-NtfyNotification -Message "Task completed successfully"
        
        Sends a notification with the specified message.
``

### Example 2

`powershell
Send-NtfyNotification -Message "Alert!" -Title "System Alert" -Priority "urgent" -Topic "alerts"
        
        Sends an urgent notification to the alerts topic.
``

## Source

Defined in: ..\profile.d\network-analysis.ps1
