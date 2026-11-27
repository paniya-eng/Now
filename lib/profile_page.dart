import 'dart:io' show File, Platform;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'account_page.dart';
import 'alarm.dart';
import 'app_state.dart';
import 'category_page.dart';
import 'data.dart';
import 'desktop.dart';
import 'fmt.dart';
import 'notifier.dart';
import 'strings.dart';
import 'sync_panel.dart';
import 'sync_service.dart';
import 'ui.dart';

const kContactEmail = 'mostafa.ghorbani.eng@gmail.com';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  // ---------------------------------------------------------------- کمکی‌ها
  Widget _sub(BuildContext context, String title, List<Widget> children) => Column(children: [
        const Divider(height: 1),
        CollapsibleSection(
          title: title,
          initiallyExpanded: false,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
          ),
        ),
      ]);

  Widget _label(String s) => Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 8),
        child: Text(s, style: const TextStyle(fontWeight: FontWeight.w600)),
      );

  Widget _soundRow(BuildContext context, String id, String label, {VoidCallback? onDelete}) {
    final sel = app.soundId == id;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        app.setSound(id);
        AlarmSound.play(loop: false, id: id);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(children: [
          CheckCircle(
            checked: sel,
            onTap: () {
              app.setSound(id);
              AlarmSound.play(loop: false, id: id);
            },
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(label, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: sel ? FontWeight.bold : FontWeight.w500))),
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: () => AlarmSound.play(loop: false, id: id),
            icon: AppIcon('play', size: 20, color: context.accent),
          ),
          if (onDelete != null)
            IconButton(
              visualDensity: VisualDensity.compact,
              onPressed: onDelete,
              icon: AppIcon('trash-2', size: 18, color: Colors.red.shade400),
            ),
        ]),
      ),
    );
  }

  Future<void> _pickSound() async {
    try {
      final res = await FilePicker.platform.pickFiles(type: FileType.audio);
      if (res == null || res.files.isEmpty) return;
      final f = res.files.single;
      if (f.path == null) return;
      final name = await app.addCustomSoundFile(f.path!, f.name);
      if (name != null) {
        app.setSound('custom:$name');
        AlarmSound.play(loop: false, id: 'custom:$name');
      }
    } catch (_) {}
  }

  Future<void> _setClock(BuildContext context) async {
    final t = await pickTime(context, TimeOfDay.fromDateTime(appNow()));
    if (t == null) return;
    final real = DateTime.now();
    var diff = (t.hour * 60 + t.minute) - (real.hour * 60 + real.minute);
    if (diff > 720) diff -= 1440;
    if (diff < -720) diff += 1440;
    app.setClockOffset(diff);
  }


  // ---------------------------------------------------------------- پروفایل
  Widget _avatar(BuildContext context) {
    final name = app.avatarName;
    final file = name.isNotEmpty && app.imageDir.isNotEmpty ? File(app.imagePath(name)) : null;
    return GestureDetector(
      onTap: () => _avatarMenu(context),
      child: Stack(children: [
        CircleAvatar(
          radius: 42,
          backgroundColor: context.accent.withValues(alpha: 0.15),
          backgroundImage: (file != null && file.existsSync()) ? ResizeImage(FileImage(file), width: 256) : null,
          child: (file != null && file.existsSync()) ? null : AppIcon('user', size: 40, color: context.accent),
        ),
        PositionedDirectional(
          bottom: 0,
          end: 0,
          child: Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(color: context.accent, shape: BoxShape.circle, border: Border.all(color: context.card, width: 2)),
            child: AppIcon('camera', size: 14, color: context.onAccent),
          ),
        ),
      ]),
    );
  }

  Future<void> _pickAvatar(ImageSource source) async {
    try {
      final x = await ImagePicker().pickImage(source: source, maxWidth: 600, imageQuality: 85);
      if (x == null) return;
      final saved = await app.saveImage(x);
      if (saved != null) {
        app.setAvatar(saved);
        SyncService.instance.schedule();
      }
    } catch (_) {}
  }

  void _avatarMenu(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: context.card,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          if (Platform.isAndroid)
            ListTile(
              leading: AppIcon('camera', color: ctx.accent),
              title: Text(tr('take_photo')),
              onTap: () {
                Navigator.pop(ctx);
                _pickAvatar(ImageSource.camera);
              },
            ),
          ListTile(
            leading: AppIcon('image', color: ctx.accent),
            title: Text(Platform.isAndroid ? tr('from_gallery') : tr('from_file')),
            onTap: () {
              Navigator.pop(ctx);
              _pickAvatar(ImageSource.gallery);
            },
          ),
          if (app.avatarName.isNotEmpty)
            ListTile(
              leading: AppIcon('trash-2', color: Colors.red.shade400),
              title: Text(tr('remove_photo')),
              onTap: () {
                Navigator.pop(ctx);
                app.setAvatar('', fromSync: false);
              },
            ),
        ]),
      ),
    );
  }

  Future<void> _editName(BuildContext context) async {
    final c = TextEditingController(text: app.accountName);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr('edit_name')),
        content: TextField(controller: c, autofocus: true, decoration: InputDecoration(hintText: tr('name'))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(tr('cancel'))),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(tr('save'))),
        ],
      ),
    );
    final name = c.text.trim();
    c.dispose();
    if (ok == true) {
      app.setAccountName(name);
      SyncService.instance.pushName();
    }
  }

  Future<void> _logout(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        content: Text(tr('confirm_logout')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(tr('cancel'))),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(tr('logout'))),
        ],
      ),
    );
    if (ok == true) app.logout();
  }

  Widget _profileCard(BuildContext context) {
    return AppCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          _avatar(context),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              InkWell(
                onTap: () => _editName(context),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Flexible(
                    child: Text(
                      app.accountName.isNotEmpty ? app.accountName : tr('name'),
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: app.accountName.isEmpty ? context.sub : null),
                    ),
                  ),
                  const SizedBox(width: 6),
                  AppIcon('pen-line', size: 16, color: context.sub),
                ]),
              ),
              const SizedBox(height: 4),
              Ltr(child: Text(app.loggedIn ? nd(app.accountPhone) : tr('not_logged_in'), style: TextStyle(color: context.sub))),
            ]),
          ),
          IconButton(
            tooltip: '${tr('light')} / ${tr('dark')}',
            onPressed: () => app.setThemeMode(context.isDark ? 1 : 2),
            icon: AppIcon(context.isDark ? 'sun' : 'moon', color: context.accent),
          ),
        ]),
        const SizedBox(height: 14),
        if (!app.loggedIn) ...[
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: context.accent, foregroundColor: context.onAccent, minimumSize: const Size.fromHeight(48)),
            onPressed: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const AccountPage())),
            icon: AppIcon('log-in', size: 20, color: context.onAccent),
            label: Text('${tr('login')} / ${tr('register')}', style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 8),
          Text(tr('login_for_sync'), textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: context.sub)),
        ] else
          OutlinedButton.icon(
            onPressed: () => _logout(context),
            icon: AppIcon('log-out', size: 18, color: context.sub),
            label: Text(tr('logout')),
          ),
      ]),
    );
  }

  // ---------------------------------------------------------------- تنظیمات
  Widget _colorPicker(BuildContext context) {
    return Wrap(spacing: 12, runSpacing: 10, children: [
      for (final c in kCatColors)
        GestureDetector(
          onTap: () => app.setAccentColor(Color(c).toARGB32()),
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Color(c),
              shape: BoxShape.circle,
              border: app.accentValue == Color(c).toARGB32() ? Border.all(color: context.ink, width: 3) : null,
            ),
            child: app.accentValue == Color(c).toARGB32() ? const Center(child: AppIcon('check', size: 18, color: Colors.white, stroke: 3)) : null,
          ),
        ),
      GestureDetector(
        onTap: () async {
          final v = await showColorPicker(context, app.accentValue);
          if (v != null) app.setAccentColor(v);
        },
        child: Container(
          width: 38,
          height: 38,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: SweepGradient(colors: [Colors.red, Colors.yellow, Colors.green, Colors.cyan, Colors.blue, Colors.purple, Colors.red]),
          ),
          child: const Center(child: Icon(Icons.colorize, size: 18, color: Colors.white)),
        ),
      ),
    ]);
  }

  Widget _settingsCard(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: CollapsibleSection(
        title: tr('settings'),
        bold: true,
        icon: 'clock',
        initiallyExpanded: false,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          _sub(context, tr('general_group'), [
            Text(tr('language'), style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            OptionChips<String>(options: const [('fa', 'فارسی'), ('en', 'English')], value: app.lang, onSelected: app.setLang),
            _label(tr('theme')),
            OptionChips<int>(options: [(0, tr('system')), (1, tr('light')), (2, tr('dark'))], value: app.themeMode, onSelected: app.setThemeMode),
            _label(tr('color')),
            _colorPicker(context),
            _label(tr('font')),
            OptionChips<bool>(options: [(false, tr('font_app')), (true, tr('font_system'))], value: app.systemFont, onSelected: app.setSystemFont),
            _label(tr('font_size')),
            OptionChips<int>(options: [(0, tr('small')), (1, tr('normal')), (2, tr('large'))], value: app.fontSize, onSelected: app.setFontSize),
          ]),
          _sub(context, tr('clock_title'), [
            SwitchListTile(contentPadding: EdgeInsets.zero, title: Text(tr('h24')), value: app.h24, onChanged: app.setH24),
            SwitchListTile(contentPadding: EdgeInsets.zero, title: Text(tr('show_seconds')), value: app.showSeconds, onChanged: app.setShowSeconds),
            const SizedBox(height: 6),
            LiveTime(builder: (context, now) => Center(child: Ltr(child: Text(fmtTime(now), style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w500))))),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(
                child: FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: context.accent, foregroundColor: context.onAccent),
                  onPressed: () => _setClock(context),
                  child: Text(tr('clock_set')),
                ),
              ),
              if (app.clockOffsetMin != 0) ...[
                const SizedBox(width: 8),
                OutlinedButton(onPressed: () => app.setClockOffset(0), child: Text(tr('clock_reset'))),
              ],
            ]),
            const SizedBox(height: 8),
            Text(tr('clock_note'), style: TextStyle(fontSize: 12, color: context.sub)),
          ]),
          _sub(context, tr('reminder_settings'), [
            Text(tr('silent_after'), style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            OptionChips<int>(
              options: [for (final m in const [1, 5, 10, 15, 20, 25]) (m, '${nd(m)} ${tr('min_unit')}'), (0, tr('never'))],
              value: app.silentAfter,
              onSelected: app.setSilentAfter,
            ),
            _label(tr('snooze_len')),
            OptionChips<int>(options: [for (final m in const [10, 15, 20, 25, 30]) (m, '${nd(m)} ${tr('min_unit')}')], value: app.snooze, onSelected: app.setSnooze),
            _label(tr('followup_after')),
            OptionChips<int>(
              options: [(0, tr('off')), for (final m in const [5, 10, 15, 20, 30]) (m, '${nd(m)} ${tr('min_unit')}')],
              value: app.followUpMin,
              onSelected: app.setFollowUp,
            ),
            _label(tr('notify_before')),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final m in const [60, 120, 180, 360, 720, 1440, 2880, 10080, 43200])
                FilterChip(
                  label: Text(leadLabel(m)),
                  selected: app.leads.contains(m),
                  showCheckmark: false,
                  selectedColor: context.accent,
                  labelStyle: TextStyle(color: app.leads.contains(m) ? context.onAccent : null),
                  onSelected: (_) => app.toggleLead(m),
                ),
            ]),
            const SizedBox(height: 10),
            Text(tr('lead_note'), style: TextStyle(fontSize: 12, color: context.sub)),
            const SizedBox(height: 6),
            Text(tr('reminder_note'), style: TextStyle(fontSize: 12, color: context.sub)),
          ]),
          _sub(context, tr('alarm_sound'), [
            for (final id in const ['bell', 'chime', 'beep', 'melody']) _soundRow(context, id, tr('sound_$id')),
            for (final n in app.customSounds)
              _soundRow(context, 'custom:$n', n.contains('_') ? n.substring(n.indexOf('_') + 1) : n, onDelete: () => app.removeCustomSound(n)),
            const SizedBox(height: 8),
            OutlinedButton.icon(onPressed: _pickSound, icon: AppIcon('plus', size: 18, color: context.accent), label: Text(tr('add_sound'))),
            const SizedBox(height: 8),
            Text(tr('sound_hint'), style: TextStyle(fontSize: 12, color: context.sub)),
          ]),
          _sub(context, tr('categories'), [
            OutlinedButton.icon(
              onPressed: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const CategoriesPage())),
              icon: AppIcon('tags', size: 18, color: context.accent),
              label: Text(tr('manage_categories')),
            ),
          ]),
          _sub(context, tr('server_group'), const [SyncPanel()]),
          _sub(context, tr('widget_title'), [
            Text(Platform.isWindows ? tr('widget_howto_win') : tr('widget_howto_android'), style: TextStyle(fontSize: 13, color: context.sub)),
            if (Platform.isWindows) ...[
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () => Desktop.instance.enterWidget(),
                icon: AppIcon('clock', size: 18, color: context.accent),
                label: Text(tr('widget_mode')),
              ),
            ],
          ]),
          if (Platform.isWindows)
            _sub(context, tr('desktop_group'), [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(tr('close_tray')),
                value: app.closeToTray,
                onChanged: (v) {
                  app.setCloseToTray(v);
                  Desktop.instance.applyCloseMode();
                },
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(tr('run_startup')),
                value: app.autoStart,
                onChanged: (v) {
                  app.setAutoStart(v);
                  Desktop.instance.applyStartup();
                },
              ),
              const SizedBox(height: 6),
              OutlinedButton.icon(
                onPressed: () => Desktop.instance.quit(),
                icon: AppIcon('log-out', size: 18, color: Colors.red.shade400),
                label: Text(tr('exit_app')),
              ),
            ]),
          if (Platform.isAndroid)
            _sub(context, tr('bg_title'), [
              Text(tr('bg_note'), style: TextStyle(fontSize: 13, color: context.sub)),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () async {
                  final err = await Notifier.test();
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err.isEmpty ? tr('test_alarm_sent') : '${tr('sync_err_other')}: $err')));
                },
                icon: AppIcon('bell', size: 18, color: context.accent),
                label: Text(tr('test_alarm')),
              ),
              ValueListenableBuilder<String>(
                valueListenable: Notifier.status,
                builder: (_, v, __) => v.isEmpty
                    ? const SizedBox()
                    : Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text('${tr('sync_err_other')}: $v', style: TextStyle(fontSize: 11, color: Colors.red.shade400)),
                      ),
              ),
            ]),
        ]),
      ),
    );
  }

  // ---------------------------------------------------------------- درباره ما
  Future<void> _feedback(BuildContext context) async {
    final body = '\n\n---\nNow / الآن v$kVersion (${Platform.operatingSystem})';
    final uri = Uri.parse('mailto:$kContactEmail?subject=${Uri.encodeComponent(tr('feedback_subject'))}&body=${Uri.encodeComponent(body)}');
    var ok = false;
    try {
      ok = await launchUrl(uri);
    } catch (_) {}
    if (!ok) {
      await Clipboard.setData(const ClipboardData(text: kContactEmail));
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('email_copied'))));
    }
  }

  Widget _aboutCard(BuildContext context) {
    return AppCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Center(child: Image.asset('assets/icon/logo_small.png', width: 88, height: 88)),
        const SizedBox(height: 10),
        const Center(child: Text('Now / الآن', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold))),
        const SizedBox(height: 2),
        Center(child: Text('${tr('version')} ${nd(kVersion)}', style: TextStyle(color: context.sub))),
        const SizedBox(height: 10),
        Text(tr('about_desc'), textAlign: TextAlign.center, style: TextStyle(color: context.sub, height: 1.5)),
        const Divider(height: 28),
        Text(tr('contact'), style: TextStyle(color: context.sub, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _feedback(context),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(children: [
              AppIcon('mail', size: 20, color: context.accent),
              const SizedBox(width: 10),
              Expanded(child: Ltr(child: Text(kContactEmail, style: TextStyle(color: context.accent, fontWeight: FontWeight.w600)))),
              IconButton(
                tooltip: tr('copy_email'),
                visualDensity: VisualDensity.compact,
                onPressed: () async {
                  await Clipboard.setData(const ClipboardData(text: kContactEmail));
                  if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('email_copied'))));
                },
                icon: AppIcon('copy', size: 18, color: context.sub),
              ),
            ]),
          ),
        ),
        const SizedBox(height: 6),
        FilledButton.icon(
          style: FilledButton.styleFrom(backgroundColor: context.accent, foregroundColor: context.onAccent, minimumSize: const Size.fromHeight(46)),
          onPressed: () => _feedback(context),
          icon: AppIcon('mail', size: 18, color: context.onAccent),
          label: Text(tr('send_feedback')),
        ),
        const SizedBox(height: 10),
        Text(tr('credits'), textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: context.sub)),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: app,
      builder: (context, _) => ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          PageTitle(tr('profile_section')),
          _profileCard(context),
          const SizedBox(height: 12),
          _settingsCard(context),
          const SizedBox(height: 12),
          PageTitle(tr('about_us')),
          _aboutCard(context),
        ],
      ),
    );
  }
}
