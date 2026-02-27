# SFTPGo on DigitalOcean Droplet

Runs SFTPGo with SFTP on port 2022, web admin behind Caddy (auto-TLS) on 443, and an existing DO managed PostgreSQL database.

## Prerequisites

- Ubuntu Droplet (1 GB+ RAM, same region as your managed DB)
- Docker + Docker Compose installed on the Droplet
- Existing DO managed PostgreSQL cluster from App Platform
- Cloudflare DNS managing `sftp.kachava.com`

## One-time Droplet setup

### 1. Allow the Droplet to reach the database

In **DO Control Panel → Databases → your cluster → Settings → Trusted Sources**, add the Droplet's public IP.

### 2. Configure the firewall

```bash
ufw allow 22      # SSH (Droplet management)
ufw allow 80      # Caddy ACME challenge
ufw allow 443     # HTTPS web admin (via Cloudflare)
ufw allow 2022    # SFTP
ufw enable
```

### 3. Update DNS

| Record | Name | Value | Proxy |
|--------|------|-------|-------|
| A | `sftp` | Droplet public IP | Proxied (orange) — for web admin HTTPS |
| A | `sftp` | Droplet public IP | **DNS only (grey)** — SFTP clients need a direct TCP connection on 2022 |

> Because SFTP is raw TCP, Cloudflare cannot proxy it. Use a separate DNS record or subdomain (e.g. `sftp-data.kachava.com`) that is **DNS only** and point SFTP clients at that hostname on port 2022. The web admin subdomain (`sftp.kachava.com`) stays proxied.

## Deploy

```bash
# On the Droplet — clone the repo
git clone https://github.com/Ka-Chava/sftpgo.git
cd sftpgo/deploy/droplet

# Create .env with your DB connection string
cp .env.example .env
nano .env   # paste the connection string from DO Control Panel → Databases → Connection Details

# Start
docker compose up -d
```

Caddy will automatically obtain a TLS certificate on first start. Check with:

```bash
docker compose logs caddy
docker compose logs sftpgo
```

## Update SFTPGo

```bash
# Edit docker-compose.yml to bump SFTPGO_VERSION if needed, then:
docker compose pull
docker compose up -d
```

## Connecting via SFTP

```bash
sftp -P 2022 your-user@<droplet-ip-or-dns-only-hostname>
```

Or in any SFTP client: host = Droplet IP (or DNS-only hostname), port = 2022.

## Notes

- SSH host keys are stored in the `sftpgo_data` Docker volume and persist across container restarts. SFTP clients will not see a host key mismatch on updates.
- User accounts and config live in PostgreSQL — the same database App Platform was using — so existing users carry over automatically.
- The web admin is still at `https://sftp.kachava.com/web/admin`, unchanged from the App Platform setup.
