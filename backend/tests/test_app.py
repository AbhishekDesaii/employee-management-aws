import pytest

from app import create_app


@pytest.fixture()
def client():
    app = create_app()
    app.config.update(TESTING=True)
    with app.test_client() as c:
        yield c


def test_health(client):
    res = client.get("/api/health")
    assert res.status_code == 200
    assert res.is_json
    assert res.get_json()["status"] == "healthy"


def test_root_meta(client):
    res = client.get("/")
    assert res.status_code == 200
    assert res.get_json()["service"] == "Employee Management API"


def test_list_employees(client):
    res = client.get("/api/employees")
    assert res.status_code == 200
    assert isinstance(res.get_json(), list)


def test_get_employee_by_id(client):
    res = client.get("/api/employees/1")
    assert res.status_code == 200
    assert res.get_json()["id"] == 1


def test_get_employee_not_found(client):
    res = client.get("/api/employees/99999")
    assert res.status_code == 404