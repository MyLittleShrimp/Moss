from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
import subprocess, threading, json, time
root = Path(__file__).resolve().parents[1]
class Handler(BaseHTTPRequestHandler):
    def log_message(self, *_): pass
    def do_POST(self):
        payload = json.loads(self.rfile.read(int(self.headers['Content-Length'])))
        assert payload['stream'] is False
        if self.path == '/failure':
            self.send_response(503); self.send_header('Content-Length','0'); self.end_headers(); return
        if self.path == '/slow': time.sleep(.4)
        message = {'content': json.dumps({'utterance':'窗外的风很轻，我把一片云写进信里。','emotion':'calm'}, ensure_ascii=False)}
        if self.path == '/api/chat':
            assert payload['format'] == 'json'
            body = {'done':True,'message':message}
        else: body = {'choices':[{'finish_reason':'stop','message':message}]}
        raw = json.dumps(body).encode()
        self.send_response(200); self.send_header('Content-Length',str(len(raw))); self.end_headers(); self.wfile.write(raw)
server = ThreadingHTTPServer(('127.0.0.1',0), Handler)
threading.Thread(target=server.serve_forever,daemon=True).start()
try:
    result = subprocess.run([str(root/'.tools/godot/Godot_v4.6.2-stable_win64_console.exe'),'--headless','--path',str(root),'--script','tests/test_narrative.gd','--',f'http://127.0.0.1:{server.server_port}'],cwd=root,timeout=40)
    raise SystemExit(result.returncode)
finally: server.shutdown()
