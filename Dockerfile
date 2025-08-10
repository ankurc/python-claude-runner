FROM python:3.10-slim

# Install system dependencies and Node.js
RUN apt-get update
RUN apt-get install -y --no-install-recommends \
    curl gnupg make tree git openssh-client sudo
RUN curl -fsSL https://deb.nodesource.com/setup_lts.x | bash -
RUN apt-get install -y nodejs
RUN rm -rf /var/lib/apt/lists/*

# Create virtualenv and install Python tools
ENV VENV_PATH=/opt/venv
RUN python -m venv $VENV_PATH && \
    $VENV_PATH/bin/pip install --upgrade pip && \
    $VENV_PATH/bin/pip install pytest pytest-cov uv

# Add virtualenv binaries to PATH
ENV PATH="$VENV_PATH/bin:$PATH"

# Create non-root user
ARG USERNAME
ARG GRP_ID

RUN groupadd -g 4200 sysadmin2 && \
    useradd -m -s /bin/bash $USERNAME && \
    usermod -aG sudo $USERNAME && \
    echo '$USERNAME ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

# Switch to non-root user
USER $USERNAME

# Install global Node.js CLI
# First, save a list of your existing global packages for later migration
RUN npm list -g --depth=0 > ~/npm-global-packages.txt

# Create a directory for your global packages
RUN mkdir -p ~/.npm-global

# Configure npm to use the new directory path
RUN npm config set prefix ~/.npm-global

# Note: Replace ~/.bashrc with ~/.zshrc, ~/.profile, or other appropriate file for your shell
RUN echo 'export PATH=~/.npm-global/bin:$PATH' >> ~/.bashrc

# Apply the new PATH setting
RUN . ~/.bashrc

# Now reinstall Claude Code in the new location
RUN npm install -g @anthropic-ai/claude-code

# Optional: Reinstall your previous global packages in the new location
# Look at ~/npm-global-packages.txt and install packages you want to keep

# Default command
CMD ["python"]