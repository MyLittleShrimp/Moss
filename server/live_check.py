"""Explicit live smoke test. Only synthetic gameplay input; reports no credentials."""
import json
import time
import urllib.error
from pathlib import Path
from proxy import LOCAL, ROOT, Budget, generate

def main():
    config = json.loads((LOCAL / 'ai.json').read_text(encoding='utf-8-sig'))
    facts = {'name': '苔苔', 'away': False, 'destination': '溪谷', 'rain_preference': 'like', 'last_event': '小桥边的邮差'}
    started = time.monotonic()
    report = {'provider': 'DeepSeek', 'model': config['model'], 'synthetic_input': True}
    try:
        if not Budget(LOCAL / 'usage.json').reserve():
            raise ValueError('budget_exceeded')
        reply = generate({'text': '今天有点累，想听你说一句轻松的话。', 'facts': facts}, config)
        report.update(ok=True, reply=reply)
    except urllib.error.HTTPError as error:
        report.update(ok=False, error='upstream_http', status=error.code)
    except Exception as error:
        report.update(ok=False, error=type(error).__name__)
        if str(error) in ('not_configured', 'invalid_endpoint', 'invalid_protocol', 'incomplete', 'invalid_output', 'invalid_emotion', 'output_too_large', 'redirect_rejected', 'budget_exceeded'):
            report['reason'] = str(error)
    report['elapsed_seconds'] = round(time.monotonic() - started, 2)
    (ROOT / 'artifacts/g4-live-check.json').write_text(json.dumps(report, ensure_ascii=False, indent=2), encoding='utf-8')
    print(json.dumps(report, ensure_ascii=False))
    return 0 if report['ok'] else 1

if __name__ == '__main__':
    raise SystemExit(main())
