import os
import psycopg2
from http.server import HTTPServer, BaseHTTPRequestHandler

def get_db():
    return psycopg2.connect(
        host=os.environ["DB_HOST"],
        dbname=os.environ["DB_NAME"],
        user=os.environ["DB_USER"],
        password=os.environ["DB_PASSWORD"]
    )

class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        try:
            conn = get_db()
            cur = conn.cursor()
            cur.execute("SELECT version();")
            version = cur.fetchone()[0]
            conn.close()
            response = f"Hello from Docker! DB: {version}".encode()
        except Exception as e:
            response = f"DB Error: {e}".encode()
        self.send_response(200)
        self.end_headers()
        self.wfile.write(response)

if __name__ == "__main__":
    HTTPServer(("", 8080), Handler).serve_forever()
