// هستهٔ همگام‌سازی: ادغام داده‌ها + ارتباط با سرور (بدون وابستگی به Flutter)
import 'dart:async';
import 'dart:convert';
import 'dart:io';

class MergeResult {
  MergeResult(this.merged, this.localAhead);
  final Map<String, dynamic> merged;

  /// آیا چیزی در دستگاه جدیدتر از سرور بود (باید به سرور فرستاده شود)؟
  final bool localAhead;
}

const _tombstoneMaxAge = 60 * 24 * 3600 * 1000; // ۶۰ روز

/// ادغام: برای هر شناسه، رکوردی که updatedAt بزرگ‌تر دارد برنده است.
/// حذف‌ها به‌صورت رکورد «del: true» نگه داشته می‌شوند تا به دستگاه‌های دیگر برسند.
MergeResult mergeState(Map<String, dynamic> local, Map<String, dynamic> remote, {int? nowMs}) {
  final now = nowMs ?? DateTime.now().millisecondsSinceEpoch;
  var ahead = false;

  List<Map<String, dynamic>> mergeKey(String key) {
    final m = <String, Map<String, dynamic>>{};
    for (final r in (remote[key] as List? ?? const [])) {
      final rm = Map<String, dynamic>.from(r as Map);
      m[rm['id'] as String] = rm;
    }
    for (final l in (local[key] as List? ?? const [])) {
      final lm = Map<String, dynamic>.from(l as Map);
      final id = lm['id'] as String;
      final r = m[id];
      if (r == null) {
        m[id] = lm;
        ahead = true;
      } else if (((lm['u'] as int?) ?? 0) > ((r['u'] as int?) ?? 0)) {
        m[id] = lm;
        ahead = true;
      }
    }
    final out = m.values.where((e) {
      final dead = (e['del'] as bool?) ?? (e['deleted'] as bool?) ?? false;
      final u = (e['u'] as int?) ?? 0;
      return !(dead && u > 0 && now - u > _tombstoneMaxAge && key != 'cats');
    }).toList();
    out.sort((a, b) => (a['id'] as String).compareTo(b['id'] as String));
    return out;
  }

  final merged = {
    'reminders': mergeKey('reminders'),
    'cats': mergeKey('cats'),
    'occ': mergeKey('occ'),
  };
  return MergeResult(merged, ahead);
}

class SyncException implements Exception {
  SyncException(this.message);
  final String message;
  @override
  String toString() => message;
}

class SyncClient {
  SyncClient(String url, this.key) : base = _normalize(url) {
    _http.connectionTimeout = const Duration(seconds: 10);
  }

  final String base;
  final String key;
  final HttpClient _http = HttpClient();

  static String _normalize(String u) {
    var s = u.trim();
    if (!s.startsWith('http://') && !s.startsWith('https://')) s = 'http://$s';
    while (s.endsWith('/')) {
      s = s.substring(0, s.length - 1);
    }
    return s;
  }

  void close() => _http.close(force: true);

  Future<HttpClientResponse> _send(String method, String path, {List<int>? body, Map<String, String>? headers}) async {
    final req = await _http.openUrl(method, Uri.parse('$base$path')).timeout(const Duration(seconds: 12));
    req.headers.set('authorization', 'Bearer $key');
    headers?.forEach(req.headers.set);
    if (body != null) {
      req.headers.contentLength = body.length;
      req.add(body);
    }
    return req.close().timeout(const Duration(seconds: 30));
  }

  Future<List<int>> _readAll(HttpClientResponse res) async {
    final b = BytesBuilder(copy: false);
    await for (final c in res) {
      b.add(c);
    }
    return b.takeBytes();
  }

  Future<void> ping() async {
    final res = await _send('GET', '/ping');
    await _readAll(res);
    if (res.statusCode != 200) throw SyncException('HTTP ${res.statusCode}');
  }

  /// (نسخه، داده)
  Future<(int, Map<String, dynamic>)> getState() async {
    final res = await _send('GET', '/state');
    final bytes = await _readAll(res);
    if (res.statusCode == 401 || res.statusCode == 403) throw SyncException('auth');
    if (res.statusCode != 200) throw SyncException('HTTP ${res.statusCode}');
    final j = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
    return ((j['version'] as int?) ?? 0, Map<String, dynamic>.from((j['data'] as Map?) ?? {}));
  }

  /// true اگر ذخیره شد؛ false اگر کس دیگری در این بین سرور را تغییر داده (۴۰۹)
  Future<bool> putState(int expectedVersion, Map<String, dynamic> data) async {
    final res = await _send('PUT', '/state',
        body: utf8.encode(jsonEncode(data)),
        headers: {'if-match': '$expectedVersion', 'content-type': 'application/json'});
    await _readAll(res);
    if (res.statusCode == 409) return false;
    if (res.statusCode == 401 || res.statusCode == 403) throw SyncException('auth');
    if (res.statusCode != 200) throw SyncException('HTTP ${res.statusCode}');
    return true;
  }

  Future<Set<String>> listBlobs() async {
    final res = await _send('GET', '/blobs');
    final bytes = await _readAll(res);
    if (res.statusCode != 200) throw SyncException('HTTP ${res.statusCode}');
    return ((jsonDecode(utf8.decode(bytes)) as List?) ?? []).map((e) => e as String).toSet();
  }

  Future<void> putBlob(String name, List<int> bytes) async {
    final res = await _send('PUT', '/blob/$name', body: bytes, headers: {'content-type': 'application/octet-stream'});
    await _readAll(res);
    if (res.statusCode != 200) throw SyncException('HTTP ${res.statusCode}');
  }

  Future<List<int>?> getBlob(String name) async {
    final res = await _send('GET', '/blob/$name');
    final bytes = await _readAll(res);
    if (res.statusCode == 404) return null;
    if (res.statusCode != 200) throw SyncException('HTTP ${res.statusCode}');
    return bytes;
  }
}
