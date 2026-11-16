# Evidence from the original deployment

These files are command output captured from the first version of the project, before the revision in this repository.

| File | Shows |
|------|-------|
| `ufw_status_original.txt` | UFW active, default deny incoming, ports 22, 80, 443, 5000 and 8080 allowed |
| `fail2ban_status_original.txt` | Fail2ban running with two jails: `sshd` and `nginx-http-auth` |
| `ssh_config_original.txt` | SSH settings applied: root login disabled, password authentication disabled |

They describe the original state. The current scripts change it: ports 5000 and 8080 are closed, SSH is hardened through a validated drop-in file, and the nginx jail is `nginx-limit-req`. See [../security.md](../security.md) for the comparison.
