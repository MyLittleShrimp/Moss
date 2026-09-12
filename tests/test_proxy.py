import importlib.util
import json
from pathlib import Path
import subprocess
import tempfile
import threading
import unittest
from unittest.mock import patch, MagicMock
import urllib.request
import urllib.error

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location('proxy', ROOT / 'server/proxy.py')
proxy = importlib.util.module_from_spec(spec)
spec.loader.exec_module(proxy)
FACTS = {'name': '苔苔', 'away': False, 'destination': '溪谷', 'rain_preference': 'unknown', 'last_event': '还未旅行'}
TOKEN = 'test-only-token-' + 'x' * 32

def response(text):
    return {'status': 'completed', 'output': [{'type': 'message', 'content': [{'type': 'output_text', 'text': text}]}]}

class ProxyTests(unittest.TestCase):
    def test_daily_book_context_and_bounds(self):
        facts = {**FACTS, 'preferences': ['喜欢茉莉花'], 'observations': ['在小屋收获过稻米 2次'], 'weather': 'rainy', 'book_day': '2026-09-11'}
        value = {'text': '今日故事', 'facts': facts, 'purpose': 'daily_book'}
        self.assertEqual(proxy.validate_input(value), value)
        self.assertEqual(proxy.validate_input({'text': 'hi', 'facts': FACTS})['facts'], FACTS)
        for bad in [{**value, 'purpose': 'grant'}, {**value, 'facts': {**facts, 'preferences': ['x'] * 33}}, {**value, 'facts': {**facts, 'observations': ['x' * 81]}}]:
            with self.assertRaises(ValueError): proxy.validate_input(bad)
        opener = MagicMock()
        upstream = {'choices': [{'finish_reason': 'stop', 'message': {'content': json.dumps({'utterance': '一。\n\n二。\n\n三。', 'emotion': 'calm'})}}]}
        opener.open.return_value.__enter__.return_value.read.return_value = json.dumps(upstream).encode()
        with patch.dict('os.environ', {'MOSS_LLM_API_KEY': 'synthetic-test-key'}), patch.object(proxy.urllib.request, 'build_opener', return_value=opener):
            proxy.generate(value, {'enabled': True, 'model': 'fixture', 'endpoint': 'https://fixture.invalid/v1/test'})
        payload = json.loads(opener.open.call_args.args[0].data)
        self.assertIn('虚构的每日小书', payload['messages'][0]['content'])

    def test_provider_adapters_without_network(self):
        for protocol in ('chat_completions', 'responses'):
            valid = json.dumps({'utterance': '你好。', 'emotion': 'calm'})
            upstream = {'choices': [{'finish_reason': 'stop', 'message': {'content': valid}}]} if protocol == 'chat_completions' else response(valid)
            opener = MagicMock()
            opener.open.return_value.__enter__.return_value.read.return_value = json.dumps(upstream).encode()
            with patch.dict('os.environ', {'MOSS_LLM_API_KEY': 'synthetic-test-key'}), patch.object(proxy.urllib.request, 'build_opener', return_value=opener):
                result = proxy.generate({'text': 'hello', 'facts': FACTS}, {'enabled': True, 'model': 'fixture', 'endpoint': 'https://fixture.invalid/v1/test', 'protocol': protocol})
                self.assertEqual(result['utterance'], '你好。')
                payload = json.loads(opener.open.call_args.args[0].data)
                self.assertIn('messages' if protocol == 'chat_completions' else 'input', payload)

    def test_input_rejects_state_mutation(self):
        with self.assertRaises(ValueError):
            proxy.validate_input({'text': 'hi', 'facts': FACTS, 'coins': 99})

    def test_output_rejects_actions(self):
        with self.assertRaises(ValueError):
            proxy.parse_output(response(json.dumps({'utterance': 'hi', 'emotion': 'calm', 'action': 'grant'})))

    def test_output_rejects_oversize(self):
        with self.assertRaises(ValueError):
            proxy.parse_output(response(json.dumps({'utterance': 'x' * 241, 'emotion': 'calm'})))

    def test_incomplete_and_refusal(self):
        for value in [{'status': 'incomplete'}, {'status': 'completed', 'output': []}]:
            with self.assertRaises(ValueError):
                proxy.parse_output(value)

    def test_budget_survives_restart(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / 'usage.json'
            self.assertTrue(proxy.Budget(path, limit=1).reserve())
            self.assertFalse(proxy.Budget(path, limit=1).reserve())

    def test_minute_limit(self):
        with tempfile.TemporaryDirectory() as directory:
            budget = proxy.Budget(Path(directory) / 'usage.json')
            self.assertTrue(all(budget.reserve() for _ in range(6)))
            self.assertFalse(budget.reserve())

    def test_http_auth_origin_error_and_godot(self):
        def fake_provider(value, _config):
            if value['text'] == '请模拟故障':
                raise RuntimeError('private upstream error must not leak')
            return {'source': 'llm', 'utterance': '联调测试纸条。', 'emotion': 'calm'}
        with tempfile.TemporaryDirectory() as directory:
            server = proxy.ThreadingHTTPServer(('127.0.0.1', 0), proxy.make_handler(
                TOKEN, {'enabled': True, 'model': 'test-only'}, proxy.Budget(Path(directory) / 'usage.json'), fake_provider))
            thread = threading.Thread(target=server.serve_forever, daemon=True)
            thread.start()
            url = f'http://127.0.0.1:{server.server_port}/dialogue'
            def call(token=TOKEN, extra=None):
                headers = {'Content-Type': 'application/json', 'Authorization': 'Bearer ' + token}
                headers.update(extra or {})
                return urllib.request.urlopen(urllib.request.Request(url, data=json.dumps({'text': 'hi', 'facts': FACTS}).encode(), headers=headers), timeout=5)
            try:
                for token, extra, status in [('wrong', None, 401), (TOKEN, {'Origin': 'https://untrusted.example'}, 403)]:
                    with self.assertRaises(urllib.error.HTTPError) as error:
                        call(token, extra)
                    self.assertEqual(error.exception.code, status)
                with call() as result:
                    self.assertEqual(json.load(result)['utterance'], '联调测试纸条。')
                (ROOT / 'artifacts/proxy-test-token').write_text(TOKEN)
                engine = ROOT / '.tools/godot/Godot_v4.6.2-stable_win64_console.exe'
                result = subprocess.run([str(engine), '--headless', '--path', str(ROOT), '--script', 'res://tests/test_dialogue_client.gd',
                    '--log-file', 'artifacts/g3-client-tests.log', '--', url], capture_output=True, text=True, encoding='utf-8', timeout=20)
                self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
                self.assertIn('DIALOGUE_CLIENT_PASS', result.stdout)
                self.assertNotIn('SCRIPT ERROR', result.stdout + result.stderr)
            finally:
                server.shutdown()
                server.server_close()
                thread.join(timeout=2)

if __name__ == '__main__':
    unittest.main(verbosity=2)
