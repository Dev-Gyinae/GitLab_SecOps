from flask import Flask
import datetime
app = Flask(__name__)
@app.route('/')
def home():
    return f"<html><head><title>Samuel Gyinae - DevSecOps</title></head><body style='font-family:Arial;margin:40px;'><h1>DevSecOps Assignment - Samuel Gyinae</h1><h2 style='color:green;'>Status: COMPLETED</h2><hr/><h3>Accomplishments:</h3><ul><li>Linux Server Setup (Ubuntu 24.04 LTS)</li><li>Security Implementation (UFW + Fail2ban + SSH Hardening)</li><li>GitLab Server with CI/CD Pipeline</li><li>GitLab Runner (Shell Executor)</li><li>Web Application Auto-Deployment</li></ul><h3>Technical Stack:</h3><ul><li>Ubuntu 24.04 LTS (4 CPU / 3.8GB RAM)</li><li>GitLab CE</li><li>Python 3.12 + Flask</li></ul><hr/><p>Last Deployed: {datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S UTC')}</p><p>Pipeline Status: <strong style='color:green;'>Operational</strong></p></body></html>"
@app.route('/health')
def health():
    return "OK"
if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
