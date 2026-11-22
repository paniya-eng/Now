import 'package:flutter/material.dart';
import 'app_state.dart';
import 'fmt.dart';
import 'jalali.dart';
import 'strings.dart';
import 'sync_service.dart';
import 'ui.dart';

class SyncPanel extends StatefulWidget {
  const SyncPanel({super.key});
  @override
  State<SyncPanel> createState() => _SyncPanelState();
}

class _SyncPanelState extends State<SyncPanel> {
  late final TextEditingController _url = TextEditingController(text: app.syncUrl);
  late final TextEditingController _key = TextEditingController(text: app.syncKey);
  late bool _auto = app.syncAuto;
  bool _hide = true;

  @override
  void dispose() {
    _url.dispose();
    _key.dispose();
    super.dispose();
  }

  String _status() {
    final s = SyncService.instance;
    if (s.busy) return tr('sync_running');
    if (s.error.isNotEmpty) {
      final msg = switch (s.error) {
        'auth' => tr('sync_err_auth'),
        'network' || 'timeout' => tr('sync_err_net'),
        _ => '${tr('sync_err_other')}: ${s.error}',
      };
      return msg;
    }
    if (app.lastSyncMs == 0) return tr('sync_never');
    final d = DateTime.fromMillisecondsSinceEpoch(app.lastSyncMs);
    return '${tr('sync_last')}: ${jShort(Jalali.fromDateTime(d))} • ${fmtTime(d)}';
  }

  InputDecoration _dec(String hint, {Widget? suffix}) => InputDecoration(
        hintText: hint,
        suffixIcon: suffix,
        filled: true,
        fillColor: context.bg,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
      );

  void _save() {
    app.setSyncConfig(_url.text, _key.text, _auto);
    SyncService.instance.syncNow();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: SyncService.instance,
      builder: (context, _) {
        final err = SyncService.instance.error.isNotEmpty;
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(tr('sync_hint'), style: TextStyle(fontSize: 12, color: context.sub)),
          const SizedBox(height: 10),
          TextField(
            controller: _url,
            textDirection: TextDirection.ltr,
            keyboardType: TextInputType.url,
            autocorrect: false,
            decoration: _dec(tr('sync_url')),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _key,
            textDirection: TextDirection.ltr,
            obscureText: _hide,
            autocorrect: false,
            decoration: _dec(
              tr('sync_key'),
              suffix: IconButton(
                onPressed: () => setState(() => _hide = !_hide),
                icon: Icon(_hide ? Icons.visibility_off : Icons.visibility, size: 20),
              ),
            ),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(tr('sync_auto')),
            value: _auto,
            onChanged: (v) {
              setState(() => _auto = v);
              app.setSyncConfig(_url.text, _key.text, v);
            },
          ),
          Row(children: [
            Expanded(
              child: FilledButton(
                style: FilledButton.styleFrom(backgroundColor: context.accent, minimumSize: const Size.fromHeight(46)),
                onPressed: SyncService.instance.busy ? null : _save,
                child: Text(tr('sync_save')),
              ),
            ),
            if (app.syncConfigured) ...[
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: SyncService.instance.busy ? null : () => SyncService.instance.syncNow(),
                child: Text(tr('sync_now')),
              ),
            ],
          ]),
          const SizedBox(height: 8),
          Text(_status(), style: TextStyle(fontSize: 12, color: err ? Colors.red.shade400 : context.sub)),
        ]);
      },
    );
  }
}
