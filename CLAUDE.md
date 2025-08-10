# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Architecture

This is a Docker-based development environment runner that creates containerized Python/Node.js development environments. The project consists of:

- **Dockerfile**: Defines a Python 3.10 development container with Node.js and essential dev tools
- **Makefile**: Handles Docker image building and deployment with cross-platform compatibility  
- **Launch Script** (`run.sh`): Interactive script with advanced container lifecycle management, user permission mapping, and agent installation support
- **Agent System** (`agents/`): Modular agent installation scripts (e.g., `claude-code.sh`) that can be dynamically loaded during container startup

## Common Commands

### Building the Docker Image
```bash
make build
```
This builds the Docker image with proper user permissions, saves it as a tar file, and imports it to containerd.

### Launching Development Environment
```bash
./run.sh [project-name] [host-port] [--agent agent-name]
```
- Creates a new development container or connects to existing one
- Mounts current directory and home directory
- Sets up proper user permissions matching host system
- Default project name: `python-agent`, default port: `8000`
- Optionally installs agents (e.g., `--agent claude-code`)

### Full Build and Deploy Pipeline
```bash
make all
```
Runs clean, build, and deploy in sequence.

### Cleanup
```bash
make clean
```
Removes the generated Docker tar file.

### Alternative npm Scripts
The project also includes npm scripts for convenience:
```bash
npm run build    # Equivalent to make build
npm run dev      # Launches development environment
npm start        # Same as npm run dev
npm run clean    # Equivalent to make clean
npm run deploy   # Equivalent to make deploy
```

## Development Environment Features

The containerized environment includes:
- Python 3.10 with virtualenv at `/opt/venv`
- Node.js LTS with npm configured for user-local packages
- Essential tools: pytest, pytest-cov, uv, git, openssh-client
- Dynamic agent installation system (Claude Code, etc.)
- Automatic user/group mapping for seamless file permissions
- SSH key and home directory mounting for Git authentication
- Project directory mounted at `/$PROJECT_NAME`
- Cross-platform user permission handling (Linux/macOS/Windows)
- Persistent agent storage with automatic PATH configuration

## Architecture Notes

- Uses multi-stage user setup to handle permission mapping between host and container
- Implements proper cleanup and error handling in the launch script  
- Supports both new container creation and reconnection to existing containers
- Agent system allows modular installation of development tools during runtime
- Cross-platform Makefile with OS detection for Windows/Unix compatibility
- Intelligent container lifecycle management with user prompts for existing containers

## Agent System

The `agents/` directory contains modular setup scripts that provide persistent agent installations:
- **Persistent Storage**: Agents are installed to `~/.python-agent-runner/agents-data` on the host for persistence across container recreations
- **claude-code.sh**: Installs Claude Code CLI via npm to persistent storage with proper PATH configuration
- **Dynamic Loading**: Agents are executed during container startup when specified with `--agent` flag
- **Auto-detection**: Previously installed agents are automatically available in new containers
- **Container Management**: Containers are now persistent (not ephemeral) to maintain agent state

## Key Environment Variables

- `PROJECT_NAME`: Name of the project (affects container name and mount paths)
- `PYTHONPATH`: Set to project directory for Python module resolution
- `UV_CACHE_DIR`: Optimized location for uv package cache
- `HOST_USER_ID`/`HOST_GROUP_ID`: Used for permission mapping
- `AGENT_NAME`: Tracks which agent was installed
- `AGENTS_DATA_DIR`: Points to `/persistent-agents` mount for agent persistence

## Persistent Agent Storage

Agents are installed to a persistent volume to survive container recreation:
- **Host Location**: `~/.python-agent-runner/agents-data`
- **Container Mount**: `/persistent-agents`
- **npm Global Packages**: Stored in `/persistent-agents/npm-global`
- **PATH Management**: Automatically configured in user sessions
- **Ownership**: Properly mapped to host user permissions