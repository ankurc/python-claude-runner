#!/bin/bash

# Claude Code Agent Setup
# This script installs and configures Claude Code in the development environment

setup_claude_code() {
    echo "Setting up Claude Code agent..."
    
    # Set up persistent npm global directory
    PERSISTENT_NPM_DIR="${AGENTS_DATA_DIR:-$HOME/persistent-agents}/npm-global"
    
    # Check if Claude Code is already installed in persistent location
    if [ -f "$PERSISTENT_NPM_DIR/bin/claude" ]; then
        echo "Claude Code found in persistent storage"
        export PATH="$PERSISTENT_NPM_DIR/bin:$PATH"
        claude --version
        return 0
    fi
    
    # Install Claude Code using npm to persistent location
    if command -v npm >/dev/null 2>&1; then
        echo "Installing Claude Code to persistent storage..."

        # Create persistent npm directory
        mkdir -p "$PERSISTENT_NPM_DIR"
        
        # Configure npm to use persistent directory
        export NPM_CONFIG_PREFIX="$PERSISTENT_NPM_DIR"
        export PATH="$PERSISTENT_NPM_DIR/bin:$PATH"
        
        # Install Claude Code
        npm install -g @anthropic-ai/claude-code
        
        # Add to bashrc for future sessions
        echo "export PATH=\"$PERSISTENT_NPM_DIR/bin:\$PATH\"" >> ~/.bashrc
        
    else
        echo "Error: npm is not available. Cannot install Claude Code."
        return 1
    fi
    
    # Verify installation
    if command -v claude >/dev/null 2>&1; then
        echo "Claude Code installed successfully to persistent storage"
        claude --version
        
        # Set up basic configuration if needed
        echo "Claude Code is ready to use!"
        echo "To authenticate, run: claude auth"
        echo "To start an interactive session, run: claude"
        
        return 0
    else
        echo "Error: Claude Code installation failed"
        return 1
    fi
}

# Agent-specific environment variables
export CLAUDE_CODE_ENABLED=true
export AGENT_NAME="claude-code"

# Call the setup function
setup_claude_code