#!/usr/bin/env bash
set -euo pipefail

echo "==> Pushing to GitHub..."
git push origin feature/msi

echo ""
echo "Done. To update the server run:"
echo ""
echo "  ssh ich@patients.medical-solidarity.org"
echo "  su -"
echo "  cd /opt/openmrs && git pull && \\"
echo "    docker compose -f docker-compose.yml -f docker-compose.prod.yml build && \\"
echo "    docker compose -f docker-compose.yml -f docker-compose.prod.yml up -d"
