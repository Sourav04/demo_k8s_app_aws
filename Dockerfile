# Multi-stage Dockerfile for Python Flask Application
# Stage 1: Build stage - install dependencies and prepare application
FROM python:3.11-slim as builder

# Build arguments for version information
ARG APP_VERSION=v1.0.0-dev
ARG BUILD_DATE=unknown
ARG VCS_REF=unknown
ARG GITHUB_RUN_ID=unknown

WORKDIR /app
RUN apt-get update && apt-get install -y \
    gcc \
    curl \
    && rm -rf /var/lib/apt/lists/*

COPY app/requirements.txt .

# Install Python dependencies to a specific directory
RUN pip install --no-cache-dir --target=/app/packages -r requirements.txt

FROM python:3.11-slim as runtime

# Build arguments for version information (need to redeclare in each stage)
ARG APP_VERSION=v1.0.0-dev
ARG BUILD_DATE=unknown
ARG VCS_REF=unknown
ARG GITHUB_RUN_ID=unknown

WORKDIR /app

RUN apt-get update && apt-get install -y \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Install Python packages directly in runtime stage
COPY app/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY app/src/ src/
RUN mkdir -p /app/src/templates

RUN groupadd -r appuser && useradd -r -g appuser appuser \
    && chown -R appuser:appuser /app

USER appuser

ENV APP_VERSION=$APP_VERSION
ENV BUILD_DATE=$BUILD_DATE
ENV VCS_REF=$VCS_REF
ENV GITHUB_RUN_ID=$GITHUB_RUN_ID

EXPOSE 5000

HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:5000/health || exit 1

CMD ["gunicorn", "--bind", "0.0.0.0:5000", "--workers", "2", "--timeout", "120", "src.app:app"] 