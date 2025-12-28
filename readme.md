# Infrastructure Repository 🚀

This repository manages **all backend apps** running on this VPS.

It handles:

- Docker Compose services for multiple backend apps
- Traefik routing and SSL
- Databases (Postgres) and caching (Redis)
- Secure environment variable management

---

## Repository Structure

```
backend-infra/
├── docker-compose.yml         # Main Compose file
├── traefik/                   # Traefik configs & certificates
│   ├── traefik.yml
│   └── acme.json
└── README.md                  # This file
```

- `.env` files are **never committed** to Git.

---

## Environment Variables

All backend environment variables are stored **securely on the VPS** in `/opt/infra/env/`.  
Each backend app has its **own env file**.

### Folder Structure on VPS

```bash
/opt/infra/env/
├── app-1-backend.env
├── app-2-backend.env
└── app-3-backend.env
```

### Creating the Folder

```bash
sudo mkdir -p /opt/infra/env
sudo chown -R $USER:$USER /opt/infra/env
sudo chmod 700 /opt/infra/env
```

- `chown` → you become the owner of the folder
- `chmod 700` → only you can read/write/execute (secure)

### Creating Env Files

Example for `app-1-backend`:

```bash
nano /opt/infra/env/app-1-backend.env
```

Add your environment variables:

```env
PORT=3000
DATABASE_URL=postgres://postgres:password@postgres:5432/dbname
JWT_SECRET=yourjwtsecret
```

Save the file. Repeat for other apps.

### Using Env Files in Docker Compose

Reference the full path in `docker-compose.yml`:

```yaml
env_file:
  - /opt/infra/env/app-1-backend.env
```

---

## Adding a New Backend App
example 1
1. Add a new service in `docker-compose.yml`:
2. Push your backend Docker image to Docker Hub.

```yaml
app-new-backend:
  image: yourdockerhub/app-new-backend:latest
  restart: always
  env_file:
    - /opt/infra/env/app-new-backend.env
  networks:
    - proxy_network
    - internal
  depends_on:
    postgres:
      condition: service_healthy
    redis:
      condition: service_healthy
  labels:
    - "traefik.enable=true"
    - "traefik.docker.network=proxy_network"
    - "traefik.http.routers.appnew.rule=Host(`new.example.com`)"
    - "traefik.http.routers.appnew.entrypoints=websecure"
    - "traefik.http.routers.appnew.tls=true"
    - "traefik.http.routers.appnew.tls.certresolver=le"
    - "traefik.http.services.appnew.loadbalancer.server.port=3000"
```

3. Create `.env` file on VPS:

```bash
nano /opt/infra/env/app-new-backend.env
chmod 600 /opt/infra/env/app-new-backend.env
```

4. Start or update the service:

```bash
docker compose up -d app-new-backend
```

---

## Core Services

- **Traefik** → handles SSL, routing, and dashboard
- **Postgres** → database service
- **Redis** → caching service
- **Backend apps** → your services (app-1, app-2, app-3…)

---

## Deployment

1. Edit or create `.env` files as described above.
2. Pull and restart backend containers via GitHub Actions or manually:

```bash
docker compose pull
docker compose up -d
```

3. Check logs or status:

```bash
docker compose ps
docker compose logs app-1-backend
```

---

## Rules & Best Practices

- One env file per app.
- VPS holds secrets; do not push `.env` files to Git.
- Add new apps by following the same pattern.
- Keep Traefik labels correct for each domain.

---
## Complete Flow

1. SSH into VPS
2. Create `/opt/infra/env/` folder with proper permissions
3. Clone this infrastructure repository
4. Create `.env` file for your app in `/opt/infra/env/`
5. Add service definition in `docker-compose.yml`
6. Configure Traefik labels with correct domain
7. Push Docker image to Docker Hub (from backend repo)
8. Pull latest images on VPS (optional )
9. Start service with `docker compose up -d` (optional)
10. Verify service is running and accessible

---
## License

MIT