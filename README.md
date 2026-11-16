# DevSecOps Environment Setup - Samuel Gyinae

## Server Specifications
| Component | Details |
|-----------|---------|
| OS | Ubuntu 24.04 LTS |
| CPU | 4 cores |
| RAM | 3.8 GB |
| IP Address | 192.168.122.197 |

## Access Information
| Service | URL | Credentials |
|---------|-----|-------------|
| GitLab | http://192.168.122.197 | root / DevSecOps2025 |
| Web App | http://192.168.122.197:5000 | Public |

## Security Measures
- UFW Firewall (ports: 22,80,443,5000,8080)
- Fail2ban (SSH + nginx jails)
- SSH Hardening (root login disabled, password auth off)

## CI/CD Pipeline Stages
1. **test** - Validates application code
2. **deploy** - Copies app to /var/www/myapp and starts service


work on it again to make it a portfolio worthy project 
