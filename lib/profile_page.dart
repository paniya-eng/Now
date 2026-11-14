import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'alarm.dart';
import 'app_state.dart';
import 'category_page.dart';
import 'fmt.dart';
import 'data.dart';
import 'strings.dart';
import 'ui.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  Widget _group(BuildContext context, String title, List<Widget> children) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: AppCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: TextStyle(color: context.sub, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            ...children,
          ]),
        ),
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

  Widget _label(String s) => Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 8),
        child: Text(s, style: const TextStyle(fontWeight: FontWeight.w600)),
      );

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: app,
      builder: (context, _) {
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          children: [
            PageTitle(tr('profile')),
            AppCard(
              child: Row(children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Image.asset('assets/icon/logo_small.png', width: 64, height: 64),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(Tr.fa ? 'الآن / Now' : 'Now / الآن', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    Text('${tr('version')} ${nd(kVersion)}', style: TextStyle(color: context.sub)),
                  ]),
                ),
              ]),
            ),
            const SizedBox(height: 12),
            _group(context, tr('language'), [
              OptionChips<String>(
                options: const [('fa', 'فارسی'), ('en', 'English')],
                value: app.lang,
                onSelected: app.setLang,
              ),
            ]),
            _group(context, tr('appearance'), [
              Text(tr('theme'), style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              OptionChips<int>(
                options: [(0, tr('system')), (1, tr('light')), (2, tr('dark'))],
                value: app.themeMode,
                onSelected: app.setThemeMode,
              ),
              _label(tr('color')),
              Wrap(spacing: 12, runSpacing: 8, children: [
                for (var i = 0; i < kAccents.length; i++)
                  GestureDetector(
                    onTap: () => app.setAccent(i),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: kAccents[i],
                        shape: BoxShape.circle,
                        border: app.accent == i ? Border.all(color: context.ink, width: 3) : null,
                      ),
                      child: app.accent == i ? const Center(child: AppIcon('check', size: 18, color: Colors.white, stroke: 3)) : null,
                    ),
                  ),
              ]),
              _label(tr('font')),
              OptionChips<bool>(
                options: [(false, tr('font_app')), (true, tr('font_system'))],
                value: app.systemFont,
                onSelected: app.setSystemFont,
              ),
              _label(tr('font_size')),
              OptionChips<int>(
                options: [(0, tr('small')), (1, tr('normal')), (2, tr('large'))],
                value: app.fontSize,
                onSelected: app.setFontSize,
              ),
            ]),
            _group(context, tr('clock_settings'), [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(tr('h24')),
                value: app.h24,
                onChanged: app.setH24,
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(tr('show_seconds')),
                value: app.showSeconds,
                onChanged: app.setShowSeconds,
              ),
            ]),
            _group(context, tr('reminder_settings'), [
              Text(tr('silent_after'), style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              OptionChips<int>(
                options: [
                  for (final m in const [1, 5, 10, 15, 20, 25]) (m, '${nd(m)} ${tr('min_unit')}'),
                  (0, tr('never')),
                ],
                value: app.silentAfter,
                onSelected: app.setSilentAfter,
              ),
              _label(tr('snooze_len')),
              OptionChips<int>(
                options: [for (final m in const [10, 15, 20, 25, 30]) (m, '${nd(m)} ${tr('min_unit')}')],
                value: app.snooze,
                onSelected: app.setSnooze,
              ),
              const SizedBox(height: 12),
              Text(tr('reminder_note'), style: TextStyle(fontSize: 12, color: context.sub)),
            ]),
            _group(context, tr('alarm_sound'), [
              for (final id in const ['bell', 'chime', 'beep', 'melody']) _soundRow(context, id, tr('sound_$id')),
              for (final n in app.customSounds)
                _soundRow(
                  context,
                  'custom:$n',
                  n.contains('_') ? n.substring(n.indexOf('_') + 1) : n,
                  onDelete: () => app.removeCustomSound(n),
                ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _pickSound,
                icon: AppIcon('plus', size: 18, color: context.accent),
                label: Text(tr('add_sound')),
              ),
              const SizedBox(height: 8),
              Text(tr('sound_hint'), style: TextStyle(fontSize: 12, color: context.sub)),
            ]),
            _group(context, tr('notify_before'), [
              Wrap(spacing: 8, runSpacing: 8, children: [
                for (final m in const [60, 120, 180, 360, 720, 1440, 2880, 10080, 43200])
                  FilterChip(
                    label: Text(leadLabel(m)),
                    selected: app.leads.contains(m),
                    showCheckmark: false,
                    selectedColor: context.accent,
                    labelStyle: TextStyle(color: app.leads.contains(m) ? Colors.white : null),
                    onSelected: (_) => app.toggleLead(m),
                  ),
              ]),
              const SizedBox(height: 12),
              Text(tr('lead_note'), style: TextStyle(fontSize: 12, color: context.sub)),
            ]),
            _group(context, tr('categories'), [
              OutlinedButton.icon(
                onPressed: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const CategoriesPage())),
                icon: AppIcon('tags', size: 18, color: context.accent),
                label: Text(tr('manage_categories')),
              ),
            ]),
            _group(context, tr('about'), [
              Text(tr('credits'), style: TextStyle(fontSize: 12, color: context.sub)),
            ]),
          ],
        );
      },
    );
  }
}
