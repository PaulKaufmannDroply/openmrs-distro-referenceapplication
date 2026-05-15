# Production Deployment Design

**Date:** 2026-05-01  
**Target:** patients.medical-solidarity.org (91.98.211.75)  
**Server OS:** Debian 13, Docker Compose pre-installed

---

## Goal

Deploy the OpenMRS MSI instance to a production server with HTTPS, using GitHub Container Registry (ghcr.io) for image distribution.

---

## Architecture

```
Internet
   │ 80/443
 [Caddy]   ← handles HTTPS + automatic Let's Encrypt cert
   │ :80 (internal Docker network)
[gateway]  ← existing nginx router (no longer port-bound to host)
   ├── [frontend]  ← nginx + SPA
   └── [backend]   ← OpenMRS Java
         └── [db]  ← MariaDB
```

Caddy sits as the outermost layer. All existing services remain structurally unchanged. The gateway loses its host port binding (Caddy takes it over).

---

## New Files

| File | Purpose |
|------|---------|
| `Caddyfile` | Single-line HTTPS config |
| `docker-compose.prod.yml` | Production overrides (images, caddy service, port changes) |
| `deploy.sh` | Local script: build → push to ghcr.io |

`docker-compose.override.yml` remains untouched for local development.

---

## File Details

### Caddyfile
```
patients.medical-solidarity.org {
    reverse_proxy gateway:80
}
```
Caddy handles ACME challenge, cert issuance, and automatic renewal.

### docker-compose.prod.yml
- Adds `caddy` service (image: `caddy:2-alpine`, ports 80/443)
- `caddy_data` volume persists Let's Encrypt certificates
- `gateway`: port binding removed (Caddy takes over)
- `frontend`, `backend`, `gateway`: `image:` set to `ghcr.io/paulkaufmanndropily/msi-*:latest`

### deploy.sh (runs locally)
```bash
docker compose -f docker-compose.yml -f docker-compose.override.yml \
               -f docker-compose.prod.yml build
docker compose -f docker-compose.yml -f docker-compose.prod.yml push
```

---

## Image Names (ghcr.io)

| Service | Image |
|---------|-------|
| gateway | `ghcr.io/paulkaufmanndropily/msi-gateway:latest` |
| frontend | `ghcr.io/paulkaufmanndropily/msi-frontend:latest` |
| backend | `ghcr.io/paulkaufmanndropily/msi-backend:latest` |

ghcr.io images are **private by default**. After the first push, each image must be set to "public" in GitHub → Packages → Settings. Once public, the server can pull without authentication. Alternatively, `docker login ghcr.io` on the server with a PAT (`read:packages` scope) avoids making them public.

---

## Workflows

### One-time server setup
```bash
ssh ich@patients.medical-solidarity.org
su -
git clone https://github.com/PaulKaufmannDroply/openmrs-distro-referenceapplication /opt/openmrs
cd /opt/openmrs
docker compose -f docker-compose.yml -f docker-compose.prod.yml pull
docker compose -f docker-compose.yml -f docker-compose.prod.yml up -d
```

### Local deploy (after code change)
```bash
# Requires: docker login ghcr.io (one-time with GitHub PAT)
./deploy.sh
```

### Server update (after deploy.sh)
```bash
ssh ich@patients.medical-solidarity.org
su -
cd /opt/openmrs && git pull && \
  docker compose -f docker-compose.yml -f docker-compose.prod.yml pull && \
  docker compose -f docker-compose.yml -f docker-compose.prod.yml up -d
```

---

## Out of Scope (for now)

- Production database passwords (currently uses defaults: openmrs/openmrs)
- Firewall configuration inside the VM (managed externally via virtualisation)
- CI/CD automation (manual deploy.sh for now)
