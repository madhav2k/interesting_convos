#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print status messages
print_status() {
    echo -e "${BLUE}[CLEANUP] $1${NC}"
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

# Function to find and kill all Ollama-related processes
find_and_kill_ollama_processes() {
    local os=$1
    case $os in
        "macos"|"linux")
            print_status "Finding all Ollama-related processes..."
            # Find all processes with "ollama" in their name or command
            local ollama_pids=$(ps aux | grep -i "ollama" | grep -v grep | awk '{print $2}')
            if [ ! -z "$ollama_pids" ]; then
                print_status "Found Ollama processes:"
                ps aux | grep -i "ollama" | grep -v grep
                print_status "Terminating processes..."
                echo "$ollama_pids" | xargs kill -9 2>/dev/null
            fi
            
            # Find and kill any processes using Ollama's ports
            local port_pids=$(lsof -ti:11434,11435 2>/dev/null)
            if [ ! -z "$port_pids" ]; then
                print_status "Found processes using Ollama ports:"
                lsof -i :11434,11435
                print_status "Terminating port-using processes..."
                echo "$port_pids" | xargs kill -9 2>/dev/null
            fi
            
            # Kill any remaining Ollama processes with force
            pkill -9 -f "ollama"
            
            # Additional cleanup for macOS
            if [ "$os" = "macos" ]; then
                # Remove launchd service
                launchctl unload ~/Library/LaunchAgents/com.ollama.ollama.plist 2>/dev/null
                rm ~/Library/LaunchAgents/com.ollama.ollama.plist 2>/dev/null
                
                # Stop and remove brew service
                brew services stop ollama 2>/dev/null
                brew services cleanup ollama 2>/dev/null
            fi
            ;;
        "windows")
            print_status "Finding all Ollama-related processes..."
            # Find and kill Ollama processes
            if tasklist /FI "IMAGENAME eq ollama.exe" /FO CSV | findstr /i "ollama.exe" > /dev/null; then
                print_status "Found Ollama processes, terminating..."
                taskkill /F /IM ollama.exe 2>/dev/null
            fi
            
            # Find and kill processes using Ollama ports
            netstat -ano | grep ":11434" | grep "LISTENING" | awk '{print $5}' | while read pid; do
                print_status "Found process using Ollama port: $pid"
                taskkill /F /PID "$pid" 2>/dev/null
            done
            
            # Remove Windows service
            sc stop Ollama 2>/dev/null
            sc config Ollama start= disabled 2>/dev/null
            sc delete Ollama 2>/dev/null
            ;;
    esac
}

# Function to clean up Ollama temporary files and caches
cleanup_ollama_files() {
    local os=$1
    case $os in
        "macos")
            print_status "Cleaning up Ollama temporary files..."
            # Stop service first
            brew services stop ollama 2>/dev/null
            
            # Remove all Ollama files
            rm -rf ~/.ollama/models/* 2>/dev/null
            rm -rf ~/.ollama/tmp/* 2>/dev/null
            rm -rf ~/.ollama/cache/* 2>/dev/null
            rm -rf ~/.ollama/ollama.db 2>/dev/null
            rm -rf ~/.ollama/ollama.db-shm 2>/dev/null
            rm -rf ~/.ollama/ollama.db-wal 2>/dev/null
            
            # Remove launchd service files
            rm -rf ~/Library/LaunchAgents/com.ollama.ollama.plist 2>/dev/null
            ;;
        "linux")
            print_status "Cleaning up Ollama temporary files..."
            # Stop service first
            sudo systemctl stop ollama 2>/dev/null
            
            # Remove all Ollama files
            sudo rm -rf ~/.ollama/models/* 2>/dev/null
            sudo rm -rf ~/.ollama/tmp/* 2>/dev/null
            sudo rm -rf ~/.ollama/cache/* 2>/dev/null
            sudo rm -rf ~/.ollama/ollama.db 2>/dev/null
            sudo rm -rf ~/.ollama/ollama.db-shm 2>/dev/null
            sudo rm -rf ~/.ollama/ollama.db-wal 2>/dev/null
            
            # Remove systemd service files
            sudo rm -f /etc/systemd/system/ollama.service 2>/dev/null
            sudo systemctl daemon-reload 2>/dev/null
            ;;
        "windows")
            print_status "Cleaning up Ollama temporary files..."
            # Stop service first
            sc stop Ollama 2>/dev/null
            
            # Remove all Ollama files
            if [ -d "$LOCALAPPDATA/ollama" ]; then
                rm -rf "$LOCALAPPDATA/ollama/models" 2>/dev/null
                rm -rf "$LOCALAPPDATA/ollama/tmp" 2>/dev/null
                rm -rf "$LOCALAPPDATA/ollama/cache" 2>/dev/null
                rm -rf "$LOCALAPPDATA/ollama/ollama.db" 2>/dev/null
                rm -rf "$LOCALAPPDATA/ollama/ollama.db-shm" 2>/dev/null
                rm -rf "$LOCALAPPDATA/ollama/ollama.db-wal" 2>/dev/null
            fi
            ;;
    esac
}

# Function to block Ollama ports
block_ollama_ports() {
    local os=$1
    case $os in
        "macos")
            print_status "Blocking Ollama ports (11434, 11435)..."
            sudo pfctl -e 2>/dev/null
            echo "block drop on lo0 proto tcp from any to any port 11434" | sudo pfctl -f - 2>/dev/null
            echo "block drop on lo0 proto tcp from any to any port 11435" | sudo pfctl -f - 2>/dev/null
            ;;
        "linux")
            print_status "Blocking Ollama ports (11434, 11435)..."
            sudo iptables -A INPUT -p tcp --dport 11434 -j DROP 2>/dev/null
            sudo iptables -A OUTPUT -p tcp --dport 11434 -j DROP 2>/dev/null
            sudo iptables -A INPUT -p tcp --dport 11435 -j DROP 2>/dev/null
            sudo iptables -A OUTPUT -p tcp --dport 11435 -j DROP 2>/dev/null
            ;;
        "windows")
            print_status "Blocking Ollama ports (11434, 11435)..."
            netsh advfirewall firewall add rule name="Block Ollama Port 11434" dir=in action=block protocol=TCP localport=11434 2>/dev/null
            netsh advfirewall firewall add rule name="Block Ollama Port 11434" dir=out action=block protocol=TCP localport=11434 2>/dev/null
            netsh advfirewall firewall add rule name="Block Ollama Port 11435" dir=in action=block protocol=TCP localport=11435 2>/dev/null
            netsh advfirewall firewall add rule name="Block Ollama Port 11435" dir=out action=block protocol=TCP localport=11435 2>/dev/null
            ;;
    esac
}

# Function to disable Ollama service
disable_ollama_service() {
    local os=$1
    case $os in
        "macos")
            print_status "Disabling Ollama service..."
            brew services stop ollama 2>/dev/null
            brew services cleanup ollama 2>/dev/null
            launchctl unload ~/Library/LaunchAgents/com.ollama.ollama.plist 2>/dev/null
            rm ~/Library/LaunchAgents/com.ollama.ollama.plist 2>/dev/null
            ;;
        "linux")
            print_status "Disabling Ollama service..."
            sudo systemctl stop ollama 2>/dev/null
            sudo systemctl disable ollama 2>/dev/null
            sudo systemctl mask ollama 2>/dev/null
            sudo rm -f /etc/systemd/system/ollama.service 2>/dev/null
            sudo systemctl daemon-reload 2>/dev/null
            ;;
        "windows")
            print_status "Disabling Ollama service..."
            sc stop Ollama 2>/dev/null
            sc config Ollama start= disabled 2>/dev/null
            sc delete Ollama 2>/dev/null
            ;;
    esac
}

# Main cleanup process
print_status "Starting comprehensive cleanup process..."

# Detect OS
OS=$(detect_os)
print_status "Detected operating system: $OS"

# Run cleanup steps
echo -e "\n=== Finding and Terminating Ollama Processes ==="
find_and_kill_ollama_processes "$OS"

echo -e "\n=== Cleaning up Ollama Files ==="
cleanup_ollama_files "$OS"

echo -e "\n=== Blocking Ollama Ports ==="
block_ollama_ports "$OS"

echo -e "\n=== Disabling Ollama Service ==="
disable_ollama_service "$OS"

# Verify cleanup
echo -e "\n=== Verifying Cleanup ==="
if pgrep -f "ollama" > /dev/null; then
    print_error "Some Ollama processes are still running!"
    print_status "Please run the script with sudo privileges for complete cleanup."
else
    print_success "All Ollama processes have been terminated"
fi

# Clear terminal
clear

print_success "Comprehensive cleanup completed successfully!"
print_status "All Ollama processes, files, and services have been terminated and blocked."
print_warning "Note: You will need to reinstall and re-enable the Ollama service when you want to use the application again." 