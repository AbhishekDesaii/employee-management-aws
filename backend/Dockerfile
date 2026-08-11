# Backend Dockerfile
#
# Single-stage build: Python 3.12 image with the Flask app + gunicorn.
# Runs as a non-root user and listens on port 5000.
#
# Build:
#   docker build -t employee-backend .  (from the backend/ directory)

FROM python:3.12-slim

WORKDIR /app

# Install the Python dependencies listed in requirements.txt
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy the rest of the backend source code
COPY . .

# Expose the port gunicorn listens on
EXPOSE 5000

# Start gunicorn with 2 workers
CMD ["gunicorn", "app:create_app()", "-c", "gunicorn.conf.py"]
