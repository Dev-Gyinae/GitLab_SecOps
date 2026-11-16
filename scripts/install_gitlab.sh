#!/usr/bin/env bash
# Install GitLab CE and GitLab Runner on the provisioned host.
#
#   sudo EXTERNAL_URL=http://<host-ip-or-name> ./scripts/install_gitlab.sh
#
# Both installers are GitLab's documented apt repository scripts. They are
# downloaded to a file first so they can be inspected before they run.
set -euo pipefail

[[ $EUID -eq 0 ]] || { echo "run as root (use sudo)" >&2; exit 1; }
: "${EXTERNAL_URL:?set EXTERNAL_URL, for example EXTERNAL_URL=http://192.168.122.197}"

export DEBIAN_FRONTEND=noninteractive
workdir="$(mktemp -d)"
trap 'rm -rf "$workdir"' EXIT

echo "==> Adding GitLab CE repository"
curl -fsSL -o "$workdir/gitlab-ce.sh" https://packages.gitlab.com/install/repositories/gitlab/gitlab-ce/script.deb.sh
bash "$workdir/gitlab-ce.sh"

echo "==> Installing GitLab CE (this takes several minutes)"
EXTERNAL_URL="$EXTERNAL_URL" apt-get install -y gitlab-ce

echo "==> Adding GitLab Runner repository"
curl -fsSL -o "$workdir/gitlab-runner.sh" https://packages.gitlab.com/install/repositories/runner/gitlab-runner/script.deb.sh
bash "$workdir/gitlab-runner.sh"
apt-get install -y gitlab-runner

cat <<EOF

GitLab CE and GitLab Runner are installed. Manual steps remain:

  1. Open $EXTERNAL_URL and set the initial root password. The generated one is in
     /etc/gitlab/initial_root_password (the file is deleted automatically after 24 hours).
  2. In the GitLab UI create a project runner (Settings > CI/CD > Runners) and copy its token.
  3. Register it with the shell executor:

       sudo gitlab-runner register --non-interactive \\
         --url "$EXTERNAL_URL" --token "<runner-token>" --executor shell

  4. Push this repository to the GitLab project. The pipeline deploys on the default branch.
EOF
