#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print status messages
print_status() {
    echo -e "${BLUE}[SETUP] $1${NC}"
}

print_success() {
    echo -e "${GREEN}[SUCCESS] $1${NC}"
}

print_error() {
    echo -e "${RED}[ERROR] $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}[WARNING] $1${NC}"
}

# Function to check if a command exists
check_command() {
    if ! command -v $1 &> /dev/null; then
        return 1
    fi
    return 0
}

# Function to detect OS
detect_os() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macos"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        echo "linux"
    elif [[ "$OSTYPE" == "msys"* || "$OSTYPE" == "cygwin"* ]]; then
        echo "windows"
    else
        echo "unknown"
    fi
}

# Function to install Rye
install_rye() {
    print_status "Installing Rye..."
    if [[ "$OSTYPE" == "darwin"* ]]; then
        if ! check_command "brew"; then
            print_status "Installing Homebrew..."
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        fi
        brew install rye
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        curl -sSf https://rye-up.com/get | bash
    else
        print_error "Unsupported operating system for Rye installation"
        exit 1
    fi
}

# Function to install Ollama
install_ollama() {
    print_status "Installing Ollama..."
    if [[ "$OSTYPE" == "darwin"* ]]; then
        if ! check_command "brew"; then
            print_status "Installing Homebrew..."
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        fi
        brew install ollama
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        curl -fsSL https://ollama.com/install.sh | sh
    else
        print_error "Unsupported operating system for Ollama installation"
        exit 1
    fi
}

# Function to start Ollama service
start_ollama_service() {
    print_status "Starting Ollama service..."
    if [[ "$OSTYPE" == "darwin"* ]]; then
        brew services start ollama
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        sudo systemctl start ollama
    fi
}

# Function to check if Ollama is running
check_ollama_running() {
    if curl -s http://localhost:11434/api/version > /dev/null; then
        return 0
    fi
    return 1
}

# Function to pull Mistral model
pull_mistral_model() {
    print_status "Pulling Mistral model..."
    ollama pull mistral
}

# Main setup process
print_status "Starting setup process..."

# Check Python version
if ! check_command "python3"; then
    print_error "Python 3 is not installed"
    exit 1
fi

# Install Rye if not present
if ! check_command "rye"; then
    install_rye
fi

# Install Ollama if not present
if ! check_command "ollama"; then
    install_ollama
fi

# Start Ollama service
start_ollama_service

# Wait for Ollama to start
print_status "Waiting for Ollama to start..."
sleep 5

# Check if Ollama is running
if ! check_ollama_running; then
    print_error "Failed to start Ollama service"
    exit 1
fi

# Pull Mistral model
pull_mistral_model

# Initialize Rye project if not already initialized
if [ ! -f "pyproject.toml" ]; then
    print_status "Initializing Rye project..."
    rye init
fi

# Sync dependencies
print_status "Syncing dependencies..."
rye sync

# Create .gitignore if it doesn't exist
if [ ! -f ".gitignore" ]; then
    print_status "Creating .gitignore..."
    cat > .gitignore << EOL
# Python
__pycache__/
*.py[cod]
*$py.class
*.so
.Python
build/
develop-eggs/
dist/
downloads/
eggs/
.eggs/
lib/
lib64/
parts/
sdist/
var/
wheels/
*.egg-info/
.installed.cfg
*.egg

# Virtual Environment
.venv/
venv/
ENV/

# IDE
.idea/
.vscode/
*.swp
*.swo

# Project specific
conversations.json
feedback.json
*.log

# macOS
.DS_Store
EOL
fi

# Create .python-version if it doesn't exist
if [ ! -f ".python-version" ]; then
    print_status "Creating .python-version..."
    rye pin > .python-version
fi

print_success "Setup completed successfully!"
print_status "You can now run the application using ./run.sh" 