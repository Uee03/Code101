import json
import os
from http.server import BaseHTTPRequestHandler, HTTPServer

import rag_pipeline
from rag_core import answer_question

TOKEN = os.environ.get("RAG_API_TOKEN", "secret")


class Handler(BaseHTTPRequestHandler):
    def do_POST(self):
        if self.headers.get("Authorization") == "Bearer " + TOKEN:
            body = self.rfile.read(int(self.headers["Content-Length"]))
            question = json.loads(body)["question"]
            print("question:", question)
            try:
                result = answer_question(question, rag_pipeline.retrieve, rag_pipeline.generate)
                reply = {"answer": result["answer"], "sources": [hit.content for hit in result["sources"]]}
                self.send_response(200)
            except Exception as error:
                reply = {"error": repr(error)}
                self.send_response(500)
            self.end_headers()
            self.wfile.write(json.dumps(reply).encode())
        else:
            self.send_response(401)
            self.end_headers()


HTTPServer(("0.0.0.0", 8090), Handler).serve_forever()
