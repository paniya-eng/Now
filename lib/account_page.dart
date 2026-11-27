import 'package:flutter/material.dart';
import 'app_state.dart';
import 'strings.dart';
import 'sync_core.dart';
import 'sync_service.dart';
import 'ui.dart';

/// ورود و ثبت‌نام با شمارهٔ موبایل
class AccountPage extends StatefulWidget {
  const AccountPage({super.key});
  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  late final TextEditingController _url = TextEditingController(text: app.syncUrl);
  final _phone = TextEditingController();
  final _pass = TextEditingController();
  final _name = TextEditingController();
  final _code = TextEditingController();
  bool _register = false;
  bool _needCode = false;
  bool _busy = false;
  bool _hide = true;
  String _msg = '';
  bool _error = false;

  @override
  void dispose() {
    _url.dispose();
    _phone.dispose();
    _pass.dispose();
    _name.dispose();
    _code.dispose();
    super.dispose();
  }

  String _text(String code) => switch (code) {
        'exists' => tr('err_exists'),
        'invalid_phone' => tr('err_phone'),
        'weak_password' => tr('err_pass'),
        'bad_credentials' => tr('err_login'),
        'bad_code' => tr('err_code'),
        'wait' => tr('err_wait'),
        'network' => tr('sync_err_net'),
        _ => '${tr('sync_err_other')}: $code',
      };

  Future<void> _submit() async {
    if (_url.text.trim().isEmpty) {
      setState(() { _msg = tr('server_first'); _error = true; });
      return;
    }
    setState(() { _busy = true; _msg = ''; _error = false; });
    final api = AuthApi(_url.text);
    try {
      AuthResult res;
      if (_register) {
        if (!_needCode) {
          final otp = await api.requestCode(_phone.text);
          if (otp) {
            setState(() { _needCode = true; _msg = tr('otp_sent'); _error = false; _busy = false; });
            return;
          }
        }
        res = await api.register(phone: _phone.text, password: _pass.text, name: _name.text.trim(), code: _code.text.trim());
      } else {
        res = await api.login(phone: _phone.text, password: _pass.text);
      }
      app.setSyncServer(_url.text, app.syncAuto);
      app.setAccount(res.token, res.phone, res.name.isNotEmpty ? res.name : app.accountName);
      SyncService.instance.syncNow();
      if (mounted) Navigator.pop(context);
    } on AuthException catch (e) {
      if (mounted) setState(() { _msg = _text(e.code); _error = true; });
    } finally {
      api.close();
      if (mounted) setState(() => _busy = false);
    }
  }

  InputDecoration _dec(String hint, {Widget? suffix}) => InputDecoration(
        hintText: hint,
        suffixIcon: suffix,
        filled: true,
        fillColor: context.card,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(tr('account')), backgroundColor: Colors.transparent),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        OptionChips<bool>(
          options: [(false, tr('login')), (true, tr('register'))],
          value: _register,
          onSelected: (v) => setState(() { _register = v; _needCode = false; _msg = ''; }),
        ),
        const SizedBox(height: 14),
        TextField(controller: _url, textDirection: TextDirection.ltr, keyboardType: TextInputType.url, autocorrect: false, decoration: _dec(tr('server_addr'))),
        const SizedBox(height: 10),
        if (_register) ...[
          TextField(controller: _name, decoration: _dec(tr('name'))),
          const SizedBox(height: 10),
        ],
        TextField(controller: _phone, textDirection: TextDirection.ltr, keyboardType: TextInputType.phone, decoration: _dec(tr('phone'))),
        const SizedBox(height: 10),
        TextField(
          controller: _pass,
          textDirection: TextDirection.ltr,
          obscureText: _hide,
          decoration: _dec(tr('password'),
              suffix: IconButton(onPressed: () => setState(() => _hide = !_hide), icon: Icon(_hide ? Icons.visibility_off : Icons.visibility, size: 20))),
        ),
        if (_register && _needCode) ...[
          const SizedBox(height: 10),
          TextField(controller: _code, textDirection: TextDirection.ltr, keyboardType: TextInputType.number, decoration: _dec(tr('otp_code'))),
        ],
        const SizedBox(height: 16),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: context.accent, foregroundColor: context.onAccent, minimumSize: const Size.fromHeight(50)),
          onPressed: _busy ? null : _submit,
          child: _busy
              ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5))
              : Text(_register ? tr('register') : tr('login'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
        if (_msg.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(_msg, textAlign: TextAlign.center, style: TextStyle(color: _error ? Colors.red.shade400 : context.sub)),
          ),
        const SizedBox(height: 16),
        Text(tr('sync_hint'), style: TextStyle(fontSize: 12, color: context.sub)),
      ]),
    );
  }
}
