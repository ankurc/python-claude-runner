#!/bin/bash

# Docker Dev Environment Launcher
# Usage: ./run.sh [project-name] [host-port]

# Ensure we're running with bash
if [ -z "$BASH_VERSION" ]; then
    echo "This script requires bash. Please run with: bash $0 $@"
    exit 1
fi

set -e

# Default values
DEFAULT_AGENT="claude-code"
DEFAULT_PROJECT_NAME="python-claude"
DEFAULT_HOST_PORT="8000"
IMAGE_NAME="python-agent-runner:3.10"

# Parse arguments
AGENT_NAME=${1:-$DEFAULT_AGENT}
PROJECT_NAME=${2:-$DEFAULT_PROJECT_NAME}
HOST_PORT=${3:-$DEFAULT_HOST_PORT}
CONTAINER_NAME="${PROJECT_NAME}-dev-env"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to cleanup on script exit
cleanup() {
    if [ $? -ne 0 ]; then
        print_error "Script failed. Cleaning up..."
        docker rm -f "$CONTAINER_NAME" 2>/dev/null || true
    fi
}

trap cleanup EXIT

# Check if Docker is running
if ! docker info >/dev/null 2>&1; then
    print_error "Docker is not running. Please start Docker and try again."
    exit 1
fi

# Check if container with same name already exists
if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    print_warning "Container '$CONTAINER_NAME' already exists."
    read -p "Do you want to remove it and create a new one? [y/N]: " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_status "Removing existing container..."
        docker rm -f "$CONTAINER_NAME"
    else
        print_status "Connecting to existing container..."
        if docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
            docker exec -it "$CONTAINER_NAME" bash
        else
            docker start "$CONTAINER_NAME"
            docker exec -it "$CONTAINER_NAME" bash
        fi
        exit 0
    fi
fi

# Create project directory on host if it doesn't exist
PROJECT_DIR="$(pwd)/$PROJECT_NAME"
AGENTS_DATA_DIR="$(pwd)/agents"
if [ ! -d "$PROJECT_DIR" ]; then
    print_status "Creating project directory: $PROJECT_DIR"
    mkdir -p "$PROJECT_DIR"
fi

# Check if the local image exists
if ! docker image inspect "$IMAGE_NAME" >/dev/null 2>&1; then
    print_error "Local image '$IMAGE_NAME' not found."
    print_error "Please build the image first or check the image name."
    exit 1
fi

print_status "Using local image: $IMAGE_NAME"

# Get current user info for proper permissions
USER_ID=$(id -u)
GROUP_ID=$(id -g)
USERNAME=$(whoami)

# Check for SSH keys
SSH_DIR="$HOME/.ssh"
SSH_MOUNT=""
if [ -d "$SSH_DIR" ]; then
    print_status "Found SSH directory, mounting for Git authentication"
    SSH_MOUNT="-v $SSH_DIR:/home/$USERNAME/.ssh:ro"
else
    print_warning "No SSH directory found at $SSH_DIR"
fi

# Check for SSH keys
HOME_DIR="$HOME"
HOME_MOUNT=""
if [ -d "$HOME_DIR" ]; then
    print_status "Found HOME directory, mounting"
    HOME_MOUNT="-v $HOME_DIR:/home/$USERNAME"
else
    print_warning "No HOME directory found at $HOME_DIR"
fi

# Create and run the development container
print_status "Creating development environment..."
print_status "Project: $PROJECT_NAME"
print_status "Host directory: $PROJECT_DIR"
print_status "Container port 8000 mapped to host port: $HOST_PORT"

docker run -it --rm \
    --name "$CONTAINER_NAME" \
    --hostname "$PROJECT_NAME-dev" \
    -v "$PROJECT_DIR:/$PROJECT_NAME" \
    -v "$AGENTS_DATA_DIR:/agents" \
    $HOME_MOUNT \
    -w /$PROJECT_NAME \
    -p "$HOST_PORT:8000" \
    -e "PROJECT_NAME=$PROJECT_NAME" \
    -e "PYTHONPATH=/$PROJECT_NAME" \
    -e "UV_CACHE_DIR=/tmp/uv-cache" \
    -e "HOST_USER_ID=$USER_ID" \
    -e "HOST_GROUP_ID=$GROUP_ID" \
    -e "HOST_USERNAME=$USERNAME" \
    "$IMAGE_NAME" \
    bash -c "
        echo 'Setting up development environment...'

        # Create group with host GID
        groupadd -g \$HOST_GROUP_ID \$HOST_USERNAME 2>/dev/null || groupadd -g 1000 devgroup 2>/dev/null || true

        # Create user with host UID and username
        useradd -u \$HOST_USER_ID -g \$HOST_GROUP_ID -s /bin/bash -m -d /home/\$HOST_USERNAME \$HOST_USERNAME 2>/dev/null || {
            echo 'Creating fallback user with UID 1000...'
            useradd -u 1000 -g 1000 -s /bin/bash -m -d /home/$USERNAME $USERNAME 2>/dev/null || true
            export HOST_USERNAME=$USERNAME
        }

        # Fix git safe directory issue if git exists
        if command -v git >/dev/null 2>&1; then
            sudo -u \$HOST_USERNAME git config --global --add safe.directory /$PROJECT_NAME 2>/dev/null || true
        fi

        # Change ownership of $PROJECT_NAME to the user
        chown -R \$HOST_USER_ID:\$HOST_GROUP_ID /$PROJECT_NAME 2>/dev/null || chown -R 1000:1000 /$PROJECT_NAME 2>/dev/null || true

        # Switch to the user
        echo 'Starting development environment as user: '\$HOST_USERNAME
        if command -v sudo >/dev/null 2>&1; then
            exec sudo -u \$HOST_USERNAME -i bash -c 'ls -al /agents && source /agents/${AGENT_NAME}.sh && cd /$PROJECT_NAME && exec bash'
        else
            echo 'Sudo not available, running as $USERNAME...'
            # Fix git safe directory issue for $USERNAME user
            if command -v git >/dev/null 2>&1; then
                git config --global --add safe.directory /$PROJECT_NAME 2>/dev/null || true
            fi
            source /agents/${AGENT_NAME}.sh
            exec bash
        fi
    "

print_success "Development environment stopped."
