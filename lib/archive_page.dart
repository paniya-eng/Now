import 'package:flutter/material.dart';
import 'app_state.dart';
import 'strings.dart';
import 'ui.dart';

class ArchivePage extends StatelessWidget {
  const ArchivePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: app,
      builder: (context, _) {
        final list = app.archived;
        return Scaffold(
          appBar: AppBar(
            title: Text(tr('archive')),
            backgroundColor: Colors.transparent,
            actions: [
              if (list.isNotEmpty)
                IconButton(
                  tooltip: tr('delete_all'),
                  icon: AppIcon('trash-2', color: Colors.red.shade400),
                  onPressed: () async {
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        content: Text(tr('confirm_delete_all')),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(tr('cancel'))),
                          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(tr('delete'))),
                        ],
                      ),
                    );
                    if (ok == true) app.clearArchive();
                  },
                ),
            ],
          ),
          body: list.isEmpty
              ? Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    AppIcon('archive', size: 56, color: context.sub),
                    const SizedBox(height: 10),
                    Text(tr('archive_empty'), style: TextStyle(color: context.sub)),
                  ]),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    AppCard(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      child: Column(children: [for (final r in list) ReminderTile(r, showDate: true)]),
                    ),
                  ],
                ),
        );
      },
    );
  }
}
