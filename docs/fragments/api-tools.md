# API Tools Fragment

## Overview

The `api-tools.ps1` fragment provides wrapper functions for API development, testing, and debugging tools. It includes functions for API clients, HTTP testing, and debugging proxies.

**Tier:** Standard  
**Dependencies:** bootstrap, env

## Functions

### Invoke-Bruno

Runs Bruno API collections for testing REST APIs. Bruno is a lightweight, fast, and modern API client.

**Alias:** `bruno`

**Parameters:**

- `CollectionPath` (string, optional): Path to the Bruno collection file or directory. Defaults to current directory.
- `Environment` (string, optional): Environment name to use for the collection.

**Examples:**

```powershell
# Run collection in current directory
Invoke-Bruno

# Run specific collection
Invoke-Bruno -CollectionPath "C:\API\MyCollection"

# Run with specific environment
Invoke-Bruno -CollectionPath "C:\API\MyCollection" -Environment "production"
```

### Invoke-Hurl

Executes Hurl test files for HTTP testing. Hurl is a command-line tool that runs HTTP requests defined in a simple plain text format.

**Alias:** `hurl`

**Parameters:**

- `TestFile` (string, mandatory): Path to the Hurl test file (.hurl).
- `Variable` (string[], optional): Set variables for the test execution (can be used multiple times). Format: "name=value"
- `Output` (string, optional): Output file path for the response.

**Examples:**

```powershell
# Run a Hurl test file
Invoke-Hurl -TestFile "C:\Tests\api-tests.hurl"

# Run with variables
Invoke-Hurl -TestFile "C:\Tests\api-tests.hurl" -Variable "base_url=https://api.example.com", "token=abc123"

# Run with output file
Invoke-Hurl -TestFile "C:\Tests\api-tests.hurl" -Output "C:\Results\response.json"
```

### Invoke-Httpie

Makes HTTP requests using httpie, a user-friendly command-line HTTP client. Supports GET, POST, PUT, DELETE, PATCH, and other HTTP methods.

**Alias:** `httpie`

**Parameters:**

- `Method` (string, optional): HTTP method (GET, POST, PUT, DELETE, PATCH, etc.). Defaults to GET.
- `Url` (string, mandatory): The URL to request.
- `Body` (string, optional): Request body (for POST, PUT, PATCH requests).
- `Header` (string[], optional): Custom headers (can be used multiple times). Format: "Header-Name: value"
- `Output` (string, optional): Output file path for the response.

**Examples:**

```powershell
# GET request
Invoke-Httpie -Url "https://api.example.com/users"

# POST request with JSON body
Invoke-Httpie -Method POST -Url "https://api.example.com/users" -Body '{"name":"John"}'

# Request with custom headers
Invoke-Httpie -Url "https://api.example.com/data" -Header "Authorization: Bearer token", "Content-Type: application/json"

# Save response to file
Invoke-Httpie -Url "https://api.example.com/data" -Output "C:\Results\response.json"
```

### Start-HttpToolkit

Starts HTTP Toolkit, an HTTP debugging proxy that intercepts and inspects HTTP/HTTPS traffic. Useful for debugging API calls, inspecting requests/responses, and testing applications.

**Alias:** `httptoolkit`

**Parameters:**

- `Port` (int, optional): Port number for the proxy server. Defaults to 8000.
- `Passthrough` (switch): If specified, starts the proxy in passthrough mode (does not intercept traffic).

**Examples:**

```powershell
# Start HTTP Toolkit on default port (8000)
Start-HttpToolkit

# Start on custom port
Start-HttpToolkit -Port 9000

# Start in passthrough mode
Start-HttpToolkit -Passthrough
```

## Installation

All tools are optional and gracefully degrade when not installed. Install hints are provided when tools are missing.

**Installation via Scoop:**

```powershell
scoop install bruno
scoop install hurl
scoop install httpie
scoop install httptoolkit
```

## Error Handling

All functions:

- Return `$null` when tools are not available
- Display installation hints when tools are missing
- Handle command execution errors gracefully
- Validate input paths before execution
- Support pipeline input where appropriate

## Testing

Comprehensive test coverage:

- **Unit tests:** 29/29 passing (100% pass rate)
- **Integration tests:** 14/14 passing
- **Performance tests:** 5/5 passing

Test files:

- `tests/unit/profile-api-tools-*.tests.ps1` (4 test files: bruno, hurl, httpie, httptoolkit)
- `tests/integration/tools/api-tools.tests.ps1`
- `tests/performance/api-tools-performance.tests.ps1`

## Notes

- All functions use `Test-CachedCommand` for efficient command availability checks
- Functions support pipeline input where appropriate
- `Invoke-Httpie` defaults to GET method if not specified
- `Start-HttpToolkit` returns a Process object for the proxy server
- Functions use `&` operator to bypass alias resolution and prevent recursion
