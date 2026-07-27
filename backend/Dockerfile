FROM python:3.12-slim-bookworm AS builder

WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

FROM python:3.12-slim-bookworm

RUN groupadd -r app && useradd -r -g app -d /app -s /bin/false app

WORKDIR /app
COPY --from=builder /usr/local/lib/python3.12/site-packages /usr/local/lib/python3.12/site-packages
COPY --from=builder /usr/local/bin /usr/local/bin
COPY . .

RUN chown -R app:app /app

USER app

EXPOSE 5000

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:5000/api/health')"

CMD ["gunicorn", "app:create_app()", "-c", "gunicorn.conf.py"]