#!/bin/bash
# Manual deploy script — runs on the Droplet.
# Called automatically by GitHub Actions on every push to main.
# Can also be run manually: ssh root@<droplet-ip> /opt/sftpgo/scripts/deploy.sh
set -e

cd /opt/sftpgo

echo "[deploy] Pulling latest code..."
git pull origin main

echo "[deploy] Rebuilding and restarting containers..."
docker compose pull
docker compose up -d --build

echo "[deploy] Waiting for services to stabilize..."
sleep 20

echo "[deploy] Running health check..."
HTTP_STATUS=$(curl -sf -o /dev/null -w "%{http_code}" http://localhost:8080/healthz 2>/dev/null || echo "000")
if [ "$HTTP_STATUS" = "200" ]; then
  echo "[deploy] Health check passed (HTTP $HTTP_STATUS). Deployment successful!"
else
  echo "[deploy] Health check failed (HTTP $HTTP_STATUS). Showing recent logs:"
  docker compose logs --tail=50 sftpgo
  exit 1
fi
