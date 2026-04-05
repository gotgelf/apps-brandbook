# ┌─────────────────────────────────────────────────────────────────────┐
# │ Multi-stage Dockerfile Template                                     │
# │                                                                     │
# │ Stages: base → lint → test → production                            │
# │ CI workflows reference these targets by name.                       │
# │ Adapt the base image and commands to your project's language.       │
# └─────────────────────────────────────────────────────────────────────┘

# ── Base stage: dependencies ──────────────────────────────────────────
FROM python:3.12-slim AS base
# FROM eclipse-temurin:21-jre AS base       # Java alternative
# FROM golang:1.22-alpine AS base           # Go alternative

WORKDIR /app

# Copy dependency manifests first (cache layer)
COPY requirements.txt .
# COPY pom.xml .                            # Java
# COPY go.mod go.sum ./                     # Go

RUN pip install --no-cache-dir -r requirements.txt
# RUN mvn dependency:resolve                # Java
# RUN go mod download                       # Go

COPY . .

# ── Lint stage ────────────────────────────────────────────────────────
FROM base AS lint

RUN pip install --no-cache-dir ruff mypy
# Adjust commands per language:
CMD ["sh", "-c", "ruff check . && ruff format --check . && mypy ."]
# CMD ["sh", "-c", "mvn checkstyle:check"]  # Java
# CMD ["sh", "-c", "golangci-lint run"]      # Go

# ── Test stage ────────────────────────────────────────────────────────
FROM base AS test

RUN pip install --no-cache-dir pytest pytest-cov
CMD ["pytest", "--cov=.", "--cov-report=term-missing", "-v"]
# CMD ["mvn", "test"]                       # Java
# CMD ["go", "test", "-v", "-race", "./..."] # Go

# ── Production stage ──────────────────────────────────────────────────
FROM base AS production

# Non-root user for security
RUN groupadd -r app && useradd -r -g app app
USER app

EXPOSE 8000

# Adjust entrypoint per project:
CMD ["python", "-m", "uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
# CMD ["java", "-jar", "app.jar"]           # Java
# CMD ["./app"]                              # Go
