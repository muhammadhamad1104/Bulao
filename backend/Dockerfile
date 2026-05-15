# Stage 1: build
FROM python:3.11-slim AS builder
RUN pip install poetry==1.7.1
COPY pyproject.toml poetry.lock* ./
RUN poetry config virtualenvs.in-project true && poetry install --no-root --without dev

# Stage 2: runtime
FROM python:3.11-slim
LABEL version="1.0.0"
WORKDIR /app
COPY --from=builder /.venv ./.venv
COPY app ./app
ENV PATH="/app/.venv/bin:$PATH" PORT=8080
EXPOSE 8080
CMD ["uvicorn","app.main:app","--host","0.0.0.0","--port","8080"]
