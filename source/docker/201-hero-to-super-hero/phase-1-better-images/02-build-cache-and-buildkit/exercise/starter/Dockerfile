FROM python:3.13-slim
WORKDIR /app
# TODO 1: copy only requirements.txt here, then install, and only afterwards copy the rest
COPY . .
RUN pip install --no-cache-dir -r requirements.txt
# TODO 2: turn the pip install line into one that uses a BuildKit cache mount for /root/.cache/pip
CMD ["python", "-u", "app.py"]
