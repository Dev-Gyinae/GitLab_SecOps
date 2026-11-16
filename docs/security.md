# Security

## Controls and what they mitigate

| Control | Threat addressed |
|---------|------------------|
| UFW default deny, minimal open ports | Exposure of services that should not be reachable |
| SSH key-only, root login disabled, `MaxAuthTries 3` | Password guessing, direct root compromise |
| UFW SSH rate limiting and Fail2ban `sshd` jail | Automated brute-force attempts |
| Fail2ban nginx rate-limit jail, nginx `limit_req` | Request flooding against the application |
| Sudo restricted to one validated deploy script | A compromised pipeline job escalating to arbitrary root commands |
| Non-root service user, read-only filesystem, no capabilities, `NoNewPrivileges` | Impact of a vulnerability in the web application |
| App files owned by root | Application tampering with its own code |
| gunicorn bound to localhost behind nginx | Direct exposure of the application server |
| Security headers and strict CSP | Clickjacking, MIME sniffing, content injection |
| Unattended security updates | Running known-vulnerable packages |
| Pinned dependency versions | Unreviewed dependency changes; reproducible builds |
| Post-deploy health check with rollback | Shipping a broken release |

## Original configuration compared with this revision

The first version of the project met the brief but had weaknesses that this revision addresses. They are listed here because identifying them is part of the work.

| Area | Original | Revision |
|------|----------|----------|
| Credentials | GitLab root password written in the README | Removed from the working tree; no secrets in the repository |
| Tests | The test job printed a success message and tested nothing | Real pytest suite plus flake8, with JUnit reporting |
| App server | Flask development server on all interfaces, port 5000 open | gunicorn on localhost behind nginx |
| Process management | `nohup` and `pkill` run through sudo | systemd service with sandboxing |
| Privileges | Multiple sudo commands in the deploy job | One validated script allowed through sudo |
| Firewall | 5000 and 8080 open to anywhere, SSH unrestricted | Only required ports open, SSH rate limited |
| SSH config | `sed` edits with duplicated settings and an appended line | Drop-in file validated with `sshd -t`, plus a lockout guard |
| Verification | Deploy only checked that a process answered | Health check with automatic rollback |
| Page content | Hard-coded "Operational" status and a request-time "last deployed" timestamp | Real process start time and deployed commit version |
| Dependencies | `Flask==2.3.0` | Current Flask and gunicorn releases, pinned |

## Known gaps

These are open on purpose and tracked in the roadmap in the [README](../README.md#limitations-and-roadmap).

- **Credential history.** The original README exposed the GitLab root password in earlier commits. Removing it from the current files does not remove it from git history. The instance no longer exists, but the history should be rewritten or the repository recreated before it is shared widely, and the password must never be reused.
- **No TLS.** GitLab and the app are served over HTTP. Credentials and session cookies cross the network in clear text. A Let's Encrypt or internal CA certificate is the next step.
- **Shell executor.** Jobs run on the host itself, so anyone who can push to a protected branch can run code as the runner user. Containerised or ephemeral runners would isolate jobs better.
- **Single host.** GitLab, the runner and the application share one VM, so a compromise of one is close to a compromise of all.
- **No security scanning yet.** The pipeline does not yet run secret detection, SAST, dependency scanning or DAST.
- **Remote installer scripts.** GitLab's apt repository setup is downloaded and executed. The script is saved to a file first, but its integrity is not verified.
- **Fail2ban coverage.** The nginx jail covers the host nginx that fronts the app. GitLab's bundled nginx logs elsewhere and is not covered by a jail.
- **No monitoring or backups.** There is no alerting, log shipping or GitLab backup routine.
- **Unvalidated on a fresh host.** The revised provisioning scripts and configs were checked with `bash -n` and `shellcheck` and the application with its test suite, but they have not been applied to a new VM.
