
FROM python:3.11-slim

WORKDIR /app

# Update vulnerable Debian packages
RUN apt-get update \
    && apt-get upgrade -y --no-install-recommends \
    && rm -rf /var/lib/apt/lists/*

# Copy Python dependencies
COPY requirements.txt .

# Upgrade Python packaging tools
RUN python -m pip install --no-cache-dir --upgrade pip setuptools wheel

# Install application dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy application source code
COPY . .

ENV PORT=8080

EXPOSE 8080

CMD ["python", "app.py"]
