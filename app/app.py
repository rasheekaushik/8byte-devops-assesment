from flask import Flask, jsonify, request
from prometheus_client import Counter, Histogram, generate_latest, CONTENT_TYPE_LATEST

app = Flask(__name__)

REQUEST_COUNT = Counter(
    "app_requests_total",
    "Total number of application requests",
    ["method", "endpoint", "http_status"],
)

REQUEST_LATENCY = Histogram(
    "app_request_latency_seconds",
    "Application request latency in seconds",
    ["method", "endpoint"],
)


@app.before_request
def start_timer():
    request.start_time = __import__("time").time()


@app.after_request
def record_metrics(response):
    latency = __import__("time").time() - request.start_time

    REQUEST_COUNT.labels(
        request.method,
        request.path,
        response.status_code,
    ).inc()

    REQUEST_LATENCY.labels(
        request.method,
        request.path,
    ).observe(latency)

    return response


@app.get("/")
def home():
    return jsonify({
        "service": "8byte-devops-app",
        "status": "running"
    })


@app.get("/health")
def health():
    return jsonify({
        "status": "healthy"
    })


@app.get("/metrics")
def metrics():
    return generate_latest(), 200, {"Content-Type": CONTENT_TYPE_LATEST}


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080)
