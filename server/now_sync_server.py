#!/usr/bin/env python3
"""
سرور همگام‌سازی «الآن / Now»
فقط به پایتون ۳ نیاز دارد (بدون نصب چیز اضافه).

اجرا:
    python now_sync_server.py --port 8787
یا با فهرست کلیدهای مجاز:
    python now_sync_server.py --port 8787 --keys کلید-یک,کلید-دو

«کلید» همان رمز شماست (حداقل ۸ نویسه). هر کلید فضای جداگانهٔ خودش را دارد.
داده‌ها در پوشهٔ now_data کنار همین فایل ذخیره می‌شوند.
"""
import argparse, hashlib, json, os, re, threading
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

LOCK = threading.Lock()
BLOB_RE = re.compile(r'^[A-Za-z0-9_.\-]{1,120}$')
MAX_BLOB = 15 * 1024 * 1024
MAX_STATE = 20 * 1024 * 1024


def make_handler(data_dir, allowed):
    class H(BaseHTTPRequestHandler):
        server_version = "NowSync/1"

        def log_message(self, fmt, *args):
            pass

        def _send(self, code, body=b'', ctype='application/json'):
            self.send_response(code)
            self.send_header('Content-Type', ctype)
            self.send_header('Content-Length', str(len(body)))
            self.end_headers()
            self.wfile.write(body)

        def _ns(self):
            auth = self.headers.get('Authorization', '')
            if not auth.startswith('Bearer '):
                return None
            key = auth[7:].strip()
            if len(key) < 8:
                return None
            if allowed and key not in allowed:
                return None
            ns = hashlib.sha256(key.encode('utf-8')).hexdigest()[:32]
            d = os.path.join(data_dir, ns)
            os.makedirs(os.path.join(d, 'blobs'), exist_ok=True)
            return d

        def _body(self, limit):
            n = int(self.headers.get('Content-Length') or 0)
            if n > limit:
                return None
            return self.rfile.read(n)

        def do_GET(self):
            if self.path == '/ping':
                return self._send(200, b'ok', 'text/plain')
            d = self._ns()
            if d is None:
                return self._send(401, b'{"error":"auth"}')
            if self.path == '/state':
                with LOCK:
                    p = os.path.join(d, 'state.json')
                    if os.path.exists(p):
                        with open(p, 'rb') as f:
                            return self._send(200, f.read())
                return self._send(200, json.dumps({'version': 0, 'data': {}}).encode())
            if self.path == '/blobs':
                names = sorted(os.listdir(os.path.join(d, 'blobs')))
                return self._send(200, json.dumps(names).encode())
            if self.path.startswith('/blob/'):
                name = self.path[6:]
                if not BLOB_RE.match(name):
                    return self._send(400)
                p = os.path.join(d, 'blobs', name)
                if not os.path.exists(p):
                    return self._send(404)
                with open(p, 'rb') as f:
                    return self._send(200, f.read(), 'application/octet-stream')
            return self._send(404)

        def do_PUT(self):
            d = self._ns()
            if d is None:
                return self._send(401, b'{"error":"auth"}')
            if self.path == '/state':
                body = self._body(MAX_STATE)
                if body is None:
                    return self._send(413)
                try:
                    data = json.loads(body.decode('utf-8'))
                except Exception:
                    return self._send(400)
                expected = int(self.headers.get('If-Match') or -1)
                with LOCK:
                    p = os.path.join(d, 'state.json')
                    cur = 0
                    if os.path.exists(p):
                        with open(p, 'rb') as f:
                            cur = json.loads(f.read().decode('utf-8')).get('version', 0)
                    if expected != cur:
                        return self._send(409, json.dumps({'version': cur}).encode())
                    new = cur + 1
                    tmp = p + '.tmp'
                    with open(tmp, 'wb') as f:
                        f.write(json.dumps({'version': new, 'data': data}, ensure_ascii=False).encode('utf-8'))
                    os.replace(tmp, p)
                return self._send(200, json.dumps({'version': new}).encode())
            if self.path.startswith('/blob/'):
                name = self.path[6:]
                if not BLOB_RE.match(name):
                    return self._send(400)
                body = self._body(MAX_BLOB)
                if body is None:
                    return self._send(413)
                with open(os.path.join(d, 'blobs', name), 'wb') as f:
                    f.write(body)
                return self._send(200, b'{}')
            return self._send(404)

    return H


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--host', default='0.0.0.0')
    ap.add_argument('--port', type=int, default=8787)
    ap.add_argument('--data', default=os.path.join(os.path.dirname(os.path.abspath(__file__)), 'now_data'))
    ap.add_argument('--keys', default='', help='فهرست کلیدهای مجاز، جداشده با ویرگول (اختیاری)')
    a = ap.parse_args()
    os.makedirs(a.data, exist_ok=True)
    allowed = {k.strip() for k in a.keys.split(',') if k.strip()}
    srv = ThreadingHTTPServer((a.host, a.port), make_handler(a.data, allowed))
    print(f'Now sync server on http://{a.host}:{a.port}  (data: {a.data})')
    srv.serve_forever()


if __name__ == '__main__':
    main()
