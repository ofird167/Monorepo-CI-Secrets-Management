# Stage 1: Build dependencies
FROM python:3.11-alpine AS builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir --user -r requirements.txt

# Stage 2: Runtime Environment
FROM python:3.11-alpine
WORKDIR /app
COPY --from=builder /root/.local /root/.local
COPY main.py ./

ENV PATH=/root/.local/bin:$PATH
ENV HOST=0.0.0.0
ENV PORT=8000

EXPOSE 8000
CMD ["python", "main.py"]
