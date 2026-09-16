FROM python:3.12-slim

WORKDIR /app

RUN pip install psycopg2-binary

COPY app.py .

EXPOSE 8080

CMD ["python", "app.py"]
