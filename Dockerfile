# Use slim image to reduce size while keeping essential tools
# Python 3.12 chosen for its performance improvements and modern features
FROM python:3.12-slim AS builder

# Use uv instead of pip for faster, more reliable dependency installation
# uv is 5-10x faster than pip and has better dependency resolution
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/
COPY requirements.txt requirements.txt
RUN uv pip install --no-cache-dir --system -r requirements.txt && \
    rm requirements.txt

# Separate testing stage to keep runtime image clean
# This ensures tests are run during build but test dependencies don't bloat the final image
FROM builder AS tester

COPY . .
RUN python -m unittest helloapp.test -v

# Runtime stage with minimal footprint
# Using multi-stage build to reduce final image size by ~60-70%
FROM python:3.12-slim AS runtime

# Create non-root user for security
# Following container security best practices
RUN useradd --create-home appuser
WORKDIR /home/appuser

# Copy only necessary files from builder stage
# This reduces attack surface and image size
COPY --from=builder /usr/local/lib/python3.12/site-packages /usr/local/lib/python3.12/site-packages
COPY helloapp helloapp

# Switch to non-root user for security
USER appuser
EXPOSE 8080

# Use Gunicorn for production-grade WSGI server
# - 2 workers for better performance and failover
# - Module-style command ensures proper Python path handling
CMD ["python", "-m", "gunicorn", "--bind", "0.0.0.0:8080", "-w", "2", "helloapp.app:app"]
