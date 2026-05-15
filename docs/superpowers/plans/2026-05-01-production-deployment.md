# Production Deployment Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Deploy the OpenMRS MSI instance to patients.medical-solidarity.org with HTTPS via Caddy, using GitHub Container Registry for image distribution.

**Architecture:** Caddy handles HTTPS termination (Let's Encrypt, auto-renewal) and reverse-proxies to the existing nginx gateway, which routes to frontend/backend. Images are built locally, pushed to ghcr.io, and pulled on the server. Local dev workflow is unchanged.

**Tech Stack:** Docker Compose v3.7, Caddy 2, ghcr.io (GitHub Container Registry), Debian 13

---

## File Map

| Action | File | What changes |
|--------|------|-------------|
| Modify | `docker-compose.yml` | Remove `ports` from `gateway` (Caddy takes over port 80) |
| Modify | `docker-compose.override.yml` | Add `ports: ["80:80"]` back to `gateway` (for local dev without Caddy) |
| Create | `Caddyfile` | One-line HTTPS reverse proxy config |
| Create | `docker-compose.prod.yml` | Caddy service + ghcr.io image overrides |
| Create | `deploy.sh` | Local build + push script |

---

## Task 1: One-time local ghcr.io authentication

**No files changed — manual step.**

- [ ] **Step 1: Create GitHub Personal Access Token**

  Go to https://github.com/settings/tokens → "Generate new token (classic)"
  - Name: `ghcr-push`
  - Scopes: `write:packages`, `read:packages`, `delete:packages`
  - Copy the token value

- [ ] **Step 2: Log in to ghcr.io**

  ```bash
  echo "YOUR_TOKEN_HERE" | docker login ghcr.io -u paulkaufmanndropily --password-stdin
  ```

  Expected output:
  ```
  Login Succeeded
  ```

---

## Task 2: Move gateway port binding out of base compose

The gateway currently binds host port 80 in `docker-compose.yml`. In production Caddy owns that port, so the binding must live only in the dev override.

**Files:**
- Modify: `docker-compose.yml`
- Modify: `docker-compose.override.yml`

- [ ] **Step 1: Remove ports from gateway in docker-compose.yml**

  In `docker-compose.yml`, change the `gateway` service from:
  ```yaml
  gateway:
    image: openmrs/openmrs-reference-application-3-gateway:${TAG:-qa}
    restart: "unless-stopped"
    depends_on:
      - frontend
      - backend
    ports:
      - "80:80"
  ```
  to:
  ```yaml
  gateway:
    image: openmrs/openmrs-reference-application-3-gateway:${TAG:-qa}
    restart: "unless-stopped"
    depends_on:
      - frontend
      - backend
  ```

- [ ] **Step 2: Add port binding to docker-compose.override.yml**

  In `docker-compose.override.yml`, change the `gateway` service from:
  ```yaml
  gateway:
    build:
      context: ./gateway
  ```
  to:
  ```yaml
  gateway:
    build:
      context: ./gateway
    ports:
      - "80:80"
  ```

- [ ] **Step 3: Verify local dev still starts**

  ```bash
  docker compose up gateway --no-deps
  ```

  Expected: gateway starts and binds port 80 (same as before).
  Stop with Ctrl+C.

- [ ] **Step 4: Commit**

  ```bash
  git add docker-compose.yml docker-compose.override.yml
  git commit -m "chore: move gateway port binding to dev override"
  ```

---

## Task 3: Create Caddyfile

**Files:**
- Create: `Caddyfile`

- [ ] **Step 1: Create the file**

  ```
  patients.medical-solidarity.org {
      reverse_proxy gateway:80
  }
  ```

  Caddy reads this on startup, requests a Let's Encrypt cert automatically for the domain, and reverse-proxies all traffic to the internal `gateway` container on port 80. No further cert management needed.

- [ ] **Step 2: Commit**

  ```bash
  git add Caddyfile
  git commit -m "chore: add Caddyfile for HTTPS termination"
  ```

---

## Task 4: Create docker-compose.prod.yml

**Files:**
- Create: `docker-compose.prod.yml`

- [ ] **Step 1: Create the file**

  ```yaml
  version: "3.7"

  services:
    caddy:
      image: caddy:2-alpine
      restart: "unless-stopped"
      ports:
        - "80:80"
        - "443:443"
        - "443:443/udp"
      volumes:
        - ./Caddyfile:/etc/caddy/Caddyfile
        - caddy_data:/data
        - caddy_config:/config
      depends_on:
        - gateway

    gateway:
      image: ghcr.io/paulkaufmanndropily/msi-gateway:latest

    frontend:
      image: ghcr.io/paulkaufmanndropily/msi-frontend:latest

    backend:
      image: ghcr.io/paulkaufmanndropily/msi-backend:latest

  volumes:
    caddy_data: ~
    caddy_config: ~
  ```

  **Why the three image overrides?** When this file is merged with `docker-compose.override.yml` locally (build context present) + `docker-compose.prod.yml` (image name present), Docker Compose builds from source AND names the resulting image with the ghcr.io tag — ready for `docker push`. On the server (no override file), Docker Compose sees only the `image:` key and pulls from ghcr.io.

- [ ] **Step 2: Commit**

  ```bash
  git add docker-compose.prod.yml
  git commit -m "chore: add docker-compose.prod.yml for production deployment"
  ```

---

## Task 5: Create deploy.sh

**Files:**
- Create: `deploy.sh`

- [ ] **Step 1: Create the file**

  ```bash
  #!/usr/bin/env bash
  set -euo pipefail

  echo "==> Building images..."
  docker compose \
    -f docker-compose.yml \
    -f docker-compose.override.yml \
    -f docker-compose.prod.yml \
    build

  echo "==> Pushing to ghcr.io..."
  docker compose \
    -f docker-compose.yml \
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
  ```

- [ ] **Step 2: Make executable and commit**

  ```bash
  chmod +x deploy.sh
  git add deploy.sh
  git commit -m "chore: add deploy.sh for local build + push to ghcr.io"
  ```

---

## Task 6: Build and push images

**No new files — runs deploy.sh.**

- [ ] **Step 1: Run the deploy script**

  ```bash
  ./deploy.sh
  ```

  This will take 15–30 minutes on first run (Maven + Node.js builds). Subsequent runs use the Docker layer cache and are much faster.

  Expected output ends with:
  ```
  Done. To update the server run:
  ...
  ```

- [ ] **Step 2: Make packages public on GitHub**

  After the first push, each image is private by default. Make them public so the server can pull without authentication:

  1. Go to https://github.com/paulkaufmanndropily?tab=packages
  2. For each of `msi-gateway`, `msi-frontend`, `msi-backend`:
     - Click the package → "Package settings" → "Change visibility" → Public

---

## Task 7: One-time server setup

**SSH session — no local files.**

- [ ] **Step 1: SSH and switch to root**

  ```bash
  ssh ich@patients.medical-solidarity.org
  su -
  # password: V73xWU79E9
  ```

- [ ] **Step 2: Clone the repo to /opt/openmrs**

  ```bash
  git clone https://github.com/PaulKaufmannDroply/openmrs-distro-referenceapplication /opt/openmrs
  cd /opt/openmrs
  git checkout feature/msi
  ```

- [ ] **Step 3: Pull images and start**

  ```bash
  docker compose -f docker-compose.yml -f docker-compose.prod.yml pull
  docker compose -f docker-compose.yml -f docker-compose.prod.yml up -d
  ```

  This starts 5 containers: caddy, gateway, frontend, backend, db.

- [ ] **Step 4: Verify**

  ```bash
  docker compose -f docker-compose.yml -f docker-compose.prod.yml ps
  ```

  Expected: all 5 services `running` or `healthy`.

  Then open https://patients.medical-solidarity.org in a browser. Caddy fetches the Let's Encrypt cert on first request (takes ~5 seconds). You should be redirected to `/openmrs/spa/`.

---

## Task 8: Subsequent server updates

**Reference — no files to create.**

After any code change, the full update cycle is:

```bash
# 1. Local machine: build + push
./deploy.sh

# 2. Server: pull + restart
ssh ich@patients.medical-solidarity.org
su -
cd /opt/openmrs && git pull && \
  docker compose -f docker-compose.yml -f docker-compose.prod.yml pull && \
  docker compose -f docker-compose.yml -f docker-compose.prod.yml up -d
```

---

## Notes for later (out of scope now)

- **Secure cookies:** `gateway/default.conf.template` has `# proxy_cookie_flags JSESSIONID secure samesite=strict;` commented out — uncomment for production.
- **DB passwords:** Set `OMRS_DB_USER`, `OMRS_DB_PASSWORD`, `MYSQL_ROOT_PASSWORD` in a `.env` file before going live.
- **SSH key:** Add your public key to `~/.ssh/authorized_keys` on the server to avoid password prompts.
