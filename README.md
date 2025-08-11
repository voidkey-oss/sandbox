# Voidkey Sandbox Environment

This sandbox provides a complete development environment for the Voidkey zero-trust credential broker system.

## Services

### Keycloak (Identity Provider)
- **URL**: http://localhost:8080
- **Admin Console**: http://localhost:8080/admin
- **Admin Credentials**: admin / admin

#### Realms and Clients

**Broker Realm** (`broker`)
- Client ID: `broker-service`
- Client Secret: `broker-secret-12345`
- Service Account: `service-account-broker-service`
- Purpose: Machine-to-machine authentication for the broker service

**Client Realm** (`client`)
- Client ID: `cli-client`
- Client Secret: `client-secret-67890`
- Service Account: `service-account-cli-client`
- Purpose: Machine-to-machine authentication for the CLI client

### MinIO (Object Storage)
- **API**: http://localhost:9000
- **Console**: http://localhost:9001
- **Root Credentials**: minioadmin / minioadmin123

#### Users and Policies

**Broker User**
- Username: `broker-user`
- Password: `broker-password-123`
- Policy: `broker-policy` (Currently `admin:*` for testing - will be narrowed to credential minting scope only in future versions. In production, this should be scoped purely to minting credentials for specific roles to minimize blast radius)

**Client User**
- Username: `client-user`
- Password: `client-password-456`
- Policy: `client-policy` (Full S3 access to voidkey-data bucket)

## Usage

### Start the Environment
```bash
docker-compose up -d
```

### Stop the Environment
```bash
docker-compose down
```

### Clean Reset
```bash
docker-compose down -v
docker-compose up -d
```

### View Logs
```bash
docker-compose logs -f
```

## Workflow

1. **CLI Authentication**: CLI authenticates with Keycloak client realm using `cli-client` credentials
2. **Broker Authentication**: Broker authenticates with Keycloak broker realm using `broker-service` credentials
3. **Credential Minting**: Broker uses its MinIO credentials to mint temporary credentials for the client
4. **Resource Access**: Client uses minted credentials to access MinIO resources

## Test Bucket

A test bucket named `voidkey-data` is automatically created and configured for client access.
