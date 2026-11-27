import 'package:flutter/material.dart';
import 'app_state.dart';
import 'fmt.dart';
import 'jalali.dart';
import 'strings.dart';
import 'sync_service.dart';
import 'ui.dart';

/// تنظیمات همگام‌سازی (نیازمند ورود به حساب کاربری)
class SyncPanel extends StatefulWidget {
  const SyncPanel({super.key});
  @override
  State<SyncPanel> createState() => _SyncPanelState();
}

class _SyncPanelState extends State<SyncPanel> {
  late final TextEditingController _url = TextEditingController(text: app.syncUrl);
  late bool _auto = app.syncAuto;

  @override
  void dispose() {
    _url.dispose();
    super.dispose();
  }

  String _status() {
    final s = SyncService.instance;
    if (!app.loggedIn) return tr('login_for_sync');
    if (s.busy) return tr('sync_running');
    if (s.error.isNotEmpty) {
      return switch (s.error) {
        'auth' => tr('sync_err_auth'),
        'network' || 'timeout' => tr('sync_err_net'),
        _ => '${tr('sync_err_other')}: ${s.error}',
      };
    }
    if (app.lastSyncMs == 0) return tr('sync_never');
    final d = DateTime.fromMillisecondsSinceEpoch(app.lastSyncMs);
    return '${tr('sync_last')}: ${jShort(Jalali.fromDateTime(d))} • ${fmtTime(d)}';
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: SyncService.instance,
      builder: (context, _) {
        final err = SyncService.instance.error.isNotEmpty || !app.loggedIn;
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(tr('sync_hint'), style: TextStyle(fontSize: 12, color: context.sub)),
          const SizedBox(height: 10),
          TextField(
            controller: _url,
            textDirection: TextDirection.ltr,
            keyboardType: TextInputType.url,
            autocorrect: false,
            decoration: InputDecoration(
              hintText: tr('server_addr'),
              filled: true,
              fillColor: context.bg,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
            ),
            onChanged: (v) => app.setSyncServer(v, _auto),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(tr('sync_auto')),
            value: _auto,
            onChanged: (v) {
              setState(() => _auto = v);
              app.setSyncServer(_url.text, v);
            },
          ),
          Row(children: [
            Expanded(
              child: FilledButton(
                style: FilledButton.styleFrom(backgroundColor: context.accent, foregroundColor: context.onAccent, minimumSize: const Size.fromHeight(46)),
                onPressed: (SyncService.instance.busy || !app.syncConfigured) ? null : () => SyncService.instance.syncNow(),
                child: Text(tr('sync_now')),
              ),
            ),
          ]),
          const SizedBox(height: 8),
          Text(_status(), style: TextStyle(fontSize: 12, color: err ? Colors.red.shade400 : context.sub)),
        ]);
      },
    );
  }
}
