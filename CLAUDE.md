# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Architecture

This is a Docker-based development environment runner that creates containerized Python/Node.js development environments. The project consists of:

- **Dockerfile**: Defines a Python 3.10 development container with Node.js, pytest, and Claude Code pre-installed
- **Makefile**: Handles Docker image building and deployment to containerd/k8s
- **Launch Script** (`run.sh`): Interactive script to create and manage development containers with proper user permissions and volume mounts

## Common Commands

### Building the Docker Image
```bash
make build
```
This builds the Docker image with proper user permissions, saves it as a tar file, and imports it to containerd.

### Launching Development Environment
```bash
./run.sh [project-name] [host-port]
```
- Creates a new development container or connects to existing one
- Mounts current directory and home directory
- Sets up proper user permissions matching host system
- Default project name: `python-claude`, default port: `8000`

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
- Claude Code CLI pre-installed globally
- Automatic user/group mapping for seamless file permissions
- SSH key mounting for Git authentication
- Project directory mounted at `/$PROJECT_NAME`

## Architecture Notes

- Uses multi-stage user setup to handle permission mapping between host and container
- Implements proper cleanup and error handling in the launch script
- Supports both new container creation and reconnection to existing containers
- Uses containerd for k8s deployment (via `ctr -n k8s.io`)