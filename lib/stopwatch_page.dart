import 'dart:async';
import 'package:flutter/material.dart';
import 'app_state.dart';
import 'strings.dart';
import 'ui.dart';

class StopwatchPage extends StatefulWidget {
  const StopwatchPage({super.key});
  @override
  State<StopwatchPage> createState() => _StopwatchPageState();
}

class _StopwatchPageState extends State<StopwatchPage> {
  final Stopwatch _sw = Stopwatch();
  final ValueNotifier<int> _ms = ValueNotifier<int>(0);
  final List<int> _laps = [];
  Timer? _t;

  @override
  void dispose() {
    _t?.cancel();
    _ms.dispose();
    super.dispose();
  }

  void _start() {
    _sw.start();
    _t = Timer.periodic(const Duration(milliseconds: 40), (_) => _ms.value = _sw.elapsedMilliseconds);
    setState(() {});
  }

  void _stop() {
    _sw.stop();
    _t?.cancel();
    _ms.value = _sw.elapsedMilliseconds;
    setState(() {});
  }

  void _lap() => setState(() => _laps.insert(0, _sw.elapsedMilliseconds));

  void _reset() {
    _sw.reset();
    _ms.value = 0;
    setState(_laps.clear);
  }

  String _fmt(int ms) {
    final cs = (ms ~/ 10) % 100;
    final s = (ms ~/ 1000) % 60;
    final m = ms ~/ 60000;
    String two(int n) => n.toString().padLeft(2, '0');
    return nd('${two(m)}:${two(s)}.${two(cs)}');
  }

  @override
  Widget build(BuildContext context) {
    final running = _sw.isRunning;
    final started = _sw.elapsedMilliseconds > 0;
    return Scaffold(
      appBar: AppBar(title: Text(tr('stopwatch')), backgroundColor: Colors.transparent),
      body: Column(children: [
        const SizedBox(height: 24),
        ValueListenableBuilder<int>(
          valueListenable: _ms,
          builder: (_, v, __) => Ltr(child: Text(_fmt(v), style: const TextStyle(fontSize: 60, fontWeight: FontWeight.w500))),
        ),
        const SizedBox(height: 24),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          if (running)
            OutlinedButton(onPressed: _lap, child: Text(tr('lap')))
          else if (started)
            OutlinedButton(onPressed: _reset, child: Text(tr('reset'))),
          if (running || started) const SizedBox(width: 14),
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: context.accent, minimumSize: const Size(150, 52)),
            onPressed: running ? _stop : _start,
            icon: AppIcon(running ? 'pause' : 'play', color: Colors.white, size: 20),
            label: Text(running ? tr('pause') : (started ? tr('resume') : tr('start')),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ]),
        const SizedBox(height: 16),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: _laps.length,
            itemBuilder: (_, i) {
              final total = _laps[i];
              final split = total - (i + 1 < _laps.length ? _laps[i + 1] : 0);
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(children: [
                  Text('${tr('lap')} ${nd(_laps.length - i)}', style: TextStyle(color: context.sub)),
                  const Spacer(),
                  Ltr(child: Text('+${_fmt(split)}', style: TextStyle(color: context.sub))),
                  const SizedBox(width: 16),
                  Ltr(child: Text(_fmt(total), style: const TextStyle(fontWeight: FontWeight.bold))),
                ]),
              );
            },
          ),
        ),
      ]),
    );
  }
}
