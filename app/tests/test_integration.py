from app import app


def test_health_endpoint_integration():
    client = app.test_client()

    response = client.get("/health")

    assert response.status_code == 200
    assert response.content_type.startswith("application/json")

    data = response.get_json()

    assert data == {"status": "healthy"}
