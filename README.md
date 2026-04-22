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

The inventory lives in `config/hosts.yml`. It defines the `raspberrypi` host group used by all playbooks.

### Running playbooks

```bash
# Verify connectivity
ansible-playbook playbooks/ping.yml

# Full bootstrap (dependencies, Docker, shell setup)
ansible-playbook playbooks/bootstrap_rpi.yml

# Individual setup tasks
ansible-playbook playbooks/ssh_enable.yml
ansible-playbook playbooks/setup_motd.yml
ansible-playbook playbooks/setup_hstr.yml
ansible-playbook playbooks/setup_zsh_completions.yml

# S3 backup / restore of config files
ansible-playbook playbooks/s3/upload_to_s3.yml
ansible-playbook playbooks/s3/download_from_s3.yml
```

### Bootstrap playbook (`bootstrap_rpi.yml`)

Runs the following tasks in order:

1. **Install dependencies** — `python3`, `awscli`, `git`, `jq`, `ripgrep`, `htop`, `hstr`, `exa`, `bash-completion`, `pip3`, `boto`/`botocore`
2. **Setup custom MOTD** — deploys a shell script that shows system info on login
3. **Update APT cache**
4. **Install Docker** — adds the official Docker repo, installs `docker-ce`, adds the user to the `docker` group
5. **Configure hstr** — shell history search tool with zsh integration
6. **Setup zsh completions** — zsh auto-suggestions

---

## Docker services

All services are defined in `docker-compose.yml` (plus `apps/nextcloud/docker-compose.yml` for Nextcloud).

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
docker compose up -d

# Start Nextcloud stack separately
cd apps/nextcloud && docker compose up -d
```

### Environment files

Sensitive config is kept in env files (not committed):

| File | Used by |
|---|---|
| `config/honeygain.env` | `honeygain` container |
| `config/earnapp.env` | `earnapp` container |
| `config/nextcloud.env` | `nextcloud-db` container |

Copy and fill in values before starting:

```bash
cp config/nextcloud.env.example config/nextcloud.env  # if an example exists
```

### Homepage dashboard

The dashboard at `http://<pi-ip>:4000` is configured via `apps/homepage/`. Service widgets pull live stats from Nginx Proxy Manager, Grafana, Portainer, Pi-hole, Nextcloud, and Paperless.

---

## S3 backups

AWS credentials and bucket name are read from `config/aws.yml`. The upload playbook backs up the three env files to `s3://<bucket>/config/`.

```bash
ansible-playbook playbooks/s3/upload_to_s3.yml
ansible-playbook playbooks/s3/download_from_s3.yml
```

---

## Enable SSH

If SSH is not yet running on a fresh Pi:

```bash
ansible-playbook playbooks/ssh_enable.yml
```

This installs `openssh-server`, enables the service, and prints its status.
