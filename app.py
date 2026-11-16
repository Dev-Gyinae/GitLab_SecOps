"""Status page for the Secure CI/CD demonstration project.

The app is intentionally small: the point of the project is the pipeline,
the deployment model and the server hardening around it.
"""
import datetime
import os

from flask import Flask, render_template


def create_app():
    app = Flask(__name__)
    started_at = datetime.datetime.now(datetime.timezone.utc)
    version = os.environ.get("APP_VERSION", "dev")

    @app.get("/")
    def home():
        return render_template(
            "index.html",
            version=version,
            started_at=started_at.strftime("%Y-%m-%d %H:%M:%S UTC"),
        )

    @app.get("/health")
    def health():
        return {"status": "ok"}

    @app.get("/version")
    def version_info():
        return {"version": version, "started_at": started_at.isoformat()}

    @app.after_request
    def set_security_headers(response):
        response.headers["X-Content-Type-Options"] = "nosniff"
        response.headers["X-Frame-Options"] = "DENY"
        response.headers["Referrer-Policy"] = "no-referrer"
        response.headers["Content-Security-Policy"] = (
            "default-src 'none'; style-src 'self'; frame-ancestors 'none'"
        )
        return response

    return app


app = create_app()

if __name__ == "__main__":
    # Local development only. In deployment the app runs under gunicorn.
    app.run(host="127.0.0.1", port=5000)
