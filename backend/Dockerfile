# ── Stage 1: Build dependencies ─────────────────────────────────────────────
FROM python:3.11-slim AS builder

WORKDIR /app

# Install wget for downloading the model
RUN apt-get update && apt-get install -y wget

# Download the Qwen 2.5 1.5B Instruct model (Q4_K_M ~1GB) directly into the image
# Moving this ABOVE dependency installation ensures it stays cached even when dependencies change!
RUN mkdir -p /app/models && \
    wget -q --show-progress "https://huggingface.co/Qwen/Qwen2.5-1.5B-Instruct-GGUF/resolve/main/qwen2.5-1.5b-instruct-q4_k_m.gguf" -O /app/models/qwen.gguf

# Install poetry
RUN pip install --no-cache-dir poetry==1.8.3

COPY pyproject.toml poetry.lock* ./
RUN poetry config virtualenvs.in-project true \
 && poetry install --no-root --without dev --no-interaction --no-ansi

# Install llama-cpp-python via pre-built CPU wheel for speed and reliability
RUN /app/.venv/bin/pip install llama-cpp-python \
  --extra-index-url https://abetlen.github.io/llama-cpp-python/whl/cpu

# ── Stage 2: Runtime ─────────────────────────────────────────────────────────
FROM python:3.11-slim

LABEL maintainer="Bulao Team"
LABEL version="2.0.0-local-llm"

WORKDIR /app

# Copy virtualenv and the downloaded model from builder
COPY --from=builder /app/.venv ./.venv
COPY --from=builder /app/models ./models

# Copy application code and all data
COPY app ./app

# Make venv Python the default
ENV PATH="/app/.venv/bin:$PATH"
ENV PORT=8080
ENV PYTHONUNBUFFERED=1
ENV PYTHONDONTWRITEBYTECODE=1

EXPOSE 8080

# Healthcheck for Cloud / App Runner
HEALTHCHECK --interval=30s --timeout=10s --start-period=120s --retries=3 \
  CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8080/health')" || exit 1

# Note: workers set to 1 because the model resides in RAM. Multiple workers would duplicate the 1GB RAM footprint.
CMD ["python", "-m", "uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8080", "--workers", "1", "--log-level", "info"]
