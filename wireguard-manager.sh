#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Add auto-install parameter
AUTO_INSTALL=${1:-false}

# Logging configuration
LOG_FILE="/var/log/wireguard-manager.log"
print_message() { echo -e "${GREEN}[+] $1${NC}" | tee -a "$LOG_FILE"; }
print_error() { echo -e "${RED}[-] $1${NC}" | tee -a "$LOG_FILE"; }
print_warning() { echo -e "${YELLOW}[!] $1${NC}" | tee -a "$LOG_FILE"; }

# Add these new functions
install_dependencies() {
    print_message "Installing dependencies..."
    apt-get update
    apt-get install -y \
        apt-transport-https \
        ca-certificates \
        curl \
        gnupg-agent \
        software-properties-common
}

install_docker() {
    print_message "Installing Docker..."
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
    add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
    apt-get update && apt-get install -y docker-ce docker-ce-cli containerd.io
}

setup_wireguard() {
    print_message "Setting up WireGuard..."
    mkdir -p /opt/wireguard-server
    
    # Create docker-compose.yaml with automated settings
    cat > /opt/wireguard-server/docker-compose.yaml << EOL
version: "3.8"
services:
  wireguard:
    container_name: wireguard
    image: linuxserver/wireguard
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=UTC
      - SERVERURL=auto
      - SERVERPORT=51820
      - PEERS=2
      - PEERDNS=auto
      - INTERNAL_SUBNET=10.13.13.0
    ports:
      - 51820:51820/udp
    volumes:
      - /opt/wireguard-server/config:/config
      - /lib/modules:/lib/modules
    restart: always
    cap_add:
      - NET_ADMIN
      - SYS_MODULE
    sysctls:
      - net.ipv4.conf.all.src_valid_mark=1
EOL

    cd /opt/wireguard-server
    docker-compose up -d
}

verify_installation() {
    print_message "Verifying installation..."
    sleep 10
    if docker ps | grep -q wireguard; then
        print_message "WireGuard is running successfully"
        return 0
    else
        print_error "WireGuard failed to start"
        return 1
    fi
}

# Function to add new peer
add_peer() {
    local current_peers=$(ls -d /opt/wireguard-server/config/peer* 2>/dev/null | wc -l)
    local new_total=$((current_peers + 1))
    
    print_message "Adding new peer (total will be $new_total)..."
    echo "Adding new peer at $(date)" >> "$LOG_FILE"
    
    # Backup existing configs
    timestamp=$(date +%Y%m%d_%H%M%S)
    mkdir -p /opt/wireguard-server/backups
    cp -r /opt/wireguard-server/config "/opt/wireguard-server/backups/config_$timestamp"
    
    # Update docker-compose.yaml
    sed -i "s/PEERS=.*/PEERS=$new_total/" /opt/wireguard-server/docker-compose.yaml
    
    # Recreate container
    cd /opt/wireguard-server
    docker-compose down
    docker-compose up -d
    
    # Wait for new config to generate
    sleep 10
    
    # Show new peer configuration
    print_message "New peer configuration (peer$new_total):"
    echo "----------------------------------------" >> "$LOG_FILE"
    echo "New peer$new_total configuration:" >> "$LOG_FILE"
    cat "/opt/wireguard-server/config/peer$new_total/peer$new_total.conf" | tee -a "$LOG_FILE"
}

# Function to revoke peer
revoke_peer() {
    print_message "Current peers:"
    ls -1 /opt/wireguard-server/config/peer*
    
    read -p "Enter peer number to revoke: " peer_num
    
    if [ ! -d "/opt/wireguard-server/config/peer$peer_num" ]; then
        print_error "Peer $peer_num not found"
        return 1
    fi  # Changed '}' to 'fi' for if statement
    
    print_message "Revoking peer$peer_num..."
    echo "Revoking peer$peer_num at $(date)" >> "$LOG_FILE"
    
    # Backup the config
    timestamp=$(date +%Y%m%d_%H%M%S)
    mkdir -p /opt/wireguard-server/revoked
    mv "/opt/wireguard-server/config/peer$peer_num" "/opt/wireguard-server/revoked/peer${peer_num}_${timestamp}"
    
    print_message "Peer $peer_num has been revoked. Configuration backed up in revoked folder."
}

# Function to remove WireGuard
remove_wireguard() {
    print_warning "This will completely remove WireGuard and all configurations!"
    read -p "Are you sure you want to continue? (y/n): " confirm
    
    if [ "$confirm" = "y" ]; then
        print_message "Removing WireGuard..."
        echo "Removing WireGuard at $(date)" >> "$LOG_FILE"
        
        # Stop and remove container
        cd /opt/wireguard-server
        docker-compose down
        
        # Backup configs
        timestamp=$(date +%Y%m%d_%H%M%S)
        mkdir -p /opt/wireguard-backups
        cp -r /opt/wireguard-server "/opt/wireguard-backups/wireguard-server_$timestamp"
        
        # Remove WireGuard directory
        rm -rf /opt/wireguard-server
        
        print_message "WireGuard has been removed. Backup saved in /opt/wireguard-backups"
    else
        print_message "Removal cancelled"
    fi
}

# Main menu
if ! check_wireguard; then
    print_warning "WireGuard is not installed. Starting installation..."
    install_wireguard
else
    while true; do
        echo
        echo "WireGuard Management"
        echo "==================="
        echo "[1] Add a new Peer"
        echo "[2] Revoke Existing Peer"
        echo "[3] Remove Wireguard"
        echo "[4] Exit"
        echo
        read -p "Select an option: " choice
        
        case $choice in
            1) add_peer ;;
            2) revoke_peer ;;
            3) remove_wireguard ;;
            4) 
                print_message "Exiting..."
                exit 0 
                ;;
            *) print_error "Invalid option" ;;
        esac
    done
fi