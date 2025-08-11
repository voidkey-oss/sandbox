#!/bin/bash

# Setup Test Environment
# Installs dependencies and starts services for Voidkey testing

set -e

echo "🔧 Setting up Voidkey test environment"
echo "======================================"

# Check if jq is installed (needed for JSON parsing)
if ! command -v jq &> /dev/null; then
    echo "📦 Installing jq..."
    if command -v apt-get &> /dev/null; then
        sudo apt-get update && sudo apt-get install -y jq
    elif command -v yum &> /dev/null; then
        sudo yum install -y jq
    elif command -v brew &> /dev/null; then
        brew install jq
    else
        echo "❌ Please install jq manually: https://stedolan.github.io/jq/download/"
        exit 1
    fi
fi
echo "✅ jq is available"

# Check if curl is installed
if ! command -v curl &> /dev/null; then
    echo "❌ curl is required but not installed"
    exit 1
fi
echo "✅ curl is available"

# Install MinIO client if not present
if ! command -v mc &> /dev/null; then
    echo "📦 Installing MinIO client (mc)..."
    curl -L https://dl.min.io/client/mc/release/linux-amd64/mc -o mc
    chmod +x mc
    sudo mv mc /usr/local/bin/
    echo "✅ MinIO client installed"
else
    echo "✅ MinIO client is available"
fi

# Start Docker services
echo "🐳 Starting Docker services..."
docker-compose up -d

# Wait for services to be ready
echo "⏳ Waiting for services to start..."
echo "   - Keycloak..."
for i in {1..30}; do
    if curl -s http://localhost:8080/realms/master >/dev/null; then
        break
    fi
    sleep 2
done

echo "   - MinIO..."
for i in {1..30}; do
    if curl -s http://localhost:9000/minio/health/live >/dev/null; then
        break
    fi
    sleep 2
done

# Verify services are running
if ! curl -s http://localhost:8080/realms/master >/dev/null; then
    echo "❌ Keycloak is not responding"
    exit 1
fi

if ! curl -s http://localhost:9000/minio/health/live >/dev/null; then
    echo "❌ MinIO is not responding"
    exit 1
fi

echo "✅ All services are running"

# Install Node.js dependencies for broker-server
echo "📦 Installing broker-server dependencies..."
cd ../broker-server
if [ ! -d "node_modules" ]; then
    npm install
fi
cd ../sandbox

echo "🎉 Test environment setup complete!"
echo ""
echo "📋 Next steps:"
echo "   1. Run: ./scripts/quick-test.sh (for quick test)"
echo "   2. Run: ./scripts/e2e-test.sh (for full end-to-end test)"
echo ""
echo "🔗 Service URLs:"
echo "   - Keycloak: http://localhost:8080 (admin/admin)"
echo "   - MinIO: http://localhost:9001 (minioadmin/minioadmin123)"
echo "   - MinIO API: http://localhost:9000"