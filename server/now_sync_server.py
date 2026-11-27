#!/usr/bin/env python3
"""
سرور حساب کاربری و همگام‌سازی «Now / الآن»
فقط به پایتون ۳ نیاز دارد (بدون نصب چیز اضافه).

اجرا:
    python now_sync_server.py --port 8787

تأیید شماره با پیامک (اختیاری، سرویس کاوه‌نگار):
    python now_sync_server.py --port 8787 --kavenegar-key کلید-API --kavenegar-template نام-قالب

بدون تنظیم پیامک، ثبت‌نام با «شمارهٔ موبایل + رمز عبور» انجام می‌شود (شماره تأیید نمی‌شود).
داده‌ها در پوشهٔ now_data کنار همین فایل ذخیره می‌شوند.
"""
import argparse, hashlib, hmac, json, os, re, secrets, threading, time, urllib.parse, urllib.request
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

LOCK = threading.Lock()
BLOB_RE = re.compile(r'^[A-Za-z0-9_.\-]{1,120}$')
MAX_BLOB = 15 * 1024 * 1024
MAX_STATE = 20 * 1024 * 1024
MAX_JSON = 64 * 1024
OTP_TTL = 300
OTP_RESEND = 60


def normalize_phone(p):
    fa, ar = '۰۱۲۳۴۵۶۷۸۹', '٠١٢٣٤٥٦٧٨٩'
    out = ''
    for c in str(p):
        if c in fa:
            out += str(fa.index(c))
        elif c in ar:
            out += str(ar.index(c))
        elif c.isdigit() or c == '+':
            out += c
    if out.startswith('+98'):
        out = '0' + out[3:]
    elif out.startswith('0098'):
        out = '0' + out[4:]
    elif out.startswith('98') and len(out) == 12:
        out = '0' + out[2:]
    return out


def valid_phone(p):
    return bool(re.fullmatch(r'09\d{9}', p)) or bool(re.fullmatch(r'\+?\d{8,15}', p))


def hash_pw(password, salt):
    return hashlib.pbkdf2_hmac('sha256', password.encode('utf-8'), bytes.fromhex(salt), 150000).hex()


class Store:
    def __init__(self, data_dir):
        self.dir = data_dir
        self.path = os.path.join(data_dir, 'accounts.json')
        self.accounts = {}
        if os.path.exists(self.path):
            with open(self.path, 'rb') as f:
                self.accounts = json.loads(f.read().decode('utf-8'))

    def save(self):
        tmp = self.path + '.tmp'
        with open(tmp, 'wb') as f:
            f.write(json.dumps(self.accounts, ensure_ascii=False).encode('utf-8'))
        os.replace(tmp, self.path)

    def ns_dir(self, phone):
        ns = hashlib.sha256(phone.encode('utf-8')).hexdigest()[:32]
        d = os.path.join(self.dir, ns)
        os.makedirs(os.path.join(d, 'blobs'), exist_ok=True)
        return d

    def find_by_token(self, token):
        th = hashlib.sha256(token.encode('utf-8')).hexdigest()
        for phone, a in self.accounts.items():
            if th in a.get('tokens', []):
                return phone
        return None

    def issue_token(self, phone):
        token = secrets.token_urlsafe(32)
        a = self.accounts[phone]
        toks = a.setdefault('tokens', [])
        toks.append(hashlib.sha256(token.encode('utf-8')).hexdigest())
        del toks[:-10]
        self.save()
        return token


def make_handler(store, otp_cfg, fixed_otp):
    otps = {}  # phone -> (code, expiry, last_sent)
    fails = {}  # ip -> (count, until)

    def send_sms(phone, code):
        if fixed_otp:
            return True
        key, tpl = otp_cfg
        url = 'https://api.kavenegar.com/v1/%s/verify/lookup.json?%s' % (
            urllib.parse.quote(key), urllib.parse.urlencode({'receptor': phone, 'token': code, 'template': tpl}))
        try:
            with urllib.request.urlopen(url, timeout=10) as r:
                return r.status == 200
        except Exception:
            return False

    otp_enabled = bool(fixed_otp) or bool(otp_cfg and otp_cfg[0] and otp_cfg[1])

    class H(BaseHTTPRequestHandler):
        server_version = "NowSync/2"

        def log_message(self, fmt, *args):
            pass

        def _send(self, code, body=b'', ctype='application/json'):
            self.send_response(code)
            self.send_header('Content-Type', ctype)
            self.send_header('Content-Length', str(len(body)))
            self.end_headers()
            self.wfile.write(body)

        def _json(self, code, obj):
            self._send(code, json.dumps(obj, ensure_ascii=False).encode('utf-8'))

        def _body(self, limit):
            n = int(self.headers.get('Content-Length') or 0)
            if n > limit:
                return None
            return self.rfile.read(n)

        def _read_json(self):
            b = self._body(MAX_JSON)
            if b is None:
                return None
            try:
                return json.loads(b.decode('utf-8'))
            except Exception:
                return None

        def _account(self):
            auth = self.headers.get('Authorization', '')
            if not auth.startswith('Bearer '):
                return None
            with LOCK:
                return store.find_by_token(auth[7:].strip())

        def _ip_blocked(self):
            ip = self.client_address[0]
            c, until = fails.get(ip, (0, 0))
            return c >= 8 and time.time() < until

        def _ip_fail(self):
            ip = self.client_address[0]
            c, until = fails.get(ip, (0, 0))
            fails[ip] = (c + 1, time.time() + 300)

        # ---------- auth ----------
        def _auth_post(self):
            data = self._read_json()
            if data is None:
                return self._json(400, {'error': 'bad_request'})
            phone = normalize_phone(data.get('phone', ''))
            if self.path == '/auth/otp':
                if not valid_phone(phone):
                    return self._json(400, {'error': 'invalid_phone'})
                if not otp_enabled:
                    return self._json(200, {'otp': False})
                now = time.time()
                with LOCK:
                    old = otps.get(phone)
                    if old and now - old[2] < OTP_RESEND:
                        return self._json(429, {'error': 'wait'})
                    code = fixed_otp or ''.join(secrets.choice('0123456789') for _ in range(5))
                    otps[phone] = (code, now + OTP_TTL, now)
                if not send_sms(phone, code):
                    return self._json(502, {'error': 'sms_failed'})
                return self._json(200, {'otp': True})
            if self.path == '/auth/register':
                password = str(data.get('password', ''))
                if not valid_phone(phone):
                    return self._json(400, {'error': 'invalid_phone'})
                if len(password) < 6:
                    return self._json(400, {'error': 'weak_password'})
                if otp_enabled:
                    with LOCK:
                        rec = otps.get(phone)
                    if not rec or time.time() > rec[1] or not hmac.compare_digest(rec[0], str(data.get('code', ''))):
                        return self._json(400, {'error': 'bad_code'})
                with LOCK:
                    if phone in store.accounts:
                        return self._json(409, {'error': 'exists'})
                    salt = secrets.token_hex(16)
                    store.accounts[phone] = {'salt': salt, 'hash': hash_pw(password, salt),
                                             'name': str(data.get('name', ''))[:60], 'avatar': '', 'tokens': []}
                    otps.pop(phone, None)
                    token = store.issue_token(phone)
                    a = store.accounts[phone]
                return self._json(200, {'token': token, 'phone': phone, 'name': a['name'], 'avatar': ''})
            if self.path == '/auth/login':
                if self._ip_blocked():
                    return self._json(429, {'error': 'wait'})
                with LOCK:
                    a = store.accounts.get(phone)
                    ok = bool(a) and hmac.compare_digest(a['hash'], hash_pw(str(data.get('password', '')), a['salt']))
                    if not ok:
                        self._ip_fail()
                        return self._json(401, {'error': 'bad_credentials'})
                    token = store.issue_token(phone)
                return self._json(200, {'token': token, 'phone': phone, 'name': a.get('name', ''), 'avatar': a.get('avatar', '')})
            return self._send(404)

        def do_GET(self):
            if self.path == '/ping':
                return self._send(200, b'ok', 'text/plain')
            phone = self._account()
            if phone is None:
                return self._json(401, {'error': 'auth'})
            d = store.ns_dir(phone)
            if self.path == '/me':
                with LOCK:
                    a = store.accounts[phone]
                return self._json(200, {'phone': phone, 'name': a.get('name', ''), 'avatar': a.get('avatar', '')})
            if self.path == '/state':
                with LOCK:
                    p = os.path.join(d, 'state.json')
                    if os.path.exists(p):
                        with open(p, 'rb') as f:
                            return self._send(200, f.read())
                return self._json(200, {'version': 0, 'data': {}})
            if self.path == '/blobs':
                return self._json(200, sorted(os.listdir(os.path.join(d, 'blobs'))))
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

        def do_POST(self):
            return self._auth_post()

        def do_PUT(self):
            phone = self._account()
            if phone is None:
                return self._json(401, {'error': 'auth'})
            d = store.ns_dir(phone)
            if self.path == '/me':
                data = self._read_json()
                if data is None:
                    return self._json(400, {'error': 'bad_request'})
                with LOCK:
                    a = store.accounts[phone]
                    if 'name' in data:
                        a['name'] = str(data['name'])[:60]
                    if 'avatar' in data and BLOB_RE.match(str(data['avatar'])):
                        a['avatar'] = str(data['avatar'])
                    store.save()
                return self._json(200, {})
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
                        return self._json(409, {'version': cur})
                    new = cur + 1
                    tmp = p + '.tmp'
                    with open(tmp, 'wb') as f:
                        f.write(json.dumps({'version': new, 'data': data}, ensure_ascii=False).encode('utf-8'))
                    os.replace(tmp, p)
                return self._json(200, {'version': new})
            if self.path.startswith('/blob/'):
                name = self.path[6:]
                if not BLOB_RE.match(name):
                    return self._send(400)
                body = self._body(MAX_BLOB)
                if body is None:
                    return self._send(413)
                with open(os.path.join(d, 'blobs', name), 'wb') as f:
                    f.write(body)
                return self._json(200, {})
            return self._send(404)

    return H


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--host', default='0.0.0.0')
    ap.add_argument('--port', type=int, default=8787)
    ap.add_argument('--data', default=os.path.join(os.path.dirname(os.path.abspath(__file__)), 'now_data'))
    ap.add_argument('--kavenegar-key', default=os.environ.get('KAVENEGAR_KEY', ''))
    ap.add_argument('--kavenegar-template', default=os.environ.get('KAVENEGAR_TEMPLATE', ''))
    ap.add_argument('--fixed-otp', default='', help='فقط برای آزمایش: کد تأیید ثابت')
    a = ap.parse_args()
    os.makedirs(a.data, exist_ok=True)
    store = Store(a.data)
    srv = ThreadingHTTPServer((a.host, a.port), make_handler(store, (a.kavenegar_key, a.kavenegar_template), a.fixed_otp))
    mode = 'با تأیید پیامکی' if (a.kavenegar_key and a.kavenegar_template) or a.fixed_otp else 'بدون تأیید پیامکی (شماره + رمز)'
    print(f'Now server on http://{a.host}:{a.port}  [{mode}]  data: {a.data}')
    srv.serve_forever()


if __name__ == '__main__':
    main()
