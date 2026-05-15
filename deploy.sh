#!/usr/bin/env bash
set -euo pipefail

# Deploy script for Naturalist API (CentOS/Rocky/AlmaLinux)
# Usage: run as root: sudo bash deploy.sh

GIT_REPO="${GIT_REPO:-https://github.com/gabriel-arrvda/Naturalist.git}"
BRANCH="${BRANCH:-main}"
APP_USER="${APP_USER:-naturalist}"
APP_DIR="${APP_DIR:-/home/${APP_USER}/app}"
VENV_DIR="${VENV_DIR:-${APP_DIR}/venv}"
VPS_IP="${VPS_IP:-187.127.253.190}"

if [ "$EUID" -ne 0 ]; then
  echo "This script must be run as root. Use: sudo bash $0" >&2
  exit 1
fi

echo "Updating system and installing packages..."
DNF_PKGS=(epel-release git python3 python3-venv python3-pip nginx firewalld 
          gcc gcc-c++ make python3-devel redhat-rpm-config openblas-devel lapack-devel libffi-devel openssl-devel unzip jq)

# Install packages
dnf update -y
# epel may already be included by package manager above
dnf install -y "${DNF_PKGS[@]}"

# Create app user if missing
if ! id -u "$APP_USER" >/dev/null 2>&1; then
  useradd -m -s /bin/bash "$APP_USER"
  echo "Created user $APP_USER"
fi

# Clone or update repo
if [ ! -d "$APP_DIR" ]; then
  sudo -u "$APP_USER" git clone -b "$BRANCH" "$GIT_REPO" "$APP_DIR"
else
  sudo -u "$APP_USER" bash -lc "cd $APP_DIR && git fetch --all && git checkout $BRANCH && git pull --ff-only origin $BRANCH"
fi

# Create venv and install Python deps as app user
sudo -u "$APP_USER" bash <<'EOF'
set -e
cd "$APP_DIR"
python3 -m venv venv
source venv/bin/activate
pip install --upgrade pip setuptools wheel build
# Install PyTorch CPU wheel (explicit index) and compatible numpy first to avoid building from source
pip install --index-url https://download.pytorch.org/whl/cpu "torch==2.2.2"
pip install numpy==1.26.4
# Install remaining requirements
pip install -r requirements.txt
# Ensure gunicorn is available (requirements includes it)
deactivate
EOF

# Create systemd service
cat > /etc/systemd/system/naturalist.service <<SERVICE
[Unit]
Description=Naturalist FastAPI
After=network.target

[Service]
User=${APP_USER}
Group=${APP_USER}
WorkingDirectory=${APP_DIR}
Environment="PATH=${VENV_DIR}/bin"
ExecStart=${VENV_DIR}/bin/gunicorn -k uvicorn.workers.UvicornWorker -w 4 -b 127.0.0.1:8000 src.app:app
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
SERVICE

systemctl daemon-reload
systemctl enable --now naturalist.service || true
systemctl restart naturalist.service || true

# Nginx config
cat > /etc/nginx/conf.d/naturalist.conf <<NGINX
server {
    listen 80;
    server_name ${VPS_IP};

    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
NGINX

nginx -t && systemctl enable --now nginx || true
systemctl restart nginx || true

# Firewall
systemctl enable --now firewalld || true
firewall-cmd --permanent --add-service=http || true
firewall-cmd --reload || true

# SELinux: allow nginx/httpd to connect to network (if SELinux enabled)
if command -v sestatus >/dev/null 2>&1; then
  if sestatus | grep -q "SELinux status:.*enabled"; then
    if command -v setsebool >/dev/null 2>&1; then
      setsebool -P httpd_can_network_connect 1 || true
    fi
  fi
fi

echo "Deployment finished. Check services:"
echo "  systemctl status naturalist.service nginx"
echo "Logs: sudo journalctl -u naturalist -f"

echo "Test locally on VPS: curl -sI http://127.0.0.1:8000"

echo "If anything fails, inspect journalctl and /var/log/nginx/error.log"
