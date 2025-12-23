# lang-java.ps1

Enhanced Java development tools fragment.

## Overview

The `lang-java.ps1` fragment provides wrapper functions for Java development tools including build tools (Maven, Gradle, Ant), compilers (Kotlin, Scala), and Java version management.

## Dependencies

- **bootstrap** - Core helper functions (`Set-AgentModeFunction`, `Set-AgentModeAlias`, `Test-CachedCommand`)
- **env** - Environment configuration

## Functions

### Build-Maven

Builds Java projects using Maven.

**Syntax:**

```powershell
Build-Maven [[-Arguments] <string[]>]
```

**Parameters:**

- `Arguments` (optional) - Additional arguments to pass to mvn. Can be used multiple times or as an array.

**Examples:**

```powershell
# Build the current Maven project
Build-Maven

# Clean and install the project
Build-Maven clean install

# Run Maven tests
Build-Maven test
```

**Aliases:**

- `mvn`

**Tool:**

- **maven** - Build automation tool for Java projects
  - Installation: `scoop install maven`

### Build-Gradle

Builds Java projects using Gradle.

**Syntax:**

```powershell
Build-Gradle [[-Arguments] <string[]>]
```

**Parameters:**

- `Arguments` (optional) - Additional arguments to pass to gradle. Can be used multiple times or as an array.

**Examples:**

```powershell
# Build the current Gradle project
Build-Gradle

# Build the project
Build-Gradle build

# Run Gradle tests
Build-Gradle test
```

**Aliases:**

- `gradle`

**Tool:**

- **gradle** - Build automation tool for Java projects
  - Installation: `scoop install gradle`

### Build-Ant

Builds Java projects using Apache Ant.

**Syntax:**

```powershell
Build-Ant [[-Arguments] <string[]>]
```

**Parameters:**

- `Arguments` (optional) - Additional arguments to pass to ant. Can be used multiple times or as an array.

**Examples:**

```powershell
# Build the current Ant project
Build-Ant

# Clean the project
Build-Ant clean

# Run Ant tests
Build-Ant test
```

**Aliases:**

- `ant`

**Tool:**

- **ant** - Build tool for Java projects
  - Installation: `scoop install ant`

### Compile-Kotlin

Compiles Kotlin code.

**Syntax:**

```powershell
Compile-Kotlin [[-Arguments] <string[]>]
```

**Parameters:**

- `Arguments` (optional) - Additional arguments to pass to kotlinc. Can be used multiple times or as an array.

**Examples:**

```powershell
# Compile Main.kt
Compile-Kotlin Main.kt

# Compile with runtime included into a JAR
Compile-Kotlin -include-runtime -d app.jar Main.kt
```

**Aliases:**

- `kotlinc`

**Tool:**

- **kotlin** - Kotlin compiler
  - Installation: `scoop install kotlin`

### Compile-Scala

Compiles Scala code.

**Syntax:**

```powershell
Compile-Scala [[-Arguments] <string[]>]
```

**Parameters:**

- `Arguments` (optional) - Additional arguments to pass to scalac. Can be used multiple times or as an array.

**Examples:**

```powershell
# Compile Main.scala
Compile-Scala Main.scala

# Compile to a specific output directory
Compile-Scala -d classes Main.scala
```

**Aliases:**

- `scalac`

**Tool:**

- **scala** - Scala compiler
  - Installation: `scoop install scala`

### Set-JavaVersion

Switches Java version using JAVA_HOME.

**Syntax:**

```powershell
Set-JavaVersion [[-Version] <string>] [[-JavaHome] <string>]
```

**Parameters:**

- `Version` (optional) - Java version to switch to (e.g., '17', '21', '11'). If not specified, displays current Java version.
- `JavaHome` (optional) - Full path to Java installation directory. If not specified, attempts to find Java in common locations.

**Examples:**

```powershell
# Show current Java version
Set-JavaVersion

# Switch to Java 17 (if available)
Set-JavaVersion -Version 17

# Set JAVA_HOME to a specific path
Set-JavaVersion -JavaHome "C:\Program Files\Java\jdk-17"
```

**Tool:**

- **java** - Java runtime (built-in or via temurin-jdk/temurin-jre or microsoft-openjdk/microsoft-openjre)
  - Installation:
    - `scoop install temurin-jdk` or `scoop install temurin-jre` (Eclipse Temurin)
    - `scoop install microsoft-openjdk` or `scoop install microsoft-openjre` (Microsoft OpenJDK)
    - Or download from [Adoptium](https://adoptium.net/) or [Microsoft OpenJDK](https://learn.microsoft.com/java/openjdk/download)

**Notes:**

- `Set-JavaVersion` follows Java standard conventions:
  1. **Checks environment variables first** (highest priority):
     - `JAVA_HOME` - Standard Java home directory
     - `JRE_HOME` - Java Runtime Environment home
     - `JDK_HOME` - Java Development Kit home
  2. **Searches common installation paths**:
     - Standard locations: `C:\Program Files\Java\jdk-<version>`
     - Eclipse Adoptium (Temurin): `%LOCALAPPDATA%\Programs\Eclipse Adoptium\jdk-<version>*`
     - Microsoft OpenJDK: `C:\Program Files\Microsoft\jdk-<version>`
  3. **Package manager installations**:
     - **Scoop**: `%SCOOP%\apps\temurin-jdk\current`, `%SCOOP%\apps\microsoft-openjdk\current`, etc.
     - **Chocolatey**: `%ChocolateyInstall%\lib\temurin*`, `%ChocolateyInstall%\lib\microsoft-openjdk*`, etc.
- If multiple versions are found, the first match is used
- Use `-JavaHome` to specify a custom installation path
- When called without parameters, displays current `JAVA_HOME`, `JRE_HOME`, and `JDK_HOME` values

## Error Handling

All functions gracefully handle missing tools by:

1. Checking tool availability using `Test-CachedCommand`
2. Displaying a helpful warning with installation instructions
3. Returning `$null` instead of throwing errors

This ensures the profile continues to load even when tools are not installed.

## Idempotency

The fragment is idempotent and can be safely loaded multiple times. Functions and aliases are only registered if they don't already exist.

## Performance

- Uses `Test-CachedCommand` for efficient command detection without triggering module autoload
- Functions are registered lazily (only when needed)
- Fragment loading is optimized for fast startup times

## Related Fragments

- **scoop.ps1**, **npm.ps1**, **pip.ps1** - Package management utilities (may include Java-related package managers)

## Notes

- All functions follow PowerShell best practices with proper error handling
- Install hints are provided when tools are missing
- Functions use `Write-MissingToolWarning` for consistent error messaging
- `Set-JavaVersion` searches common Java installation locations but may require manual path specification for custom installations

