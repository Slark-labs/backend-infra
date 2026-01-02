# Backend Infrastructure 🚀

A production-ready infrastructure for deploying multiple backend applications on a single VPS with automatic CI/CD, SSL certificates, and secure environment management.

## ✨ Features

- **Multi-app deployment** - Run multiple Node.js/Express apps on one VPS
- **Automatic SSL** - Let's Encrypt certificates via Traefik reverse proxy
- **Database & Caching** - PostgreSQL + Redis with health checks
- **GitHub Actions CI/CD** - Zero-downtime automated deployments
- **Secure secrets** - Environment variables stored securely on VPS
- **Health monitoring** - Automatic rollback on deployment failures
- **Load balancing** - Traefik handles routing and SSL termination

## 🚀 Quick Start

### 1. VPS Initial Setup

```bash
# SSH into your VPS and run the setup script
curl -fsSL https://raw.githubusercontent.com/yourusername/backend-infra/main/setup-vps.sh | bash

# Or clone manually:
git clone https://github.com/yourusername/backend-infra.git /opt/backend-infra
cd /opt/backend-infra
chmod +x setup-vps.sh && ./setup-vps.sh
```

### 2. Configure Environment Variables

```bash
# Generate secure passwords
POSTGRES_PASSWORD=$(openssl rand -base64 32)
JWT_SECRET=$(openssl rand -hex 32)

# Update database credentials
nano /opt/infra/env/database.env
# Add: POSTGRES_PASSWORD=your_generated_password

# Update app environments
nano /opt/infra/env/app-1-backend.env
nano /opt/infra/env/app-2-backend.env
# Update DATABASE_URL and JWT_SECRET with generated values
```

### 3. Start Infrastructure

```bash
cd /opt/backend-infra
docker compose up -d
```

### 4. GitHub Secrets Setup

Add these secrets to **all repositories** (infra + each app repo):

```env
DOCKER_USERNAME=your_dockerhub_username
DOCKER_PASSWORD=your_dockerhub_password
VPS_IP=your.vps.ip.address
VPS_USERNAME=root
VPS_SSH_KEY=-----BEGIN OPENSSH PRIVATE KEY-----...
VPS_PORT=22
```

---

## 🏗️ Architecture

```
Internet
    ↓
[Traefik Reverse Proxy] (Ports 80, 443)
    ↓
[Backend Apps] (app-1.example.com, app-2.example.com)
    ↓
[PostgreSQL + Redis] (Internal network only)
```

### Repository Structure

```
backend-infra/
├── docker-compose.yml         # Main orchestration
├── setup-vps.sh              # Initial VPS setup script
├── .github/workflows/        # GitHub Actions CI/CD
│   └── deploy-infra.yml
├── traefik/                  # Reverse proxy config
│   ├── traefik.yml
│   └── acme.json            # SSL certificates
└── README.md
```

### Services

- **Traefik** - Reverse proxy, SSL termination, load balancing
- **PostgreSQL** - Primary database with health checks
- **Redis** - Caching and session storage
- **Backend Apps** - Your Node.js/Express applications

---

## 🔐 Environment Variables

Environment variables are **never committed to Git**. They're stored securely on your VPS in `/opt/infra/env/`.

### Directory Structure

```bash
/opt/infra/env/
├── database.env           # PostgreSQL credentials
├── app-1-backend.env      # App 1 environment
├── app-2-backend.env      # App 2 environment
└── app-3-backend.env      # App 3 environment (future)
```

### Required Variables

**Database (`database.env`):**

```env
POSTGRES_PASSWORD=your_secure_postgres_password
```

**Each App (`app-*-backend.env`):**

```env
PORT=3000
NODE_ENV=production
DATABASE_URL=postgres://postgres:your_password@postgres:5432/app_database
REDIS_URL=redis://redis:6379
JWT_SECRET=your_unique_jwt_secret
```

### Security Best Practices

- Use `openssl rand` to generate strong passwords
- Different JWT secrets for each app
- File permissions: `chmod 600 /opt/infra/env/*.env`
- Never commit `.env` files to version control

---

## 🚀 CI/CD Deployment

### How It Works

```
Push Code → GitHub Actions → Build/Test → Deploy to VPS
```

**Two Deployment Types:**

1. **Infrastructure Changes** (this repo)

   - Updates to `docker-compose.yml`, Traefik config, networks
   - Triggers full infrastructure redeploy

2. **Application Changes** (your app repos)
   - Code changes in your backend applications
   - Builds new Docker images and deploys them

### GitHub Actions Workflows

**Infrastructure Repository:**

- **Trigger:** Push to `main` branch
- **Action:** SSH to VPS → `git pull` → `docker compose up -d`

**Application Repositories:**

- **Trigger:** Push to `main` branch
- **Action:** Build Docker image → Push to Docker Hub → SSH to VPS → Deploy

### Required GitHub Secrets

Add these to **every repository** (infra + all app repos):

```env
DOCKER_USERNAME=your_dockerhub_username
DOCKER_PASSWORD=your_dockerhub_password
VPS_IP=your.vps.ip.address
VPS_USERNAME=root  # or your SSH username
VPS_SSH_KEY=-----BEGIN OPENSSH PRIVATE KEY-----
...your private key content...
-----END OPENSSH PRIVATE KEY-----
VPS_PORT=22  # optional, defaults to 22
```

### SSH Key Setup

```bash
# Generate SSH key pair
ssh-keygen -t ed25519 -C "your-email@example.com" -f ~/.ssh/vps_deploy

# Copy PUBLIC key to VPS
ssh-copy-id -i ~/.ssh/vps_deploy.pub root@your-vps-ip

# Copy PRIVATE key content to GitHub secret VPS_SSH_KEY
cat ~/.ssh/vps_deploy
```

---

## 🧪 Testing & Monitoring

### Local Development Testing

```bash
# Test your app locally before pushing
cd your-app-repo
npm install
npm start
# Visit: http://localhost:3000/health
```

### Production Testing

```bash
# SSH to VPS
ssh root@your-vps-ip
cd /opt/backend-infra

# Check all services
docker compose ps

# Test your endpoints
curl https://your-app.example.com/health
curl https://your-app.example.com/api/status

# View logs
docker compose logs your-app-backend
```

### Health Monitoring

Each deployment includes automatic health checks:

```bash
# Check if app is responding
docker compose exec your-app-backend curl -f http://localhost:3000/health

# Monitor all services
docker compose ps
docker stats
```

---

## 🔧 Adding New Applications

### 1. Create App Repository

Create a new GitHub repository with this structure:

```
your-new-app/
├── Dockerfile
├── package.json
├── index.js          # Your Express app
├── .github/
│   └── workflows/
│       └── deploy.yml # Copy from existing app
└── README.md
```

### 2. Update Infrastructure

**Add service to `docker-compose.yml`:**

```yaml
your-app-backend:
  image: yourdockerhub/your-app-backend:latest
  container_name: your-app-backend
  restart: always
  env_file:
    - /opt/infra/env/your-app-backend.env
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
    - "traefik.http.routers.yourapp.rule=Host(`your-app.example.com`)"
    - "traefik.http.routers.yourapp.entrypoints=websecure"
    - "traefik.http.routers.yourapp.tls=true"
    - "traefik.http.routers.yourapp.tls.certresolver=le"
    - "traefik.http.services.yourapp.loadbalancer.server.port=3000"
```

### 3. Create Environment File

```bash
# On VPS
nano /opt/infra/env/your-app-backend.env

# Add:
PORT=3000
NODE_ENV=production
DATABASE_URL=postgres://postgres:your_password@postgres:5432/app_database
REDIS_URL=redis://redis:6379
JWT_SECRET=your_unique_jwt_secret

# Set permissions
chmod 600 /opt/infra/env/your-app-backend.env
```

### 4. Configure GitHub Actions

Copy the `deploy.yml` workflow from an existing app and update:

```yaml
# In your-app/.github/workflows/deploy.yml
- name: Build and push Docker image
  uses: docker/build-push-action@v5
  with:
    tags: |
      ${{ secrets.DOCKER_USERNAME }}/your-app-backend:latest
      ${{ secrets.DOCKER_USERNAME }}/your-app-backend:${{ github.sha }}

# In the deploy step
docker compose pull your-app-backend
docker compose up -d your-app-backend
```

### 5. Deploy

```bash
# On VPS
cd /opt/backend-infra
docker compose up -d your-app-backend

# Test
curl https://your-app.example.com/health
```

---

## 🐛 Troubleshooting

### Deployment Issues

**GitHub Actions fails:**

- Check secrets are added correctly
- Verify SSH key has proper permissions
- Ensure VPS_IP and credentials are correct

**Container won't start:**

```bash
# Check logs
docker compose logs your-app-backend

# Check environment variables
docker compose exec your-app-backend env

# Test database connection
docker compose exec postgres pg_isready -U postgres
```

### SSL Certificate Issues

**Certificate not issued:**

```bash
# Check Traefik logs
docker compose logs traefik

# Verify domain DNS points to your VPS
nslookup your-app.example.com

# Restart Traefik
docker compose restart traefik
```

### Database Connection Issues

**Connection refused:**

```bash
# Check PostgreSQL status
docker compose ps postgres

# View database logs
docker compose logs postgres

# Test connection from app container
docker compose exec your-app-backend nc -zv postgres 5432
```

### Network Issues

**Can't access app:**

```bash
# Check Traefik configuration
docker compose logs traefik | grep your-app

# Verify app is listening on port 3000
docker compose exec your-app-backend netstat -tlnp | grep 3000

# Test internal connectivity
docker compose exec your-app-backend curl -f http://localhost:3000/health
```

### Common Commands

```bash
# View all services
docker compose ps

# View logs for specific service
docker compose logs your-app-backend

# Restart specific service
docker compose restart your-app-backend

# View resource usage
docker stats

# Clean up unused images
docker image prune -f
```

---

## 📋 Complete Setup Checklist

### Initial Setup

- [ ] Run `setup-vps.sh` on your VPS
- [ ] Generate and set secure passwords in `/opt/infra/env/`
- [ ] Configure SSH keys for GitHub Actions
- [ ] Add GitHub secrets to all repositories
- [ ] Start infrastructure with `docker compose up -d`

### Testing

- [ ] Test apps locally before pushing
- [ ] Verify all services are running: `docker compose ps`
- [ ] Test health endpoints via HTTPS
- [ ] Check SSL certificates are valid

### Deployment

- [ ] Push infrastructure changes to trigger redeploy
- [ ] Push app changes to trigger build/deploy
- [ ] Monitor GitHub Actions for successful deployments
- [ ] Verify apps are accessible via custom domains

### Production

- [ ] Set up monitoring and alerting
- [ ] Configure backup strategy for PostgreSQL
- [ ] Set up log aggregation
- [ ] Plan scaling strategy for increased load

---

## 🤝 Contributing

1. Fork this repository
2. Create a feature branch
3. Make your changes
4. Test locally and on VPS
5. Push to your fork
6. Create a Pull Request

---

## 📄 License

MIT License - feel free to use this infrastructure for your projects.

---

## 📞 Support

If you encounter issues:

1. Check the troubleshooting section above
2. Review GitHub Actions logs for errors
3. Check VPS logs: `docker compose logs`
4. Verify environment variables are correct
5. Ensure DNS is properly configured

For additional help, check the Docker and Traefik documentation.
