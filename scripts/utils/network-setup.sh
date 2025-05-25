#!/bin/bash
set -e

echo "🌐 [network-setup.sh] Setting up Docker network for QLDSV-HTC..."

# Create Docker network if it doesn't exist
if ! docker network ls | grep -q "$DOCKER_NETWORK"; then
    echo "🔧 Creating Docker network: $DOCKER_NETWORK"
    docker network create \
        --driver bridge \
        --subnet=172.25.0.0/16 \
        "$DOCKER_NETWORK"
    echo "✅ Docker network created successfully"
else
    echo "ℹ️ Docker network '$DOCKER_NETWORK' already exists"
fi

# Verify network
echo "🔍 Network information:"
docker network inspect "$DOCKER_NETWORK" --format='{{.Name}}: {{.IPAM.Config}}'

echo "✅ [network-setup.sh] Network setup completed"