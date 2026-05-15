#!/usr/bin/env bash
set -euo pipefail

# Robust deploy script for Naturalist API on CentOS/Rocky/AlmaLinux
# Run as root: sudo bash deploy_full.sh
# This script will:
# - install required system packages (best-effort)
# - create app user, clone/pull repo
# - create virtualenv (venv) with fallbacks
# - install PyTorch (CPU) + numpy wheels, then remaining pip requirements
# - create systemd service and nginx reverse-proxy
# - configure firewall and SELinux boolean

GIT_REPO="https://github.com/gabriel-arrvda/Naturalist.git"
BRANCH="main"
APP_USER="naturalist"
APP_HOME="/home/${APP_USER}"
APP_DIR="${APP_HOME}/app"
VENV_DIR="${APP_DIR}/venv"
VPS_IP="187.127.253.190"
PYTORCH_VERSION="2.2.2"
NUMPY_VERSION="1.26.4"
LOG="/var/log/naturalist-deploy.log"

exec > >(tee -a "$LOG") 2>&1

echo "=== Deploy started: $(date -u) ==="

if [ "$EUID" -ne 0 ]; then
  echo "This script requires root. Run with: sudo bash $0" >&2
  exit 1
fi

echo "Updating system and installing packages (best-effort)..."
DNF_PKGS=(epel-release git python3 python3-pip python3-devel gcc gcc-c++ make redhat-rpm-config libffi-devel openssl-devel openblas-devel lapack-devel unzip jq nginx firewalld)

# Update and install
dnf update -y || true
# Try installing packages; tolerate missing ones
for pkg in "${DNF_PKGS[@]}"; do
  echo "Installing: $pkg"
  dnf install -y "$pkg" || echo "Package $pkg not available or failed, continuing"
done

# Try install python3-venv or python3-virtualenv
if dnf list available python3-venv >/dev/null 2>&1; then
  dnf install -y python3-venv || true
else
  dnf install -y python3-virtualenv || true
fi

# Create app user
if ! id -u "$APP_USER" >/dev/null 2>&1; then
  useradd -m -s /bin/bash "$APP_USER"
  echo "Created user $APP_USER"
fi

# Ensure home dir exists
mkdir -p "$APP_HOME"
chown "$APP_USER":"$APP_USER" "$APP_HOME"

# Clone or update repo as app user
if [ ! -d "$APP_DIR/.git" ]; then
  echo "Cloning repo into $APP_DIR"
  sudo -u "$APP_USER" git clone -b "$BRANCH" "$GIT_REPO" "$APP_DIR"
else
  echo "Updating repo in $APP_DIR"
  sudo -u "$APP_USER" bash -lc "cd $APP_DIR && git fetch --all && git checkout $BRANCH && git pull --ff-only origin $BRANCH" || echo "git pull failed, continuing"
fi

# Create virtualenv with fallbacks
echo "Creating virtualenv in $VENV_DIR"
if [ ! -d "$VENV_DIR" ]; then
  # Preferred: python3 -m venv
  if sudo -u "$APP_USER" bash -lc "python3 -m venv $VENV_DIR >/dev/null 2>&1"; then
    echo "Created venv with python3 -m venv"
  else
    echo "python3 -m venv failed, trying virtualenv module"
    if sudo -u "$APP_USER" bash -lc "python3 -m virtualenv $VENV_DIR >/dev/null 2>&1"; then
      echo "Created venv with python3 -m virtualenv"
    else
      echo "virtualenv module missing; installing via pip user and retrying"
      sudo -u "$APP_USER" bash -lc "python3 -m pip install --user virtualenv && ~/.local/bin/virtualenv $VENV_DIR"
    fi
  fi
else
  echo "Virtualenv already exists"
fi

# Install python deps inside venv
echo "Installing Python packages inside venv"
sudo -u "$APP_USER" bash -lc "set -e; source $VENV_DIR/bin/activate; pip install --upgrade pip setuptools wheel build; python3 -V && uname -m; pip cache purge || true; \
  echo 'Installing PyTorch (CPU) wheel'; pip install --index-url https://download.pytorch.org/whl/cpu torch==${PYTORCH_VERSION}; \
  echo 'Installing numpy wheel'; pip install numpy==${NUMPY_VERSION}; \
  # prepare requirements: temporarily remove torch and numpy to avoid rebuild
  cp requirements.txt requirements.txt.deploy.bak || true; \
  sed -i.bak -E '/^torch|^numpy/Id' requirements.txt || true; \
  echo 'Installing remaining requirements'; pip install -r requirements.txt || (echo 'pip install -r failed, restoring requirements and exiting' && mv requirements.txt.deploy.bak requirements.txt && exit 1); \
  # restore original requirements
  if [ -f requirements.txt.deploy.bak ]; then mv requirements.txt.deploy.bak requirements.txt; fi; \
  deactivate"

# Create systemd service
echo "Creating systemd service file"
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

systemctl daemon-reload || true
systemctl enable --now naturalist.service || echo 'failed to enable/start naturalist.service, check journalctl -u naturalist'

# Nginx configuration
echo "Writing nginx config"
cat > /etc/nginx/conf.d/naturalist.conf <<NGINX
server {
    listen 80;
    server_name ${VPS_IP};

    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
NGINX

nginx -t && systemctl enable --now nginx || echo 'nginx start failed'
systemctl restart nginx || true

# Firewall
echo 'Configuring firewall'
systemctl enable --now firewalld || true
firewall-cmd --permanent --add-service=http || true
firewall-cmd --reload || true

# SELinux boolean for nginx to connect to network
if command -v getenforce >/dev/null 2>&1; then
  if [ "$(getenforce)" = "Enforcing" ]; then
    echo 'Enabling SELinux boolean httpd_can_network_connect'
    setsebool -P httpd_can_network_connect 1 || true
  fi
fi

# Final status
echo 'Deployment complete. Services status:'
systemctl status naturalist --no-pager || true
systemctl status nginx --no-pager || true

echo "You can test locally on the VPS with: curl -sI http://127.0.0.1:8000"
echo "And from outside: http://$VPS_IP"

echo "Logs: sudo journalctl -u naturalist -f"

exit 0
