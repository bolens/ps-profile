# Security Policy

## Reporting a vulnerability

Please report suspected vulnerabilities through GitHub's private vulnerability
reporting feature when it is available. Otherwise, contact the maintainer
privately through the contact details on their GitHub profile. Do not open a
public issue for an unpatched vulnerability.

Include the affected command or fragment, supported platforms, reproduction
steps, potential impact, and any suggested mitigation. Reports will be
acknowledged as soon as practical and coordinated disclosure will be preferred.

## Supported versions

This profile is under active development. Security fixes are applied to the
latest revision of the `main` branch; older revisions are not maintained.

## Security controls

PowerShell source is checked with PSScriptAnalyzer and the repository security
scanner. GitHub Actions workflows are analyzed separately with CodeQL.
