FROM python:3.12-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY backend ./backend
COPY database ./database

# Datos fuera del código: se montan como volúmenes (ver docker-compose.yml)
ENV RUTA_IMAGENES=/data/media \
    DB_PATH=/data/db/perritos.db \
    PYTHONUNBUFFERED=1
WORKDIR /app/backend
EXPOSE 8000
CMD ["python", "-m", "uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
