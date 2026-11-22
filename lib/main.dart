import 'dart:ui' show PointerDeviceKind;
import 'package:flutter/material.dart';
import 'alarm.dart';
import 'app_state.dart';
import 'data.dart';
import 'calendar_page.dart';
import 'clock_page.dart';
import 'desktop.dart';
import 'notifier.dart';
import 'sync_service.dart';
import 'widget_view.dart';
import 'home_page.dart';
import 'profile_page.dart';
import 'search_page.dart';
import 'strings.dart';
import 'ui.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await app.load();
  await Desktop.instance.init();
  Notifier.init();
  SyncService.instance.start();
  AlarmService.instance.start();
  runApp(const NowApp());
}

ThemeData _theme(bool dark) {
  final accent = kAccents[app.accent];
  final cs = ColorScheme.fromSeed(seedColor: accent, brightness: dark ? Brightness.dark : Brightness.light);
  return ThemeData(
    useMaterial3: true,
    colorScheme: cs,
    fontFamily: app.systemFont ? null : 'AppFont',
    scaffoldBackgroundColor: dark ? const Color(0xFF101116) : const Color(0xFFEDEEF3),
    appBarTheme: const AppBarTheme(centerTitle: true, scrolledUnderElevation: 0),
  );
}

class _AppScroll extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => PointerDeviceKind.values.toSet();
}

class NowApp extends StatelessWidget {
  const NowApp({super.key});
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: app,
      builder: (context, _) => MaterialApp(
        title: 'Now',
        debugShowCheckedModeBanner: false,
        scrollBehavior: _AppScroll(),
        navigatorKey: navKey,
        theme: _theme(false),
        darkTheme: _theme(true),
        themeMode: const [ThemeMode.system, ThemeMode.light, ThemeMode.dark][app.themeMode],
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(const [0.9, 1.0, 1.15][app.fontSize])),
          child: Directionality(
            textDirection: Tr.fa ? TextDirection.rtl : TextDirection.ltr,
            child: child!,
          ),
        ),
        home: ValueListenableBuilder<bool>(
          valueListenable: Desktop.instance.widgetMode,
          builder: (_, w, __) => w ? const DesktopWidget() : const Shell(),
        ),
      ),
    );
  }
}

class Shell extends StatelessWidget {
  const Shell({super.key});
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: app,
      builder: (context, _) {
        const pages = <Widget>[HomePage(), CalendarPage(), ClockPage(), SearchPage(), ProfilePage()];
        return Scaffold(
          body: SafeArea(bottom: false, child: pages[app.tab]),
          bottomNavigationBar: const SafeArea(child: _NavBar()),
        );
      },
    );
  }
}

class _NavBar extends StatelessWidget {
  const _NavBar();

  static const _items = [
    ('house', 'home'),
    ('calendar-days', 'calendar'),
    ('clock', 'clock'),
    ('search', 'search'),
    ('user', 'profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: app,
      builder: (context, _) => _bar(context),
    );
  }

  Widget _bar(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 6, 14, 10),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: context.card,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.07), blurRadius: 16, offset: const Offset(0, 4))],
      ),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        for (var i = 0; i < _items.length; i++)
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => app.setTab(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              padding: EdgeInsets.symmetric(horizontal: app.tab == i ? 16 : 12, vertical: 11),
              decoration: BoxDecoration(
                color: app.tab == i ? Colors.black : Colors.transparent,
                borderRadius: BorderRadius.circular(22),
                border: (app.tab == i && context.isDark) ? Border.all(color: Colors.white24) : null,
              ),
              child: AnimatedSize(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutCubic,
                alignment: AlignmentDirectional.centerStart,
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  AppIcon(_items[i].$1, size: 22, color: app.tab == i ? Colors.white : context.ink, stroke: 1.8),
                  if (app.tab == i) ...[
                    const SizedBox(width: 7),
                    Text(tr(_items[i].$2), style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                  ],
                ]),
              ),
            ),
          ),
      ]),
    );
  }
}
