#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Add this at the beginning of your script
AUTO_INSTALL=${1:-false}

# Logging configuration
LOG_FILE="/var/log/wireguard-manager.log"
print_message() { echo -e "${GREEN}[+] $1${NC}" | tee -a "$LOG_FILE"; }
print_error() { echo -e "${RED}[-] $1${NC}" | tee -a "$LOG_FILE"; }
print_warning() { echo -e "${YELLOW}[!] $1${NC}" | tee -a "$LOG_FILE"; }

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    print_error "Please run as root or with sudo"
    exit 1
fi

# Initialize log file
echo "----------------------------------------" >> "$LOG_FILE"
echo "Script started at $(date)" >> "$LOG_FILE"

# Function to check if WireGuard is installed
check_wireguard() {
    if [ -d "/opt/wireguard-server" ] && docker ps | grep -q wireguard; then
        return 0 # Installed
    else
        return 1 # Not installed
    fi
}

# Function to install WireGuard
install_wireguard() {
    print_message "Starting WireGuard installation..."
    
    # Create new user
    print_message "Creating new user..."
    read -p "Enter username for new admin user: " NEW_USER
    echo "Username set to: $NEW_USER" >> "$LOG_FILE"
    
    adduser $NEW_USER
    usermod -aG sudo $NEW_USER
    
    # Update system
    print_message "Updating system packages..."
    apt update -y && apt upgrade -y && apt autoremove -y
    
    # Install dependencies
    print_message "Installing required packages..."
    apt-get install -y apt-transport-https ca-certificates curl gnupg-agent software-properties-common
    
    # Install Docker
    print_message "Installing Docker..."
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
    add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
    apt-get update && apt-get install -y docker-ce docker-ce-cli containerd.io
    
    # Install Docker Compose
    print_message "Installing Docker Compose..."
    curl -L "https://github.com/docker/compose/releases/download/1.26.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
    
    # Add user to docker group
    usermod -aG docker $NEW_USER
    
    # Get number of peers
    read -p "How many peer configurations do you want to create? " PEER_COUNT
    echo "Number of peers set to: $PEER_COUNT" >> "$LOG_FILE"
    
    # Get Server IP
    SERVER_IP=$(curl -s ifconfig.me)
    echo "Server IP detected as: $SERVER_IP" >> "$LOG_FILE"
    
    # Create WireGuard directory
    print_message "Setting up WireGuard directory..."
    mkdir -p /opt/wireguard-server
    chown $NEW_USER:$NEW_USER /opt/wireguard-server
    
    # Create docker-compose.yaml
    print_message "Creating Docker Compose configuration..."
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
      - SERVERURL=${SERVER_IP}
      - SERVERPORT=51820
      - PEERS=${PEER_COUNT}
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
    
    # Start WireGuard
    print_message "Starting WireGuard container..."
    cd /opt/wireguard-server
    docker-compose up -d
    
    # Wait for container to start and configs to generate
    print_message "Waiting for WireGuard to initialize..."
    sleep 10
    
    # Show peer configurations
    print_message "Peer configurations:"
    for i in $(seq 1 $PEER_COUNT); do
        echo "----------------------------------------" >> "$LOG_FILE"
        echo "Configuration for peer$i:" >> "$LOG_FILE"
        cat "/opt/wireguard-server/config/peer$i/peer$i.conf" >> "$LOG_FILE"
        print_message "Peer $i configuration has been saved to the log file"
        print_message "Configuration for peer$i:"
        cat "/opt/wireguard-server/config/peer$i/peer$i.conf"
    done
    
    print_message "Installation complete! All configurations have been saved to $LOG_FILE"
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