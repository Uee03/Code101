import json
import os
from http.server import BaseHTTPRequestHandler, HTTPServer
import psycopg


def connect():
    return psycopg.connect(
        host=os.environ["DB_HOST"],
        dbname=os.environ["POSTGRES_DB"],
        user=os.environ["POSTGRES_USER"],
        password=os.environ["POSTGRES_PASSWORD"],
        connect_timeout=3,
    )


class Page(BaseHTTPRequestHandler):
    def do_GET(self):
        try:
            with connect() as connection:
                if self.path == "/health":
                    connection.execute("SELECT 1")
                    result = {"status": "ready"}
                elif self.path == "/":
                    connection.execute("CREATE TABLE IF NOT EXISTS counter "
                                       "(id INTEGER PRIMARY KEY, visits INTEGER NOT NULL)")
                    visits = connection.execute(
                        "INSERT INTO counter VALUES (1, 1) "
                        "ON CONFLICT (id) DO UPDATE SET visits = counter.visits + 1 "
                        "RETURNING visits"
                    ).fetchone()[0]
                    result = {"message": os.environ["GREETING"], "visits": visits}
                else:
                    self.send_response(404)
                    self.end_headers()
                    return
            self.send_response(200)
        except psycopg.OperationalError:
            result = {"error": "Database is not ready; try again"}
            self.send_response(503)
        self.send_header("Content-Type", "application/json")
        self.end_headers()
        self.wfile.write((json.dumps(result) + "\n").encode())


print("Code101 API listening on 8000", flush=True)
HTTPServer(("0.0.0.0", 8000), Page).serve_forever()
