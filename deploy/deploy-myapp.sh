#!/usr/bin/env bash
# Deploy the Flask app from a CI checkout, verify it, and roll back on failure.
#
# Installed to /usr/local/bin/deploy-myapp and allowed (only this command) for
# the gitlab-runner user via sudoers. Because it runs as root, it treats its
# arguments as untrusted input and validates them before doing anything.
#
# Usage: sudo deploy-myapp <source_dir> <version>
set -euo pipefail

APP_DIR=/opt/myapp
SERVICE=myapp
HEALTH_URL=http://127.0.0.1:8000/health
ALLOWED_SOURCE_PREFIX=/home/gitlab-runner/builds/

die() { echo "deploy-myapp: $*" >&2; exit 2; }

[[ $EUID -eq 0 ]] || die "must run as root"
[[ $# -eq 2 ]] || die "usage: deploy-myapp <source_dir> <version>"

src="$(realpath -e -- "$1")" || die "source directory does not exist"
version="$2"

[[ "$src/" == "$ALLOWED_SOURCE_PREFIX"* ]] || die "source must be under $ALLOWED_SOURCE_PREFIX"
[[ "$version" =~ ^[A-Za-z0-9._-]{1,64}$ ]] || die "invalid version string"
for required in app.py requirements.txt templates static; do
  [[ -e "$src/$required" ]] || die "missing $required in source"
done

backup="$APP_DIR/previous"
rollback() {
  echo "deploy-myapp: health check failed, rolling back" >&2
  if [[ -d "$backup/current" ]]; then
    rm -rf "$APP_DIR/current"
    cp -a "$backup/current" "$APP_DIR/current"
    [[ -f "$backup/version.env" ]] && cp -a "$backup/version.env" "$APP_DIR/version.env"
    systemctl restart "$SERVICE" || true
    echo "deploy-myapp: previous release restored" >&2
  else
    echo "deploy-myapp: no previous release to restore" >&2
  fi
  exit 1
}

# Keep the currently running release so it can be restored.
install -d -m 0755 "$APP_DIR"
rm -rf "$backup"
if [[ -d "$APP_DIR/current" ]]; then
  install -d -m 0755 "$backup"
  cp -a "$APP_DIR/current" "$backup/current"
  [[ -f "$APP_DIR/version.env" ]] && cp -a "$APP_DIR/version.env" "$backup/version.env"
fi

# Install dependencies into a virtualenv, then replace the application files.
# Files are owned by root so the service user cannot modify its own code.
[[ -x "$APP_DIR/venv/bin/pip" ]] || python3 -m venv "$APP_DIR/venv"
"$APP_DIR/venv/bin/pip" install --quiet --disable-pip-version-check -r "$src/requirements.txt"

rm -rf "$APP_DIR/current"
install -d -m 0755 "$APP_DIR/current"
cp -a "$src/app.py" "$src/templates" "$src/static" "$APP_DIR/current/"
chown -R root:root "$APP_DIR/current"

printf 'APP_VERSION=%s\n' "$version" > "$APP_DIR/version.env"
chmod 0644 "$APP_DIR/version.env"

systemctl restart "$SERVICE"

for attempt in $(seq 1 10); do
  if curl -fsS --max-time 2 "$HEALTH_URL" > /dev/null; then
    echo "deploy-myapp: version $version is healthy (attempt $attempt)"
    exit 0
  fi
  sleep 1
done

rollback
