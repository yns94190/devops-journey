FROM python:3.12-slim

RUN apt-get update && apt-get upgrade -y && rm -rf /var/lib/apt/lists/*

WORKDIR /app

RUN pip install psycopg2-binary

COPY app.py .

EXPOSE 8080

CMD ["python", "app.py"]
