FROM python:3.13-slim AS builder

COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/

ENV VIRTUAL_ENV=/opt/venv
RUN python3 -m venv $VIRTUAL_ENV
ENV PATH="$VIRTUAL_ENV/bin:$PATH"

COPY requirements.txt requirements.txt
RUN uv pip install --no-cache-dir -r requirements.txt


FROM builder AS tester

COPY . .

RUN sed -i 's/\r$//' test.sh && \
    chmod +x test.sh
RUN ./test.sh

FROM python:3.13-slim AS runtime

RUN useradd --create-home appuser
WORKDIR /home/appuser

COPY --from=builder --chown=appuser:appuser /opt/venv /opt/venv
COPY . .

RUN sed -i 's/\r$//' run.sh && \
    chmod +x run.sh

USER appuser

ENV VIRTUAL_ENV=/opt/venv
ENV PATH="$VIRTUAL_ENV/bin:$PATH"

EXPOSE 8080

CMD ["./run.sh"]
