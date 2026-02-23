# Root Dockerfile for Digital Ocean App Platform (kca-sftpgo uses dockerfile_path: /Dockerfile).
# Source of truth: deploy/Dockerfile — keep in sync.
# See https://docs.sftpgo.com/2.6/docker/ and https://docs.sftpgo.com/2.6/env-vars/

ARG SFTPGO_VERSION=v2.6.6
FROM drakkan/sftpgo:${SFTPGO_VERSION}

ENV SFTPGO_HTTPD__BINDINGS__0__PORT=8080

USER 1000
EXPOSE 8080 2022
