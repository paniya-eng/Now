import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'app_state.dart';
import 'sync_core.dart';

/// همگام‌سازی خودکار و دستی با سرور (ویندوز و موبایل با یک آدرس و یک کلید)
class SyncService extends ChangeNotifier {
  SyncService._();
  static final SyncService instance = SyncService._();

  bool busy = false;
  String error = ''; // خالی = موفق
  Timer? _debounce;
  Timer? _periodic;

  void start() {
    app.onDataChanged = schedule;
    _periodic?.cancel();
    _periodic = Timer.periodic(const Duration(seconds: 90), (_) {
      if (app.syncAuto) syncNow();
    });
    Timer(const Duration(seconds: 3), () {
      if (app.syncAuto) syncNow();
    });
  }

  void schedule() {
    if (!app.syncConfigured || !app.syncAuto) return;
    _debounce?.cancel();
    _debounce = Timer(const Duration(seconds: 4), syncNow);
  }

  Future<void> syncNow() async {
    if (busy || !app.syncConfigured) return;
    busy = true;
    error = '';
    notifyListeners();
    final client = SyncClient(app.syncUrl, app.syncKey);
    try {
      var done = false;
      for (var attempt = 0; attempt < 4 && !done; attempt++) {
        final (version, remote) = await client.getState();
        final r = mergeState(app.exportSyncState(), remote);
        app.importSyncState(r.merged);
        if (!r.localAhead) {
          done = true;
        } else {
          done = await client.putState(version, r.merged);
        }
      }
      if (!done) throw SyncException('conflict');
      await _syncImages(client);
      app.markSynced();
    } on SocketException {
      error = 'network';
    } on TimeoutException {
      error = 'timeout';
    } on SyncException catch (e) {
      error = e.message;
    } catch (e) {
      error = '$e';
    } finally {
      client.close();
      busy = false;
      notifyListeners();
    }
  }

  Future<void> _syncImages(SyncClient client) async {
    final used = app.usedImages;
    if (used.isEmpty || app.imageDir.isEmpty) return;
    final remote = await client.listBlobs();
    for (final name in used) {
      final f = File(app.imagePath(name));
      if (f.existsSync()) {
        if (!remote.contains(name)) await client.putBlob(name, await f.readAsBytes());
      } else if (remote.contains(name)) {
        final bytes = await client.getBlob(name);
        if (bytes != null) await f.writeAsBytes(bytes);
      }
    }
    app.markSynced(); // برای تازه‌شدن نمایش تصاویر دانلودشده
  }
}
