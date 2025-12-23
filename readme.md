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
├── env/                       # Environment files (secrets)
│   ├── app-1-backend.env.example
│   ├── app-2-backend.env.example
│   └── app-3-backend.env.example
├── traefik/                   # Traefik configs & certificates
│   ├── traefik.yml
│   └── acme.json
└── README.md                  # This file
```

- `.env` files are **never committed** to Git.
- `.env.example` files document required variables.

---

## Adding a New Backend App

1. Push your backend Docker image to Docker Hub.
2. Add a new service in `docker-compose.yml`:

```yaml
app-new-backend:
  image: yourdockerhub/app-new-backend:latest
  restart: always
  env_file:
    - ./env/app-new-backend.env
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

3. Create `.env` file from example:

```bash
cd env
cp app-new-backend.env.example app-new-backend.env
nano app-new-backend.env
chmod 600 app-new-backend.env
```

4. Start or update the service:

```bash
docker compose up -d app-new-backend
```

---

## Environment Variables

- Each app has its own `.env` file.
- `.env.example` shows required variables only.
- Docker Compose loads env files at runtime.
- Never commit `.env` files to Git.

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

## License

MIT
