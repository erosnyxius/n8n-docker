# n8n Production-Ready Setup 

![n8n-prod](/n8n-prod.PNG)

A complete, robust, and scalable Docker deployment for **n8n**. This stack includes PostgreSQL, Caddy (Reverse Proxy/SSL), automated local & S3 backups, and **External Task Runners** for high-performance Python and JavaScript execution.

## Features

* **n8n with External Task Runners:** Runs Python and JS code in isolated worker containers (preventing the main n8n process from crashing during heavy tasks).
* **PostgreSQL 16:** Robust database backend instead of SQLite.
* **Caddy Server:** Automatic HTTPS/SSL management and reverse proxy.
* **Automated Backups:**
* **Local:** Daily rolling backups of the PostgreSQL database (kept for 7 days).
* **Offsite (Optional):** Automatic syncing of backups to any S3-compatible storage (AWS S3, Cloudflare R2, MinIO, DigitalOcean Spaces) using Rclone.


* **Pre-loaded Libraries:** The task runners come pre-installed with popular data science and utility libraries (Pandas, NumPy, Lodash, Axios, etc.).
* **Interactive Setup:** Includes a `setup.sh` script to configure the environment automatically.

---

## Architecture

| Service | Description |
| --- | --- |
| **n8n** | The main workflow automation tool. |
| **db** | PostgreSQL 16 database. |
| **task-runner** | Dedicated container for executing custom Python/JS code. |
| **caddy** | Reverse proxy that handles domain names and SSL certificates. |
| **backup-local** | Dumps the database daily to a local folder. |
| **backup-s3** | Syncs the local backup folder to remote S3 storage. |

---

## Quick Start

### 1. Clone the Repository

```bash
git clone https://github.com/erosnyxius/n8n-docker.git
cd n8n-docker
```

### 2. Run the Setup Wizard

The included script will help you generate secure passwords, encryption keys, and configure your domain/backup settings.

```bash
chmod +x setup.sh
./setup.sh
```

*Follow the on-screen prompts to select Local or Production mode.*

### 3. Start the Stack

```bash
docker compose up -d --build
```

### 4. Access n8n

* **Local Mode:** `http://localhost:8080`
* **Production Mode:** `https://your-domain.com`

---

## Task Runners & Libraries

This setup uses n8n's **Task Runner** feature. This decouples code execution from the main workflow engine, allowing for heavier processing and better security.

### Pre-Installed Python Libraries:

* `numpy`
* `pandas`
* `requests`
* `beautifulsoup4`

### Pre-Installed JavaScript Libraries:

* `moment`
* `lodash`
* `uuid`
* `axios`

### Adding More Libraries

To add more libraries, edit the `Dockerfile.runner` file and rebuild the container:

```dockerfile
# Dockerfile.runner

# Add Python libraries here
RUN cd /opt/runners/task-runner-python \
    && uv pip install your-new-library

# Add JS libraries here
RUN cd /opt/runners/task-runner-javascript \
    && pnpm add your-new-library
```

Then run: `docker compose up -d --build`

---

## Backup Configuration

### Local Backups

By default, the `backup-local` service runs **daily**. It dumps the PostgreSQL database to the `./backups` directory (mapped to the volume `shared_backups`). It keeps the last **7 days** of files.

### S3 / Offsite Backups

During `setup.sh`, you can enable S3 backups. If enabled, the `backup-s3` container will sync the `./backups` folder to your bucket immediately after the local backup completes.

To manually configure S3 later, edit the `.env` file:

```env
S3_ENABLED=true
S3_BUCKET=my-bucket-name
S3_REGION=us-east-1
S3_ACCESS_KEY_ID=xxxx
S3_SECRET_ACCESS_KEY=xxxx
S3_ENDPOINT=https://s3.amazonaws.com # Or your provider's endpoint

```

---

## Project Structure

```text
.
├── Caddyfile                 # Caddy reverse proxy configuration
├── Dockerfile.runner         # Custom image definition for Task Runners
├── README.md
├── docker-compose.yml        # Main service orchestration
├── n8n-task-runners.json     # Configuration mapping for runners
└── setup.sh                  # Interactive configuration script
```

## Manual Configuration (Optional)

If you prefer not to use `setup.sh`, you can rename `.env.example` to `.env` and fill in the values manually.

```bash
cp .env.example .env
nano .env
```

*Note: Ensure you generate secure strings for `N8N_ENCRYPTION_KEY` and `N8N_RUNNERS_TOKEN`.*

## Contributing

Feel free to submit issues or pull requests if you have suggestions for improvements or new default libraries for the runner image.