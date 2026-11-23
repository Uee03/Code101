FROM python:3.13-slim
LABEL code101.owner="docker-101"
WORKDIR /app
COPY app.py .
RUN python -m compileall -q app.py
CMD ["python", "-u", "app.py"]
