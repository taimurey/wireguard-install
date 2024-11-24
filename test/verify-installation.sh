#!/bin/bash

verify_installation() {
    # Check if Docker is running
    if ! docker info >/dev/null 2>&1; then
        echo "Error: Docker is not running"
        return 1
    fi

    # Check if WireGuard container exists and is running
    if ! docker ps | grep -q wireguard; then
        echo "Error: WireGuard container is not running"
        return 1
    fi

    # Check if WireGuard port is listening
    if ! docker exec wireguard netstat -tuln | grep -q "51820"; then
        echo "Error: WireGuard port is not listening"
        return 1
    fi

    echo "WireGuard installation verified successfully"
    return 0
}

verify_installation