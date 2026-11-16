import pytest

from app import create_app


@pytest.fixture()
def client():
    app = create_app()
    app.config.update(TESTING=True)
    return app.test_client()


def test_home_renders_project_page(client):
    response = client.get("/")
    assert response.status_code == 200
    assert b"Secure CI/CD with Flask and GitLab" in response.data


def test_health_returns_ok_json(client):
    response = client.get("/health")
    assert response.status_code == 200
    assert response.get_json() == {"status": "ok"}


def test_version_uses_environment_variable(monkeypatch):
    monkeypatch.setenv("APP_VERSION", "abc1234")
    response = create_app().test_client().get("/version")
    assert response.status_code == 200
    body = response.get_json()
    assert body["version"] == "abc1234"
    assert "started_at" in body


def test_version_defaults_to_dev(monkeypatch):
    monkeypatch.delenv("APP_VERSION", raising=False)
    response = create_app().test_client().get("/version")
    assert response.get_json()["version"] == "dev"


def test_security_headers_present(client):
    headers = client.get("/").headers
    assert headers["X-Content-Type-Options"] == "nosniff"
    assert headers["X-Frame-Options"] == "DENY"
    assert headers["Referrer-Policy"] == "no-referrer"
    assert "default-src 'none'" in headers["Content-Security-Policy"]


def test_unknown_route_returns_404(client):
    assert client.get("/does-not-exist").status_code == 404


def test_stylesheet_is_served(client):
    response = client.get("/static/style.css")
    assert response.status_code == 200
    assert response.mimetype == "text/css"
