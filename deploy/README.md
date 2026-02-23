# Deploy SFTPGo on Digital Ocean App Platform with Cloudflare

This directory contains everything needed to run [SFTPGo](https://github.com/drakkan/sftpgo) on **Digital Ocean App Platform** behind **Cloudflare** as a reverse proxy, with **persistent user accounts** across deployments.

## Requirements

- [Digital Ocean account](https://docs.digitalocean.com/)
- [Cloudflare](https://www.cloudflare.com/) (or any reverse proxy that sets `X-Forwarded-Proto`, `X-Forwarded-Host`, and `CF-Connecting-IP` / `X-Forwarded-For`)
- [doctl](https://docs.digitalocean.com/reference/doctl/how-to/install/) (optional, for CLI deploy)

## What’s included

| Item | Purpose |
|------|--------|
| **Dockerfile** | Uses the official `drakkan/sftpgo` image; config is via environment variables. |
| **.do/app.yaml** | App Platform app spec: build from this repo (Git), deploy on push; PostgreSQL + reverse-proxy-safe HTTP config. |
| **README.md** | Setup, Cloudflare, and deployment steps. |

## Reverse proxy and CSRF-safe behavior

When the app is behind Cloudflare (or another reverse proxy), SFTPGo must:

1. **Treat requests as HTTPS** so cookies and redirects use `https://` and avoid mixed-content / CSRF issues.
2. **Use the public host** for redirects and links (not the internal App Platform host).
3. **Restrict allowed hosts** to your public domain(s) so host-header attacks are rejected.

The app spec configures this via:

- **`security.enabled`** – turns on security and proxy-aware behavior.
- **`https_proxy_headers`** – `X-Forwarded-Proto: https` so the app considers the request HTTPS.
- **`hosts_proxy_headers`** – `X-Forwarded-Host` so the app uses the public hostname.
- **`allowed_hosts`** – set to your public domain(s); requests with other Host headers are rejected.
- **`client_ip_proxy_header`** – `CF-Connecting-IP` (or `X-Forwarded-For`) for real client IP.
- **`proxy_allowed`** – IPs allowed to send these headers (e.g. `0.0.0.0/0` when you rely on `allowed_hosts`).
- **`base_url`** – Public URL of the app (e.g. `https://sftp.kachava.com`) so login and CSRF tokens use the correct origin.
- **`allowed_hosts`** – Must include the exact domain users visit; a mismatch causes "Form token is invalid" on login.

References: [SFTPGo configuration](https://docs.sftpgo.com/latest/config-file/), [SFTPGo env vars](https://docs.sftpgo.com/2.6/env-vars/).

## Persistent user accounts

User and admin data are stored in **PostgreSQL**, not on the container filesystem. The app spec adds a database component and sets:

- `SFTPGO_DATA_PROVIDER__DRIVER=postgres`
- `SFTPGO_DATA_PROVIDER__CONNECTION_STRING=${sftpgo-db.DATABASE_URL}`

So when you redeploy or scale the app, the same database is used and **user accounts persist**.

For production, use a **managed database** and set `production: true` and `cluster_name` in the `databases` section of `.do/app.yaml`.

## CI/CD: Deploy on push

The app builds from this repo and deploys when you push to `main` (GitHub **Ka-Chava/sftpgo**, **Deploy on push** enabled, Dockerfile at `deploy/Dockerfile`). User data persists in PostgreSQL.

### One-time setup

Edit **`.do/app.yaml`** and replace the placeholder with your real domain (the one you’ll put in front of the app in Cloudflare):

```yaml
- key: SFTPGO_HTTPD__BINDINGS__0__SECURITY__ALLOWED_HOSTS__0
  value: "sftpgo.yourdomain.com"   # e.g. sftp.example.com
  scope: RUN_TIME
```

If you have multiple domains, add more entries (e.g. `ALLOWED_HOSTS__1`, `ALLOWED_HOSTS__2`).

2. **Create the app** and connect GitHub: **Control Panel** → [Apps](https://cloud.digitalocean.com/apps) → **Create App** → **GitHub** → select **Ka-Chava/sftpgo** and branch `main`; use the app spec from **`.do/app.yaml`**. Or CLI: `doctl apps create --spec deploy/.do/app.yaml`. Ensure **Deploy on push** is enabled (the spec sets `deploy_on_push: true`).

3. After the first deploy, note the app URL.

### Ongoing: deploy on push

Push to `main` to trigger a new build and deployment. No manual deploy needed.

## Cloudflare and first-time setup

### Point Cloudflare at the app

1. In Cloudflare DNS, add a **CNAME** (or A/AAAA if you use a custom load balancer):
   - Name: your subdomain (e.g. `sftp` or `sftpgo`).
   - Target: the App Platform default URL host (e.g. `sftpgo-xxxxx.ondigitalocean.app`), or the URL you get from the app’s **Settings → Domains**.
2. **Proxy status**: turn **Proxied (orange cloud) on** so traffic goes through Cloudflare and the app receives `X-Forwarded-Proto`, `X-Forwarded-Host`, and `CF-Connecting-IP`.

Your app will then be reachable at `https://sftpgo.yourdomain.com` (or whatever you set in `allowed_hosts`).

### First-time SFTPGo setup

1. Open `https://sftpgo.yourdomain.com/web/admin` (or your domain).
2. Complete the **initial setup** and create the first admin user.
3. Create SFTP users and folders as needed via the Web Admin or [REST API](https://docs.sftpgo.com/2.6/rest-api/).

## SFTP and WebDAV on App Platform

- **HTTP/HTTPS** (Web Admin, REST API, Web Client) work over the App Platform URL and through Cloudflare.
- **SFTP (port 22/2022)** and **FTP** are **TCP** protocols. App Platform exposes **HTTP(S) only** to the internet, so **SFTP is not reachable from the public internet** when the app is only on App Platform.

Options if you need SFTP:

1. Run SFTPGo on a **Droplet** (or another VM) where you can open port 22/2022, and use the same PostgreSQL DB if desired.
2. Use **WebDAV** over HTTPS for file access from the same App Platform deployment (enable and configure WebDAV in SFTPGo).
3. Use **Cloudflare Tunnel** (or similar) to expose TCP (e.g. SFTP) from a separate host; that’s outside this App Platform setup.

## Changing branch or repo

To deploy from a different branch or repo, edit **`.do/app.yaml`**:

```yaml
github:
  repo: Ka-Chava/sftpgo   # or owner/repo
  branch: main             # e.g. develop, release/2.6
  deploy_on_push: true
```

## References

- [SFTPGo installation](https://docs.sftpgo.com/2.6/installation/)
- [SFTPGo Docker](https://docs.sftpgo.com/2.6/docker/)
- [SFTPGo configuration](https://docs.sftpgo.com/latest/config-file/)
- [SFTPGo environment variables](https://docs.sftpgo.com/2.6/env-vars/)
- [Digital Ocean App Platform – App Spec](https://docs.digitalocean.com/products/app-platform/reference/app-spec/)
- [Digital Ocean – Database env vars](https://docs.digitalocean.com/products/app-platform/how-to/manage-databases/)
