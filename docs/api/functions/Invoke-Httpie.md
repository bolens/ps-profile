# Invoke-Httpie

## Synopsis

Makes HTTP requests using httpie.

## Description

Executes HTTP requests using httpie, a user-friendly command-line HTTP client. Supports GET, POST, PUT, DELETE, PATCH, and other HTTP methods.

## Signature

```powershell
Invoke-Httpie
```

## Parameters

### -Method

HTTP method (GET, POST, PUT, DELETE, PATCH, etc.). Defaults to GET if not specified.

### -Url

The URL to request.

### -Body

Request body (for POST, PUT, PATCH requests).

### -Header

Custom headers (can be used multiple times). Format: "Header-Name: value"

### -Output

Output file path for the response.


## Outputs

System.String. HTTP response from httpie.


## Examples

### Example 1

`powershell
Invoke-Httpie -Method GET -Url "https://api.example.com/users"
        Makes a GET request to the specified URL.
``

### Example 2

`powershell
Invoke-Httpie -Method POST -Url "https://api.example.com/users" -Body '{"name":"John"}'
        Makes a POST request with a JSON body.
``

## Aliases

This function has the following aliases:

- `httpie` - Makes HTTP requests using httpie.


## Source

Defined in: ..\profile.d\api-tools.ps1
