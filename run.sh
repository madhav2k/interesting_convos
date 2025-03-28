#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print status messages
print_status() {
    echo -e "${BLUE}[RUN] $1${NC}"
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

# Function to check if Ollama is running
check_ollama_running() {
    if curl -s http://localhost:11434/api/version > /dev/null; then
        return 0
    fi
    return 1
}

# Function to start Ollama service
start_ollama_service() {
    print_status "Starting Ollama service..."
    if [[ "$OSTYPE" == "darwin"* ]]; then
        brew services start ollama
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        sudo systemctl start ollama
    fi
    
    # Wait for Ollama to start
    print_status "Waiting for Ollama to start..."
    for i in {1..30}; do
        if check_ollama_running; then
            print_success "Ollama service started successfully"
            return 0
        fi
        sleep 1
    done
    print_error "Failed to start Ollama service"
    return 1
}

# Function to check if rye sync is needed
check_rye_sync_needed() {
    # Always return true to force sync
    return 0
}

# Main run process
print_status "Starting application..."

# Check if Rye is installed
if ! check_command "rye"; then
    print_error "Rye is not installed. Please run setup.sh first."
    exit 1
fi

# Check if Ollama is installed
if ! check_command "ollama"; then
    print_error "Ollama is not installed. Please run setup.sh first."
    exit 1
fi

# Check if Ollama is running, start if not
if ! check_ollama_running; then
    if ! start_ollama_service; then
        print_error "Failed to start Ollama service"
        exit 1
    fi
fi

# Check if Mistral model is available
if ! ollama list | grep -q "mistral"; then
    print_status "Pulling Mistral model..."
    ollama pull mistral
fi

# Check if we're in a Rye environment
if [ ! -f "pyproject.toml" ]; then
    print_error "Not in a Rye project directory. Please run setup.sh first."
    exit 1
fi

# Check if rye sync is needed
print_status "Syncing dependencies..."
rye sync

# Run the application
print_status "Starting conversation suggester..."
rye run python conversation_suggester.py
