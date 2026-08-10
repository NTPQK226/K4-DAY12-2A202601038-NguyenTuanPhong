# ═══════════════════════════════════════════════════════════════════
# CP2 — Multi-stage production build
# ═══════════════════════════════════════════════════════════════════

# ---- Stage 1: Builder ----
FROM python:3.11-slim AS builder
WORKDIR /build
COPY requirements.txt .
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt

# ---- Stage 2: Runtime ----
FROM python:3.11-slim
WORKDIR /app

# Copy only the installed packages from builder stage
COPY --from=builder /install /usr/local

# Copy source code AFTER pip install (Docker cache optimization)
COPY app/ ./app/
COPY utils/ ./utils/

# Security: run as non-root user
RUN useradd --create-home --uid 10001 appuser
USER appuser

EXPOSE 8000

# Health check using Python (slim image has no curl)
HEALTHCHECK --interval=30s --timeout=5s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://127.0.0.1:8000/healthz').read()" || exit 1

# Read PORT from env (cloud platforms set PORT dynamically)
CMD ["python", "-c", "import os; import uvicorn; port = int(os.environ.get('PORT', 8000)); uvicorn.run('app.main:app', host='0.0.0.0', port=port)"]
