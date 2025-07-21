FROM python:3.13-slim AS builder

COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/
COPY requirements.txt requirements.txt
RUN uv pip install --no-cache-dir --system -r requirements.txt && \
    rm requirements.txt


FROM builder AS tester

COPY . .
RUN python -m unittest helloapp.test -v

FROM python:3.13-slim AS runtime

RUN useradd --create-home appuser
WORKDIR /home/appuser

COPY --from=builder /usr/local/lib/python3.13/site-packages /usr/local/lib/python3.13/site-packages
COPY helloapp helloapp


USER appuser
EXPOSE 8080

CMD ["python", "-m", "gunicorn", "--bind", "0.0.0.0:8080", "-w", "2", "helloapp.app:app"]
