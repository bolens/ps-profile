# Start-MongoDbCompass

## Synopsis

Launches MongoDB Compass GUI.

## Description

Opens MongoDB Compass, a GUI tool for MongoDB database management and visualization. MongoDB Compass allows you to explore, query, and manage MongoDB databases.

## Signature

```powershell
Start-MongoDbCompass
```

## Parameters

### -ConnectionString

Optional MongoDB connection string to open directly.


## Outputs

System.Diagnostics.Process. Process object for MongoDB Compass.


## Examples

### Example 1

`powershell
Start-MongoDbCompass
        Launches MongoDB Compass GUI.
``

### Example 2

`powershell
Start-MongoDbCompass -ConnectionString "mongodb://localhost:27017"
        Launches MongoDB Compass with a connection string.
``

## Aliases

This function has the following aliases:

- `mongodb-compass` - Launches MongoDB Compass GUI.


## Source

Defined in: ..\profile.d\database-clients.ps1
