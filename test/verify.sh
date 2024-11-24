#!/bin/bash

verify_wireguard() {
    # Check Docker
    if ! command -v docker >/dev/null 2>&1; then
        echo "Docker not installed"
        exit 1
    fi

    # Check WireGuard container
    if ! docker ps | grep -q wireguard; then
        echo "WireGuard container not running"
        exit 1
    fi

    # Check port
    if ! docker exec wireguard netstat -tuln | grep -q ":51820"; then
        echo "WireGuard port not listening"
        exit 1
    fi

    echo "WireGuard verification successful"
    exit 0
}

verify_wireguard