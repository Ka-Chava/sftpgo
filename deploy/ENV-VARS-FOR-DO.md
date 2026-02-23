# Environment variables for kca-sftpgo (Digital Ocean)

Use these **exact** key names in your app’s **Settings → Environment Variables**.  
SFTPGo expects **double underscores** `__` between each level (e.g. `SFTPGO_HTTPD__BINDINGS__0__...`).  
Wrong keys (e.g. `SFTPGO_HTTPDBINDINGS_0...` or `SFTPGO_DATA_PROVIDERDRIVER`) are **ignored** and cause "Form token invalid" and other issues.

---

## What’s wrong on the app right now

| Current key (wrong) | Problem |
|---------------------|--------|
| `SFTPGO_DATA_PROVIDERDRIVER` | Missing `__` → should be `SFTPGO_DATA_PROVIDER__DRIVER` |
| `SFTPGO_DATA_PROVIDERCONNECTION_STRING` | Missing `__` → should be `SFTPGO_DATA_PROVIDER__CONNECTION_STRING` |
| `SFTPGO_HTTPDBINDINGS_0CLIENT_IP_PROXY_HEADER` | Missing `__` → should be `SFTPGO_HTTPD__BINDINGS__0__CLIENT_IP_PROXY_HEADER` |
| `SFTPGO_HTTPDBINDINGS_0CLIENT_IP_HEADER_DEPTH` | Missing `__` → should be `SFTPGO_HTTPD__BINDINGS__0__CLIENT_IP_HEADER_DEPTH` |
| `CLIENT_IP_PROXY_HEADER` / `CLIENT_IP_HEADER_DEPTH` | Not SFTPGo keys; remove them (they do nothing). |

Also missing: security, base_url, allowed_hosts, proxy_allowed, https_proxy_headers — all required for form token and reverse proxy.

---

## Correct env vars to set

Copy these into your **sftpgo** service env vars. Your database component is **db-sftpgo**, so the connection string ref is `${db-sftpgo.DATABASE_URL}`.

| Key | Value |
|-----|--------|
| `SFTPGO_HTTPD__BINDINGS__0__PORT` | `8080` |
| `SFTPGO_HTTPD__BINDINGS__0__SECURITY__ENABLED` | `true` |
| `SFTPGO_HTTPD__BINDINGS__0__SECURITY__HTTPS_PROXY_HEADERS__0__KEY` | `X-Forwarded-Proto` |
| `SFTPGO_HTTPD__BINDINGS__0__SECURITY__HTTPS_PROXY_HEADERS__0__VALUE` | `https` |
| `SFTPGO_HTTPD__BINDINGS__0__SECURITY__HOSTS_PROXY_HEADERS__0` | `X-Forwarded-Host` |
| `SFTPGO_HTTPD__BINDINGS__0__SECURITY__ALLOWED_HOSTS__0` | `sftp.kachava.com` |
| `SFTPGO_HTTPD__BINDINGS__0__SECURITY__ALLOWED_HOSTS__1` | `sftpgo.kachava.com` |
| `SFTPGO_HTTPD__BINDINGS__0__BASE_URL` | `https://sftp.kachava.com` |
| `SFTPGO_HTTPD__BINDINGS__0__SECURITY__HTTPS_REDIRECT` | `false` |
| `SFTPGO_HTTPD__BINDINGS__0__CLIENT_IP_PROXY_HEADER` | `CF-Connecting-IP` |
| `SFTPGO_HTTPD__BINDINGS__0__CLIENT_IP_HEADER_DEPTH` | `0` |
| `SFTPGO_HTTPD__BINDINGS__0__PROXY_ALLOWED__0` … `__21` | Cloudflare IPv4 + IPv6 ranges from [cloudflare.com/ips](https://www.cloudflare.com/ips/) (see `.do/app.yaml` for full list) |
| `SFTPGO_DATA_PROVIDER__DRIVER` | `postgresql` |
| `SFTPGO_DATA_PROVIDER__CONNECTION_STRING` | `${db-sftpgo.DATABASE_URL}` |

---

## Steps

1. Open **Apps** → **kca-sftpgo** → **Settings** (or the **sftpgo** service).
2. Go to **Environment Variables**.
3. **Remove** the incorrect keys (e.g. `SFTPGO_DATA_PROVIDERDRIVER`, `SFTPGO_HTTPDBINDINGS_0...`, `CLIENT_IP_PROXY_HEADER`, `CLIENT_IP_HEADER_DEPTH`). Keep `DATABASE_URL` if it’s used elsewhere.
4. **Add** each key from the table above with the exact name and value. For `SFTPGO_DATA_PROVIDER__CONNECTION_STRING`, use the value `${db-sftpgo.DATABASE_URL}` (or bind the **db-sftpgo** database to the service so this variable is available).
5. Save and **redeploy** the app.

After redeploy, the form token (setup and login) should work because SFTPGo will read security, base_url, allowed_hosts, and client IP correctly.
