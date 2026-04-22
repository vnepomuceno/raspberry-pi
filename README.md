# raspberry-pi

Ansible playbooks and Docker Compose configuration for bootstrapping and managing a self-hosted Raspberry Pi home server.

## Overview

| Layer | Tool | Purpose |
|---|---|---|
| Provisioning | Ansible | Install packages, configure shell, enable SSH |
| Services | Docker Compose | Run containerised apps |
| Reverse proxy | Nginx Proxy Manager | TLS termination, subdomain routing |
| VPN | Tailscale | Remote access via custom domain subdomains |

---

## Prerequisites

- Ansible installed on your local machine (`pip install ansible`)
- SSH access to the Pi (see [Enable SSH](#enable-ssh))
- Docker and Docker Compose on the Pi (installed by the bootstrap playbook)

---

## Ansible

### Inventory

Copy the example and fill in your Pi's IP and credentials:

```bash
cp ansible/inventory/hosts.ini.example ansible/inventory/hosts.ini
```

### Running playbooks

```bash
# Verify connectivity
ansible-playbook ansible/playbooks/ping.yml

# Full bootstrap (dependencies, Docker, shell setup)
ansible-playbook ansible/playbooks/bootstrap.yml

# Individual setup tasks
ansible-playbook ansible/playbooks/ssh_enable.yml
ansible-playbook ansible/playbooks/setup_motd.yml
ansible-playbook ansible/playbooks/setup_hstr.yml
ansible-playbook ansible/playbooks/setup_zsh_completions.yml

# S3 backup / restore of config files
ansible-playbook ansible/playbooks/s3/upload.yml
ansible-playbook ansible/playbooks/s3/download.yml

# Operational tasks
ansible-playbook ansible/playbooks/ops/restart_earnapp.yml
```

### Bootstrap playbook (`ansible/playbooks/bootstrap.yml`)

Runs the following tasks in order:

1. **Install dependencies** — `python3`, `awscli`, `git`, `jq`, `ripgrep`, `htop`, `hstr`, `exa`, `bash-completion`, `pip3`, `boto`/`botocore`
2. **Setup custom MOTD** — deploys a shell script that shows system info on login
3. **Update APT cache**
4. **Install Docker** — adds the official Docker repo, installs `docker-ce`, adds the user to the `docker` group
5. **Configure hstr** — shell history search tool with zsh integration
6. **Setup zsh completions** — zsh auto-suggestions

---

## Docker services

All services are defined in `docker/docker-compose.yml` (plus `docker/nextcloud/docker-compose.yml` for Nextcloud).

| Service | Image | Port(s) | Description |
|---|---|---|---|
| `nginx` | `jc21/nginx-proxy-manager` | 80, 81, 443 | Reverse proxy + Let's Encrypt TLS |
| `tailscale` | `tailscale/tailscale` | host network | VPN, advertises as exit node |
| `pihole` | `pihole/pihole` | 53, 67, 80 | Network-wide ad blocking + optional DHCP |
| `portainer` | `portainer/portainer-ce` | 9000 | Docker container management UI |
| `homepage` | `ghcr.io/gethomepage/homepage` | 4000 | Self-hosted dashboard |
| `honeygain` | `honeygain/honeygain` | — | Passive income (bandwidth sharing) |
| `earnapp` | `fazalfarhan01/earnapp:lite` | — | Passive income (bandwidth sharing) |
| `nextcloud` | `nextcloud` | 8181 | File sync and collaboration |
| `nextcloud-db` | `yobasystems/alpine-mariadb` | — | MariaDB backend for Nextcloud |

### Starting services

```bash
# Start all services
docker compose -f docker/docker-compose.yml up -d

# Start Nextcloud stack separately
docker compose -f docker/nextcloud/docker-compose.yml up -d
```

### Environment files

Sensitive config is kept in env files (not committed). Copy the examples and fill in values before starting:

| Example file | Copy to | Used by |
|---|---|---|
| `config/honeygain.env.example` | `config/honeygain.env` | `honeygain` container |
| `config/earnapp.env.example` | `config/earnapp.env` | `earnapp` container |
| `config/nextcloud.env.example` | `config/nextcloud.env` | `nextcloud-db` container |
| `config/aws.yml.example` | `config/aws.yml` | S3 playbooks |

### Homepage dashboard

The dashboard at `http://<pi-ip>:4000` is configured via `apps/homepage/`. Service widgets pull live stats from Nginx Proxy Manager, Grafana, Portainer, Pi-hole, Nextcloud, and Paperless.

---

## S3 backups

AWS credentials and bucket name are read from `config/aws.yml`. The upload playbook backs up the three env files to `s3://<bucket>/config/`.

```bash
ansible-playbook ansible/playbooks/s3/upload.yml
ansible-playbook ansible/playbooks/s3/download.yml
```

---

## Enable SSH

If SSH is not yet running on a fresh Pi:

```bash
ansible-playbook ansible/playbooks/ssh_enable.yml
```

This installs `openssh-server`, enables the service, and prints its status.
