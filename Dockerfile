FROM python:3.12-slim

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

WORKDIR /app

# System deps for building wheels if ever needed
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential libsndfile1 git && rm -rf /var/lib/apt/lists/*

# Copy requirements and install core wheels first (PyTorch CPU + numpy)
COPY requirements.txt ./

RUN pip install --upgrade pip setuptools wheel
RUN pip install --index-url https://download.pytorch.org/whl/cpu "torch==2.2.2" numpy==1.26.4
RUN pip install -r requirements.txt

# Copy app
COPY . .

# Create non-root user
RUN useradd -m appuser && chown -R appuser:appuser /app
USER appuser

EXPOSE 8000

CMD ["gunicorn","-k","uvicorn.workers.UvicornWorker","-w","4","-b","0.0.0.0:8000","src.app:app"]
