#!/usr/bin/env bash
set -euo pipefail

echo "==> Building images for linux/amd64..."
DOCKER_DEFAULT_PLATFORM=linux/amd64 docker compose \
  -f docker-compose.yml \
  -f docker-compose.override.yml \
  -f docker-compose.prod.yml \
  build

echo "==> Pushing to ghcr.io..."
docker compose \
  -f docker-compose.yml \
  -f docker-compose.override.yml \
  -f docker-compose.prod.yml \
  push gateway frontend backend

echo ""
echo "Done. To update the server run:"
echo ""
echo "  ssh ich@patients.medical-solidarity.org"
echo "  su -"
echo "  cd /opt/openmrs && git pull && \\"
echo "    docker compose -f docker-compose.yml -f docker-compose.prod.yml pull && \\"
echo "    docker compose -f docker-compose.yml -f docker-compose.prod.yml up -d"
