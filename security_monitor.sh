#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print status messages
print_status() {
    echo -e "${BLUE}[MONITOR] $1${NC}"
}

print_success() {
    echo -e "${GREEN}[SAFE] $1${NC}"
}

print_error() {
    echo -e "${RED}[ALERT] $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}[WARNING] $1${NC}"
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

# Function to check for running Ollama processes
check_ollama_processes() {
    local os=$1
    case $os in
        "macos"|"linux")
            if pgrep -f "ollama" > /dev/null; then
                print_error "Unauthorized Ollama processes detected!"
                echo "Process details:"
                ps aux | grep ollama | grep -v grep
                return 1
            fi
            ;;
        "windows")
            if tasklist /FI "IMAGENAME eq ollama.exe" 2>NUL | find /I /N "ollama.exe">NUL; then
                print_error "Unauthorized Ollama processes detected!"
                echo "Process details:"
                tasklist /FI "IMAGENAME eq ollama.exe"
                return 1
            fi
            ;;
    esac
    print_success "No unauthorized Ollama processes found"
    return 0
}

# Function to check for suspicious network connections
check_network_connections() {
    local os=$1
    case $os in
        "macos")
            if lsof -i :11434 > /dev/null; then
                print_error "Suspicious network connection detected on port 11434 (Ollama default port)"
                echo "Connection details:"
                lsof -i :11434
                return 1
            fi
            ;;
        "linux")
            if netstat -tuln | grep ":11434" > /dev/null; then
                print_error "Suspicious network connection detected on port 11434 (Ollama default port)"
                echo "Connection details:"
                netstat -tuln | grep ":11434"
                return 1
            fi
            ;;
        "windows")
            if netstat -ano | findstr ":11434" > /dev/null; then
                print_error "Suspicious network connection detected on port 11434 (Ollama default port)"
                echo "Connection details:"
                netstat -ano | findstr ":11434"
                return 1
            fi
            ;;
    esac
    print_success "No suspicious network connections found"
    return 0
}

# Function to check for unauthorized model files
check_model_files() {
    local os=$1
    case $os in
        "macos")
            if [ -d "$HOME/.ollama/models" ]; then
                print_status "Checking Ollama model files..."
                ls -la "$HOME/.ollama/models"
            fi
            ;;
        "linux")
            if [ -d "$HOME/.ollama/models" ]; then
                print_status "Checking Ollama model files..."
                ls -la "$HOME/.ollama/models"
            fi
            ;;
        "windows")
            if [ -d "$LOCALAPPDATA/ollama/models" ]; then
                print_status "Checking Ollama model files..."
                dir "$LOCALAPPDATA/ollama/models"
            fi
            ;;
    esac
}

# Function to check system resources
check_system_resources() {
    local os=$1
    case $os in
        "macos")
            print_status "Checking system resources..."
            echo "Memory usage:"
            ps -o pid,ppid,%mem,rss,cmd -p $(pgrep -f ollama 2>/dev/null) 2>/dev/null || echo "No Ollama processes found"
            ;;
        "linux")
            print_status "Checking system resources..."
            echo "Memory usage:"
            ps -o pid,ppid,%mem,rss,cmd -p $(pgrep -f ollama 2>/dev/null) 2>/dev/null || echo "No Ollama processes found"
            ;;
        "windows")
            print_status "Checking system resources..."
            echo "Memory usage:"
            tasklist /FI "IMAGENAME eq ollama.exe" /FO LIST
            ;;
    esac
}

# Main security check process
print_status "Starting security monitoring process..."

# Detect OS
OS=$(detect_os)
print_status "Detected operating system: $OS"

# Run security checks
echo -e "\n=== Checking for Unauthorized Processes ==="
check_ollama_processes "$OS"

echo -e "\n=== Checking Network Connections ==="
check_network_connections "$OS"

echo -e "\n=== Checking Model Files ==="
check_model_files "$OS"

echo -e "\n=== Checking System Resources ==="
check_system_resources "$OS"

print_status "Security monitoring completed."
print_status "If you see any [ALERT] messages, please investigate further." 