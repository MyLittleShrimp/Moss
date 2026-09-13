from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
import subprocess, threading, json
root = Path(__file__).resolve().parents[1]
class Handler(BaseHTTPRequestHandler):
    def log_message(self, *_): pass
    def do_GET(self):
        if self.path == '/v1/models':
            assert self.headers.get('Authorization') == 'Bearer fixture-only'
            code, body = 200, {'data':[{'id':'local-b'},{'id':'local-a'},{'id':'local-b'}]}
        elif self.path == '/redirect/models': code, body = 302, {}
        else: code, body = 404, {}
        raw = json.dumps(body).encode()
        self.send_response(code)
        if code == 302: self.send_header('Location','/must-not-follow')
        assert self.path != '/must-not-follow'
        self.send_header('Content-Length',str(len(raw)))
        self.end_headers()
        self.wfile.write(raw)
server = ThreadingHTTPServer(('127.0.0.1',0),Handler)
threading.Thread(target=server.serve_forever,daemon=True).start()
try:
    result = subprocess.run([str(root/'.tools/godot/Godot_v4.6.2-stable_win64_console.exe'),'--headless','--path',str(root),'--script','tests/test_model_list.gd','--',f'http://127.0.0.1:{server.server_port}'],cwd=root,timeout=30)
    assert result.returncode == 0
    result = subprocess.run([str(root/'.tools/godot/Godot_v4.6.2-stable_win64_console.exe'),'--path',str(root),'tests/packing_scene.tscn','--quit-after','1800','--','--qa',f'http://127.0.0.1:{server.server_port}'],cwd=root,timeout=35)
    raise SystemExit(result.returncode)
finally: server.shutdown()
