# server_tkv_compressor.py - HTTP Proxy Daemon for TokenVector Universal AI Context Compressor
from http.server import HTTPServer, BaseHTTPRequestHandler
import json
import sys
import os

# Load TokenVector Compressor Engine
with open('universal_context_compressor.tkv', 'r', encoding='utf-8') as f:
    tkv_code = f.read()

tkv_scope = {}
exec(tkv_code, tkv_scope)

PORT = 8888

class TKVCompressorHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == '/health' or self.path == '/livez':
            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps({
                "status": "ok",
                "engine": "TokenVector Universal AI Context Compressor",
                "version": "1.0.0-native",
                "savings_average": "51-87%"
            }).encode('utf-8'))
        else:
            self.send_response(200)
            self.send_header('Content-Type', 'text/html; charset=utf-8')
            self.end_headers()
            self.wfile.write(b"<h1>TokenVector Universal AI Context Compressor Engine Active (Port 8888)</h1>")

    def do_POST(self):
        content_length = int(self.headers.get('Content-Length', 0))
        post_data = self.rfile.read(content_length).decode('utf-8')
        
        client_tag = self.headers.get('X-AI-Client', 'Universal-AI')
        
        # Compress payload via TokenVector Engine
        compressed_output = tkv_scope['format_universal_ai_request'](client_tag, post_data)
        
        self.send_response(200)
        self.send_header('Content-Type', 'text/plain; charset=utf-8')
        self.send_header('X-Engine', 'TokenVector-Native')
        self.end_headers()
        self.wfile.write(compressed_output.encode('utf-8'))

def run_server():
    server = HTTPServer(('127.0.0.1', PORT), TKVCompressorHandler)
    print(f"=========================================================================")
    print(f"   TOKENVECTOR UNIVERSAL AI CONTEXT COMPRESSOR ENGINE ACTIVE AT PORT {PORT}")
    print(f"=========================================================================")
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\nStopping TokenVector Compressor Engine Server...")
        server.server_close()

if __name__ == '__main__':
    run_server()
