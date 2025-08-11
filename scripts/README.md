# Voidkey Test Scripts

This directory contains scripts for testing the complete Voidkey workflow from end-to-end.

## Scripts Overview

### 🔧 `setup-test-env.sh`
Sets up the complete test environment including:
- Installing required dependencies (jq, MinIO client)
- Starting Docker services (Keycloak, MinIO)
- Installing Node.js dependencies for broker-server
- Verifying all services are running

```bash
./scripts/setup-test-env.sh
```

### ⚡ `quick-test.sh`
Performs a quick end-to-end test:
- Builds the CLI from source
- Gets OIDC token from Keycloak
- Mints MinIO credentials via broker
- Tests basic MinIO operations
- Cleans up artifacts

```bash
./scripts/quick-test.sh
```

### 🚀 `e2e-test.sh`
Comprehensive end-to-end test that covers:
- All prerequisites checking
- CLI build and installation
- Broker server startup (if not running)
- OIDC token acquisition
- Credential minting with multiple formats
- Complete MinIO file upload/download cycle
- Credential expiration verification
- Comprehensive logging and error handling

```bash
./scripts/e2e-test.sh
```

### 📊 Existing Scripts
- `broker-info.sh` - Shows broker realm service account info  
- `client-info.sh` - Shows client realm service account info
- `test-broker-workflow.sh` - Tests broker workflow with curl

## Prerequisites

- Docker and docker-compose
- Go (for building CLI)
- Node.js and npm (for broker-server)
- curl (usually pre-installed)

## Quick Start

```bash
# 1. Setup environment (first time only)
./scripts/setup-test-env.sh

# 2. Run quick test
./scripts/quick-test.sh

# OR run comprehensive test
./scripts/e2e-test.sh
```

## What the Tests Demonstrate

The test scripts demonstrate a complete zero-trust credential broker workflow:

1. **Identity Authentication**: Service gets OIDC token from identity provider (Keycloak)
2. **Credential Request**: Service requests temporary credentials from Voidkey broker
3. **Identity Validation**: Broker validates the OIDC token
4. **Provider Authentication**: Broker authenticates to access provider (MinIO) using its own OIDC token
5. **Credential Minting**: Access provider mints temporary credentials via STS
6. **Secure Operations**: Service uses temporary credentials for actual operations
7. **Automatic Expiration**: Credentials expire automatically for security

## Architecture Tested

```
┌─────────────┐    ┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│   Client    │───▶│   Keycloak  │    │   Voidkey   │───▶│    MinIO    │
│     CLI     │    │    (IdP)    │    │   Broker    │    │    (STS)    │
└─────────────┘    └─────────────┘    └─────────────┘    └─────────────┘
       │                   │                   │                   │
       │ 1. Get OIDC token │                   │                   │
       │◀──────────────────│                   │                   │
       │                                       │                   │
       │ 2. Request credentials                │                   │
       │──────────────────────────────────────▶│                   │
       │                                       │                   │
       │                             3. Validate client token     │
       │                                       │                   │
       │                                       │ 4. Get broker token │
       │                                       │──────────────────▶│
       │                                       │                   │
       │                                       │ 5. Mint credentials │
       │                                       │◀──────────────────│
       │                                       │                   │
       │ 6. Return temp credentials            │                   │
       │◀──────────────────────────────────────│                   │
       │                                                           │
       │ 7. Use credentials for operations                         │
       │──────────────────────────────────────────────────────────▶│
```

## Troubleshooting

### Common Issues

1. **Services not starting**: Run `docker-compose down -v && docker-compose up -d`
2. **Permission denied**: Make sure scripts are executable with `chmod +x scripts/*.sh`
3. **Token errors**: Check that Keycloak realms are properly imported
4. **Network issues**: Verify all services are accessible on their expected ports

### Debug Commands

```bash
# Check service health
curl http://localhost:8080/realms/master
curl http://localhost:9000/minio/health/live

# Check Docker services
docker-compose ps
docker-compose logs keycloak
docker-compose logs minio

# Manual token test
curl -X POST "http://localhost:8080/realms/client/protocol/openid-connect/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=client_credentials" \
  -d "client_id=service-account" \
  -d "client_secret=service-secret-12345"
```

## Security Notes

- The test environment uses default credentials for simplicity
- In production, use proper secrets management
- OIDC tokens should be obtained securely and not logged
- Temporary credentials automatically expire for security