#!/usr/bin/env bash
# Provision a fresh Ubuntu 24.04 host: security hardening plus the app runtime.
#
# Run from a normal admin account that already has an SSH key installed:
#   sudo ./scripts/provision.sh
#
# GitLab itself is installed separately by scripts/install_gitlab.sh.
set -euo pipefail

die() { echo "provision: $*" >&2; exit 1; }
log() { echo "==> $*"; }

[[ $EUID -eq 0 ]] || die "run as root (use sudo)"

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ADMIN_USER="${SUDO_USER:-}"

# Lockout guard: password logins are disabled below, so refuse to continue
# unless the admin account has a key to log in with.
[[ -n "$ADMIN_USER" && "$ADMIN_USER" != "root" ]] || die "run via sudo from a non-root admin user"
ADMIN_HOME="$(getent passwd "$ADMIN_USER" | cut -d: -f6)"
[[ -s "$ADMIN_HOME/.ssh/authorized_keys" ]] \
  || die "$ADMIN_HOME/.ssh/authorized_keys is empty; add your public key first"

install_packages() {
  log "Installing packages"
  export DEBIAN_FRONTEND=noninteractive
  apt-get update
  apt-get upgrade -y
  apt-get install -y ufw fail2ban nginx python3-venv python3-pip curl unattended-upgrades
}

harden_ssh() {
  log "Hardening SSH"
  # sshd keeps the FIRST value it reads for a setting, and drop-ins are read in
  # filename order, so this file is named 00- to win over cloud-init's 50- file.
  cat > /etc/ssh/sshd_config.d/00-hardening.conf <<'EOF'
PermitRootLogin no
PasswordAuthentication no
KbdInteractiveAuthentication no
PubkeyAuthentication yes
MaxAuthTries 3
LoginGraceTime 30
X11Forwarding no
AllowAgentForwarding no
EOF
  sshd -t                      # abort (set -e) before restarting if the config is invalid
  systemctl restart ssh
  log "Effective SSH settings:"
  sshd -T | grep -E '^(permitrootlogin|passwordauthentication|kbdinteractiveauthentication|pubkeyauthentication|maxauthtries) '
}

configure_firewall() {
  log "Configuring UFW"
  ufw default deny incoming
  ufw default allow outgoing
  ufw limit 22/tcp             # SSH, rate limited
  ufw allow 80/tcp             # GitLab (HTTP)
  ufw allow 443/tcp            # GitLab (HTTPS, once TLS is configured)
  ufw allow 8088/tcp           # Application (nginx)
  # Remove rules from the original setup that exposed the dev server and 8080.
  ufw delete allow 5000/tcp 2>/dev/null || true
  ufw delete allow 8080/tcp 2>/dev/null || true
  ufw delete allow 22/tcp 2>/dev/null || true   # superseded by the rate-limited rule
  ufw --force enable
  ufw status verbose
}

configure_fail2ban() {
  log "Configuring Fail2ban"
  cat > /etc/fail2ban/jail.d/10-project.local <<'EOF'
[DEFAULT]
bantime  = 1h
findtime = 10m
maxretry = 5

[sshd]
enabled  = true
maxretry = 4

[nginx-limit-req]
enabled  = true
port     = 8088
logpath  = /var/log/nginx/error.log
EOF
  systemctl enable fail2ban
  systemctl restart fail2ban
}

enable_auto_updates() {
  log "Enabling unattended security updates"
  cat > /etc/apt/apt.conf.d/20auto-upgrades <<'EOF'
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
EOF
}

install_app_runtime() {
  log "Installing application runtime"
  id myapp >/dev/null 2>&1 \
    || useradd --system --no-create-home --shell /usr/sbin/nologin myapp
  install -d -m 0755 /opt/myapp

  install -m 0755 -o root -g root "$REPO_DIR/deploy/deploy-myapp.sh" /usr/local/bin/deploy-myapp
  install -m 0644 "$REPO_DIR/deploy/myapp.service" /etc/systemd/system/myapp.service
  systemctl daemon-reload
  systemctl enable myapp

  install -m 0644 "$REPO_DIR/deploy/nginx-myapp.conf" /etc/nginx/sites-available/myapp
  ln -sf /etc/nginx/sites-available/myapp /etc/nginx/sites-enabled/myapp
  rm -f /etc/nginx/sites-enabled/default
  nginx -t
  systemctl reload nginx

  # The runner may run exactly one privileged command: the deploy script.
  local sudoers_tmp
  sudoers_tmp="$(mktemp)"
  echo 'gitlab-runner ALL=(root) NOPASSWD: /usr/local/bin/deploy-myapp *' > "$sudoers_tmp"
  visudo -cf "$sudoers_tmp"
  install -m 0440 -o root -g root "$sudoers_tmp" /etc/sudoers.d/gitlab-runner-deploy
  rm -f "$sudoers_tmp"
}

install_packages
harden_ssh
configure_firewall
configure_fail2ban
enable_auto_updates
install_app_runtime

log "Done. Next: scripts/install_gitlab.sh, then push to GitLab so the pipeline performs the first deploy."
