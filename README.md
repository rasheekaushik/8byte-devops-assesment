# 8Byte DevOps Assessment

End-to-end DevOps implementation covering **Terraform, AWS, Docker, PostgreSQL, GitHub Actions, security scanning, monitoring, and centralized logging**.

> **Note:** AWS deployment is not performed, as it is not required for this assessment. Terraform is validated using `fmt`, `validate`, and `plan`.

---

## 1. Architecture

```text
                         Internet
                            |
                       +----v----+
                       |   ALB   |
                       +----+----+
                            |
                     Private Subnet
                            |
                     +------v------+
                     | Application |
                     | EC2/Docker  |
                     +------+------+
                            |
                     Private Subnet
                            |
                     +------v------+
                     | PostgreSQL  |
                     |    RDS      |
                     +-------------+

              Terraform → AWS Infrastructure
                         |
                    GitHub Actions
                         |
        +----------------+----------------+
        |                |                |
      Tests          Security Scan     Build/Push
        |                |                |
        +----------------+----------------+
                         |
                    Staging Deploy
                         |
                  Manual Production
                      Approval


Local Observability:

 Flask App ──→ Prometheus ──→ Grafana
     |              ↑
     |          Node Exporter
     |          PostgreSQL Exporter
     |
     └──→ Promtail ──→ Loki ──→ Grafana
```

---

## 2. Technology Stack

| Area         | Technology          |
| ------------ | ------------------- |
| IaC          | Terraform           |
| Cloud        | AWS                 |
| Application  | Python / Flask      |
| Containers   | Docker              |
| Database     | PostgreSQL          |
| CI/CD        | GitHub Actions      |
| Metrics      | Prometheus          |
| Dashboards   | Grafana             |
| Logging      | Loki + Promtail     |
| Host Metrics | Node Exporter       |
| DB Metrics   | PostgreSQL Exporter |
| Testing      | Pytest              |
| Security     | Trivy + pip-audit   |

---

# 3. Part 1 — Infrastructure Provisioning

Terraform provisions:

* VPC `10.0.0.0/16`
* 2 public subnets
* 2 private subnets
* Internet Gateway
* Public/private route tables
* NAT Gateway
* Application EC2 instance
* Application Load Balancer
* Target Group
* PostgreSQL RDS
* Security Groups
* Variables and outputs

### Security design

* ALB is internet-facing.
* Application runs in a private subnet.
* PostgreSQL runs in a private subnet.
* Security groups restrict traffic between components.
* Database is not directly exposed to the internet.

### Validation

```bash
cd terraform

terraform fmt -check
terraform validate
terraform plan
```

Validated plan:

```text
Plan: 27 to add, 0 to change, 0 to destroy
```

**`terraform apply` was intentionally not performed.**

---

# 4. Part 2 — CI/CD

GitHub Actions runs on:

* Pull requests to `main`
* Pushes to `main`

Pipeline:

```text
PR / Push
   |
   +--> Unit + Integration Tests
   |
   +--> pip-audit
   |
   +--> Docker Build
   |
   +--> Trivy Container Scan
   |
   +--> Push Image to GHCR
   |
   +--> Staging Deployment
   |       |
   |       +--> /health validation
   |
   +--> Production
           |
       Manual Approval
```

### Testing

```bash
PYTHONPATH=$(pwd)/app pytest app/tests/
```

Result:

```text
3 passed
```

### Dependency scan

```bash
pip-audit -r app/requirements.txt
```

Result:

```text
No known vulnerabilities found
```

### Container security

Docker images are scanned using **Trivy** before publishing.

### Image registry

Successful builds are pushed to **GitHub Container Registry** using:

* Commit SHA tag
* `latest` tag

### Production protection

Production deployment uses a GitHub Environment with a **required manual reviewer**.

---

# 5. Part 3 — Monitoring & Logging

Monitoring runs locally through Docker Compose because AWS deployment is not required.

### Components

```text
Application
    |
    +--> Prometheus
    |      |
    |      +--> Node Exporter
    |      +--> PostgreSQL Exporter
    |
    +--> Promtail --> Loki
                         |
                         v
                      Grafana
```

### Application metrics

The Flask application exposes:

```text
/metrics
```

Metrics include:

* Request rate
* HTTP status codes
* Request latency
* P95 latency

### Infrastructure metrics

Node Exporter provides:

* CPU
* Memory
* Disk

### PostgreSQL metrics

PostgreSQL Exporter provides:

* Database availability
* Active connections
* Database size
* Transaction rate
* Cache hit ratio
* Rollback rate

### Logging

Promtail collects:

* Docker application logs
* Gunicorn access logs
* System logs

Loki provides centralized log storage and Grafana provides log exploration.

---

# 6. Grafana Dashboard

Dashboard:

**8Byte Application Monitoring**

Includes:

* Application request rate
* Error rate
* P95 latency
* HTTP status distribution
* Average latency
* CPU usage
* Memory usage
* Disk usage
* PostgreSQL status
* Active DB connections
* DB size
* Transaction rate
* Cache hit ratio
* Rollback rate

Dashboard provisioning is stored in Git:

```text
monitoring/grafana/
├── dashboards/
│   └── application-monitoring.json
└── provisioning/
    ├── dashboards/
    │   └── dashboards.yml
    └── datasources/
        └── datasources.yml
```

---

# 7. Run Monitoring Locally

From the repository root:

```bash
docker compose -f monitoring/docker-compose.yml up -d
```

Check services:

```bash
docker compose -f monitoring/docker-compose.yml ps
```

Application:

```text
http://localhost:8080
```

Health:

```bash
curl http://localhost:8080/health
```

Metrics:

```bash
curl http://localhost:8080/metrics
```

Grafana:

```text
http://localhost:3000
```

Prometheus:

```text
http://localhost:9090
```

---

# 8. Security & Secrets

Sensitive values are not committed to Git.

Examples excluded through `.gitignore`:

```text
terraform.tfvars
.env
*.pem
*.tfstate
```

Terraform sensitive values can be supplied through environment variables:

```bash
export TF_VAR_db_password="<secure-password>"
```

GitHub Actions uses repository/environment secrets where required.

Production implementation should additionally use AWS Secrets Manager or SSM Parameter Store for application secrets.

---

# 9. Terraform State Management

For this assessment, Terraform state remains local because actual AWS deployment is not required.

For production:

* Store state in encrypted S3
* Enable S3 versioning
* Restrict IAM access
* Enable state locking/concurrency protection
* Maintain separate state per environment

---

# 10. Backup & Reliability

RDS automated backups are configured with a retention period.

Production backup strategy should include:

* Automated backups
* Point-in-time recovery
* Defined retention
* Periodic restore testing
* Backup monitoring
* Disaster recovery documentation

---

# 11. Cost Optimization

Key decisions:

* Single NAT Gateway for the assessment to reduce cost.
* Local Docker Compose used for observability validation.
* Resources are intentionally right-sized.
* Managed RDS reduces database operational overhead.

For a production high-availability environment, multiple NAT Gateways may be justified despite the additional cost.

---

# 12. Approach

The project was implemented incrementally:

1. Designed AWS infrastructure with Terraform.
2. Built a containerized Flask application.
3. Added unit and integration tests.
4. Implemented GitHub Actions CI/CD.
5. Added dependency and container security scanning.
6. Added staging validation and production approval.
7. Instrumented the application with Prometheus metrics.
8. Added infrastructure and PostgreSQL monitoring.
9. Implemented centralized logging with Loki and Promtail.
10. Created and provisioned Grafana dashboards.
11. Validated the complete solution locally.

The main design priorities were **automation, security, observability, reproducibility, and cost awareness**.

---

# 13. Challenges & Resolutions

### CI dependency vulnerabilities

`pip-audit` initially identified vulnerable dependency versions.

**Resolution:** Updated Flask, pytest, and requests to patched versions.

### Trivy action failure

The initial Trivy GitHub Action version was unavailable.

**Resolution:** Updated the workflow to a valid Trivy action release.

### Prometheus configuration

A PostgreSQL exporter target had an indentation/configuration issue.

**Resolution:** Corrected the Prometheus configuration and recreated the Prometheus container.

### Grafana dashboard reproducibility

The dashboard initially existed only in the running Grafana instance.

**Resolution:** Exported the dashboard JSON and added Grafana file provisioning to the repository.

### Application log collection

Gunicorn access logs were not initially exposed through container stdout.

**Resolution:** Configured Gunicorn with:

```text
--access-logfile -
```

This allows Promtail to collect application access logs.

---

# 14. Repository Structure

```text
8byte-devops-assesment/
│
├── app/
│   ├── app.py
│   ├── Dockerfile
│   ├── requirements.txt
│   └── tests/
│
├── monitoring/
│   ├── docker-compose.yml
│   ├── prometheus/
│   ├── grafana/
│   └── loki/
│
├── terraform/
│   ├── vpc.tf
│   ├── ec2.tf
│   ├── alb.tf
│   ├── rds.tf
│   ├── security-groups.tf
│   ├── variables.tf
│   └── outputs.tf
│
├── .github/
│   └── workflows/
│       └── ci.yml
│
├── .gitignore
└── README.md
```

---

## Final Validation

The project has been validated through:

* Terraform formatting
* Terraform validation
* Terraform plan
* Python unit/integration tests
* Docker image build
* Dependency vulnerability scan
* Container vulnerability scan
* CI/CD pipeline
* Staging health check
* Production approval workflow
* Prometheus targets
* PostgreSQL metrics
* Grafana dashboards
* Loki application logs
* Loki system logs

**No AWS resources were created with `terraform apply`.**
