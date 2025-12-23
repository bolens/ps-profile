# AI Tools Fragment

## Overview

The `ai-tools.ps1` fragment provides wrapper functions for AI and LLM (Large Language Model) command-line tools. It includes functions for running local LLMs, managing AI model servers, and working with AI development tools.

**Tier:** Standard  
**Dependencies:** bootstrap, env

## Functions

### Invoke-OllamaEnhanced

Executes Ollama commands with enhanced functionality. Ollama is a local LLM runner that allows you to run large language models on your machine.

**Alias:** `ollama-enhanced`

**Parameters:**

- `Arguments` (string[], optional): Arguments to pass to ollama command. Can be used multiple times or as an array.

**Examples:**

```powershell
# List available Ollama models
Invoke-OllamaEnhanced list

# Run a prompt with a model
Invoke-OllamaEnhanced run llama2 "Hello, world!"

# Pull a model
Invoke-OllamaEnhanced pull llama2
```

### Invoke-LMStudio

Executes LM Studio CLI commands for managing local LLMs. LM Studio is a desktop application for running LLMs locally, and the CLI provides programmatic access.

**Alias:** `lms`

**Parameters:**

- `Arguments` (string[], optional): Arguments to pass to lms command. Can be used multiple times or as an array.

**Examples:**

```powershell
# List available models
Invoke-LMStudio list

# Start a server
Invoke-LMStudio server start

# Check server status
Invoke-LMStudio server status
```

**Note:** LM Studio CLI (`lms`) is typically installed in `%USERPROFILE%\.lmstudio\bin\lms.exe` or `%USERPROFILE%\.cache\lm-studio\bin\lms.exe`. The function automatically checks these locations if the command is not in PATH.

### Invoke-KoboldCpp

Executes KoboldCpp commands. KoboldCpp is a local LLM inference engine that provides a web interface and API for running LLMs.

**Alias:** `koboldcpp`

**Parameters:**

- `Arguments` (string[], optional): Arguments to pass to koboldcpp command. Can be used multiple times or as an array.

**Examples:**

```powershell
# Start KoboldCpp server
Invoke-KoboldCpp --help

# Run with specific model
Invoke-KoboldCpp --model "path/to/model.gguf"
```

### Invoke-Llamafile

Executes llamafile commands. Llamafile is a tool that packages LLMs as single-file executables, making them easy to distribute and run.

**Alias:** `llamafile`

**Parameters:**

- `Arguments` (string[], optional): Arguments to pass to llamafile command. Can be used multiple times or as an array.

**Examples:**

```powershell
# Run a llamafile
Invoke-Llamafile --help

# Run with specific prompt
Invoke-Llamafile -m model.llamafile -p "Hello, world!"
```

### Invoke-LlamaCpp

Executes llama.cpp commands. llama.cpp is a C/C++ port of Facebook's LLaMA model, optimized for performance.

**Alias:** `llama-cpp`

**Parameters:**

- `Arguments` (string[], optional): Arguments to pass to llama-cpp command. Can be used multiple times or as an array.

**Examples:**

```powershell
# Show help
Invoke-LlamaCpp --help

# Run inference
Invoke-LlamaCpp -m model.gguf -p "Hello, world!"
```

**Note:** The function automatically checks for `llama-cpp-cuda`, `llama-cpp`, and `llama.cpp` commands in order of preference (CUDA version first, then standard, then dot notation).

### Invoke-ComfyUI

Executes ComfyUI CLI commands. ComfyUI is a powerful and modular Stable Diffusion GUI and workflow system.

**Alias:** `comfy`

**Parameters:**

- `Arguments` (string[], optional): Arguments to pass to comfy command. Can be used multiple times or as an array.

**Examples:**

```powershell
# Install ComfyUI
Invoke-ComfyUI install

# Launch ComfyUI
Invoke-ComfyUI launch

# Install a custom node
Invoke-ComfyUI node install "ComfyUI-Manager"
```

**Note:** ComfyUI CLI (`comfy`) is installed via `pip` or `pipx`, not Scoop. The function provides appropriate installation hints.

## Installation

All tools are optional and gracefully degrade when not installed. Install hints are provided when tools are missing.

**Installation via Scoop:**

```powershell
scoop install ollama
scoop install koboldcpp
scoop install llamafile
```

**Installation via other methods:**

- **LM Studio CLI:** Install LM Studio desktop application, which includes the CLI in `%USERPROFILE%\.lmstudio\bin\` or `%USERPROFILE%\.cache\lm-studio\bin\`
- **ComfyUI CLI:** Install via `pip install comfy-cli` or `pipx install comfy-cli`
- **llama.cpp:** Install via Scoop or build from source

## Error Handling

All functions:

- Return `$null` when tools are not available
- Display installation hints when tools are missing
- Handle command execution errors gracefully
- Support pipeline input where appropriate

## Testing

Comprehensive test coverage:

- **Unit tests:** 43/46 passing (93.5% pass rate)
- **Integration tests:** 19/19 passing
- **Performance tests:** 5/5 passing

Test files:

- `tests/unit/profile-ai-tools-*.tests.ps1` (6 test files: ollama, lmstudio, koboldcpp, llamafile, llamacpp, comfyui)
- `tests/integration/tools/ai-tools.tests.ps1`
- `tests/performance/ai-tools-performance.tests.ps1`

## Notes

- All functions use `Test-CachedCommand` for efficient command availability checks
- Functions support pipeline input where appropriate
- `Invoke-LMStudio` automatically checks common installation paths if the command is not in PATH
- `Invoke-LlamaCpp` checks multiple command variants (llama-cpp-cuda, llama-cpp, llama.cpp) in order of preference
- Functions use `&` operator to bypass alias resolution and prevent recursion
- Aliases are created separately from function registration to ensure they persist even if functions already exist
