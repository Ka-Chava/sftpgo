# SFTPGo on Digital Ocean App Platform (Cloudflare reverse proxy)
# Uses official image; override config via environment variables for reverse proxy and persistence.
# See https://docs.sftpgo.com/2.6/docker/ and https://docs.sftpgo.com/2.6/env-vars/

ARG SFTPGO_VERSION=v2.6.6
FROM drakkan/sftpgo:${SFTPGO_VERSION}

# Default HTTP port for App Platform (can be overridden by PORT)
ENV SFTPGO_HTTPD__BINDINGS__0__PORT=8080

# Data and config persist via mounted volumes or external PostgreSQL (see README)
# When using PostgreSQL, set SFTPGO_DATA_PROVIDER__* in the app environment.

USER 1000
EXPOSE 8080 2022
