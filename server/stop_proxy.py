import urllib.request
from proxy import LOCAL

try:
    token = (LOCAL / 'proxy-token').read_text().strip()
    req = urllib.request.Request('http://127.0.0.1:8765/shutdown', data=b'', headers={'Authorization': 'Bearer ' + token}, method='POST')
    with urllib.request.urlopen(req, timeout=3) as response:
        print('Local proxy stopped.' if response.status == 200 else 'Could not stop local proxy.')
except Exception:
    print('Local proxy is unavailable or needs restarting to support shutdown.')
