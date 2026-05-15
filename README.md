# OpenMRS 3.0 Reference Application

This project holds the build configuration for the OpenMRS 3.0 reference application, found on
https://dev3.openmrs.org and https://o3.openmrs.org.

## Quick start

### Package the distribution and prepare the run

```
docker compose build
```

### Run the app

```
docker compose up
```

The new OpenMRS UI is accessible at http://localhost/openmrs/spa

OpenMRS Legacy UI is accessible at http://localhost/openmrs

## MSI Production Deployment (patients.medical-solidarity.org)

### Voraussetzungen (einmalig lokal)

1. GitHub PAT für `PaulKaufmannDroply` mit `write:packages`-Scope erstellen:
   https://github.com/settings/tokens
2. Bei ghcr.io einloggen:
   ```bash
   echo "TOKEN" | docker login ghcr.io -u paulkaufmanndroply --password-stdin
   ```
3. Git-Remote mit PAT setzen (falls push fehlschlägt):
   ```bash
   git remote set-url origin https://PaulKaufmannDroply:TOKEN@github.com/PaulKaufmannDroply/openmrs-distro-referenceapplication.git
   ```

### Deployment (nach Code-Änderungen)

```bash
./deploy.sh
```

Baut die Images für `linux/amd64`, pusht zu ghcr.io und zeigt den Server-Update-Befehl.

### Server einmalig einrichten

```bash
ssh ich@patients.medical-solidarity.org
su -
git clone https://github.com/PaulKaufmannDroply/openmrs-distro-referenceapplication /opt/openmrs
cd /opt/openmrs
git checkout feature/msi
docker compose -f docker-compose.yml -f docker-compose.prod.yml pull
docker compose -f docker-compose.yml -f docker-compose.prod.yml up -d
```

Beim **ersten Start** muss der Setup-Wizard einmal manuell durchlaufen werden:
https://patients.medical-solidarity.org/openmrs/web/setup.htm

Die Datenbank-Migration dauert beim ersten Start 1–2 Stunden (433 Liquibase-Changesets).

### Server updaten

```bash
cd /opt/openmrs && git pull && \
  docker compose -f docker-compose.yml -f docker-compose.prod.yml pull && \
  docker compose -f docker-compose.yml -f docker-compose.prod.yml up -d
```

### Hinweise

- Server: Debian 13, 1.9 GB RAM — ausreichend zum Betreiben, nicht zum Bauen
- Images werden lokal gebaut (Apple Silicon → `linux/amd64` via QEMU) und zu ghcr.io gepusht
- HTTPS via Caddy mit automatischem Let's Encrypt-Zertifikat
- DB-Passwörter vor Produktivbetrieb in `.env` setzen

---

## Overview

This distribution consists of four images:

* db - This is just the standard MariaDB image supplied to use as a database
* backend - This image is the OpenMRS backend. It is built from the main Dockerfile included in the root of the project and
  based on the core OpenMRS Docker file. Additional contents for this image are drawn from the `distro` sub-directory which
  includes a full Initializer configuration for the reference application intended as a starting point.
* frontend - This image is a simple nginx container that embeds the 3.x frontend, including the modules described in  the
  `frontend/spa-build-config.json` file.
* proxy - This image is an even simpler nginx reverse proxy that sits in front of the `backend` and `frontend` containers
  and provides a common interface to both. This helps mitigate CORS issues.

## Contributing to the configuration

This project uses the [Initializer](https://github.com/mekomsolutions/openmrs-module-initializer) module
to configure metadata for this project. The Initializer configuration can be found in the configuration
subfolder of the distro folder. Any files added to this will be automatically included as part of the
metadata for the RefApp.

Eventually, we would like to split this metadata into two packages:

* `openmrs-core`, which will contain all the metadata necessary to run OpenMRS
* `openmrs-demo`, which will include all of the sample data we use to run the RefApp

The `openmrs-core` package will eventually be a standard part of the distribution, with the `openmrs-demo`
provided as an optional add-on. Most data in this configuration _should_ be regarded as demo data. We
anticipate that implementation-specific metadata will replace data in the `openmrs-demo` package,
though they may use that metadata as a starting point for that customization.

To help us keep track of things, we ask that you suffix any files you add with either
`-core_demo` for files that should be part of the demo package and `-core_data` for
those that should be part of the core package. For example, a form named `test_form.json` would become
`test_core-core_demo.json`.

Frontend configuration can be found in `frontend/config-core_demo.json`.

Thanks!
