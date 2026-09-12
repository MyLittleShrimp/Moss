"""Start the configured local proxy on demand, then the existing Godot game."""
import json
import subprocess
import time
import sys
import urllib.request
from proxy import ROOT, LOCAL

def ready():
    try:
        token = (LOCAL / 'proxy-token').read_text().strip()
        req = urllib.request.Request('http://127.0.0.1:8765/health', headers={'Authorization': 'Bearer ' + token})
        with urllib.request.urlopen(req, timeout=1) as response:
            return json.load(response).get('service') == 'moss-proxy'
    except Exception:
        return False

def ensure_proxy():
    path = LOCAL / 'ai.json'
    if not path.exists() or not json.loads(path.read_text(encoding='utf-8-sig')).get('enabled'):
        return False
    if ready():
        return True
    subprocess.Popen([sys.executable, str(ROOT / 'server/proxy.py')], cwd=ROOT,
                     creationflags=subprocess.CREATE_NO_WINDOW, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    for _ in range(30):
        if ready():
            return True
        time.sleep(0.1)
    return False

if __name__ == '__main__':
    configured = ensure_proxy()
    if '--proxy-only' in sys.argv:
        print('PROXY_READY' if configured else 'PROXY_UNAVAILABLE')
        raise SystemExit(0 if configured else 1)
    subprocess.Popen([str(ROOT / '.tools/godot/Godot_v4.6.2-stable_win64.exe'), '--path', str(ROOT)], cwd=ROOT)
