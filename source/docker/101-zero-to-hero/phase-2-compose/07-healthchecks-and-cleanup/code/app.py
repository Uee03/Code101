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
                name = connection.execute("SELECT current_database()").fetchone()[0]
            body = json.dumps({"message": os.environ["GREETING"],
                               "database": name, "host": os.environ["DB_HOST"]})
            self.send_response(200)
        except psycopg.OperationalError:
            body = json.dumps({"error": "Database is not ready; try again"})
            self.send_response(503)
        self.send_header("Content-Type", "application/json")
        self.end_headers()
        self.wfile.write((body + "\n").encode())


print("Code101 web listening on 8000", flush=True)
HTTPServer(("0.0.0.0", 8000), Page).serve_forever()
