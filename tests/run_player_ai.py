"""Isolated HTTP protocol fixture; never invokes a real provider or reads player keys."""
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
import json
import subprocess
import threading
import time

root = Path(__file__).resolve().parents[1]
class Handler(BaseHTTPRequestHandler):
    def log_message(self, *_):
        pass
    def do_POST(self):
        data = json.loads(self.rfile.read(int(self.headers['Content-Length'])))
        assert self.path == '/v1/chat/completions'
        assert 'Authorization' not in self.headers
        assert data['model'] == 'fixture' and data['stream'] is False
        prompt = json.loads(data['messages'][1]['content'])['text']
        if prompt == 'timeout':
            time.sleep(0.6)
        status = 401 if prompt == 'unauthorized' else 302 if prompt == 'redirect' else 200
        content = 'invalid' if prompt == 'malformed' else json.dumps({'utterance': '模型接口测试。', 'emotion': 'calm'}, ensure_ascii=False)
        body = json.dumps({'choices': [{'finish_reason': 'stop', 'message': {'content': content}}]}).encode()
        self.send_response(status)
        if status == 302:
            self.send_header('Location', '/v1/chat/completions')
        self.send_header('Content-Length', str(len(body)))
        self.end_headers()
        try:
            self.wfile.write(body)
        except (BrokenPipeError, ConnectionResetError, ConnectionAbortedError):
            pass

if __name__ == '__main__':
    server = ThreadingHTTPServer(('127.0.0.1', 0), Handler)
    thread = threading.Thread(target=server.serve_forever, daemon=True)
    thread.start()
    try:
        result = subprocess.run([str(root / '.tools/godot/Godot_v4.6.2-stable_win64_console.exe'), '--headless', '--path', str(root), '--script', 'res://tests/test_player_ai.gd', '--log-file', 'artifacts/g10-http.log', '--', f'http://127.0.0.1:{server.server_port}/v1/chat/completions'], timeout=20, cwd=root)
        raise SystemExit(result.returncode)
    finally:
        server.shutdown()
