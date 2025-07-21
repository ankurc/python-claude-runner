# python-claude-runner

A Docker-based development environment runner that creates isolated, containerized Python/Node.js development environments with Claude Code pre-installed and ready for use.

## Overview

This project provides a streamlined way to spin up consistent development environments using Docker containers. Each environment comes pre-configured with Python 3.10, Node.js LTS, essential development tools, and Claude Code CLI, eliminating the "works on my machine" problem.

## Architecture Flow

```
Host System                          Docker Container
┌─────────────────────┐             ┌─────────────────────────────────┐
│                     │             │                                 │
│  Current Directory  │◄────────────┤  Project Directory              │
│  ~/project-name/    │  Volume     │  /project-name/                 │
│                     │  Mount      │                                 │
├─────────────────────┤             ├─────────────────────────────────┤
│                     │             │                                 │
│  Home Directory     │◄────────────┤  User Home Directory            │
│  ~/.ssh/, etc.      │  Volume     │  /home/username/                │
│                     │  Mount      │                                 │
├─────────────────────┤             ├─────────────────────────────────┤
│                     │             │                                 │
│  Host Port :8000    │◄────────────┤  Container Port :8000           │
│                     │  Port       │                                 │
│                     │  Forward    │                                 │
└─────────────────────┘             └─────────────────────────────────┘
                                    
                                    Container Environment:
                                    • Python 3.10 + virtualenv
                                    • Node.js LTS + npm
                                    • Claude Code CLI
                                    • pytest, uv, git
                                    • User permission mapping
```

## Key Features

- **Isolated Environments**: Each project gets its own containerized environment
- **Permission Mapping**: Automatically maps host user permissions to container
- **Pre-installed Tools**: Python 3.10, Node.js, pytest, Claude Code CLI
- **Volume Mounting**: Access to host directories and SSH keys
- **Interactive Management**: Smart container lifecycle management
- **Cross-platform**: Works on Linux, macOS, and Windows

## Quick Start

### 1. Build the Environment

```bash
# Build the Docker image
make build

# Or using npm
npm run build
```

### 2. Launch Development Environment

```bash
# Launch with default settings
./run.sh

# Launch with custom project name and port
./run.sh my-project 3000
```

### 3. Start Developing

Once inside the container:
```bash
# Python development
python --version    # Python 3.10
pip install -r requirements.txt

# Node.js development
node --version      # Node.js LTS
npm install

# Use Claude Code
claude --help
```

## Usage Examples

### Python Project Development

```bash
# Launch environment for Python project
./run.sh python-api 8080

# Inside container - create virtual environment
python -m venv venv
source venv/bin/activate
pip install fastapi uvicorn

# Start development server
uvicorn main:app --reload --host 0.0.0.0
```

### Full-stack Development

```bash
# Launch environment for full-stack project
./run.sh fullstack-app 3000

# Inside container - install dependencies
pip install -r requirements.txt  # Backend
npm install                      # Frontend

# Run both services
python backend/app.py &          # Background process
npm run dev                      # Frontend dev server
```

## Available Commands

### Make Commands
```bash
make build    # Build Docker image with proper permissions
make deploy   # Load the built image into Docker
make clean    # Remove generated tar files
make all      # Run clean, build, and deploy sequence
```

### NPM Scripts
```bash
npm run build    # Equivalent to make build
npm run dev      # Launch development environment
npm start        # Same as npm run dev
npm run clean    # Equivalent to make clean
npm run deploy   # Equivalent to make deploy
```

## Container Features

The development container includes:

- **Python 3.10** with pip and virtualenv at `/opt/venv`
- **Node.js LTS** with npm configured for user-local packages
- **Development Tools**: pytest, pytest-cov, uv, git, openssh-client
- **Claude Code CLI** pre-installed globally
- **User Permissions**: Automatic mapping of host user to container user
- **SSH Access**: SSH keys mounted for Git authentication
- **Project Access**: Current directory mounted at `/$PROJECT_NAME`

## Advanced Usage

### Container Management

The `run.sh` script intelligently handles container lifecycle:

- **New Container**: Creates fresh environment if none exists
- **Reconnect**: Connects to existing running container
- **Replace**: Optionally removes and recreates existing containers
- **Cleanup**: Automatic cleanup on script failure

### Environment Variables

The container sets up several environment variables:
- `PROJECT_NAME`: Name of your project
- `PYTHONPATH`: Set to project directory
- `UV_CACHE_DIR`: Optimized package cache location

### Port Forwarding

Container port 8000 is forwarded to specified host port (default: 8000):
```bash
./run.sh my-app 3000  # Container:8000 -> Host:3000
```

## Benefits

1. **Consistency**: Same environment across different machines
2. **Isolation**: Projects don't interfere with each other
3. **Clean Setup**: No need to install Python/Node.js on host
4. **Version Control**: Environment definition tracked in code
5. **Collaboration**: Team members get identical setups
6. **Security**: Isolated from host system changes

## Requirements

- Docker installed and running
- bash shell (for run.sh script)
- Make (optional, can use npm scripts instead)

## Troubleshooting

### Docker Not Running
```bash
# Start Docker service (Linux)
sudo systemctl start docker

# Or use Docker Desktop (macOS/Windows)
```

### Permission Issues
The script automatically handles permission mapping, but if you encounter issues:
```bash
# Check your user ID
id -u
id -g

# The script uses these automatically
```

### Container Already Exists
The script will prompt you to either reconnect or replace existing containers.

## License

MIT License - see LICENSE file for details.