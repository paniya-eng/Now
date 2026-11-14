import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'alarm.dart';
import 'app_state.dart';
import 'strings.dart';
import 'ui.dart';

class TimerPage extends StatefulWidget {
  const TimerPage({super.key});
  @override
  State<TimerPage> createState() => _TimerPageState();
}

class _TimerPageState extends State<TimerPage> {
  int _h = 0, _m = 5, _s = 0;
  Timer? _t;
  DateTime? _end;
  Duration _total = Duration.zero;
  Duration _left = Duration.zero;
  bool _running = false;
  bool _active = false;

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  void _start() {
    if (!_active) {
      _total = Duration(hours: _h, minutes: _m, seconds: _s);
      if (_total == Duration.zero) return;
      _left = _total;
      _active = true;
    }
    _end = DateTime.now().add(_left);
    _running = true;
    _t?.cancel();
    _t = Timer.periodic(const Duration(milliseconds: 200), (_) => _tick());
    setState(() {});
  }

  void _tick() {
    final left = _end!.difference(DateTime.now());
    if (left <= Duration.zero) {
      _t?.cancel();
      setState(() {
        _left = Duration.zero;
        _running = false;
        _active = false;
      });
      _finished();
    } else {
      setState(() => _left = left);
    }
  }

  void _pause() {
    _t?.cancel();
    _left = _end!.difference(DateTime.now());
    setState(() => _running = false);
  }

  void _reset() {
    _t?.cancel();
    setState(() {
      _running = false;
      _active = false;
    });
  }

  void _finished() {
    HapticFeedback.heavyImpact();
    AlarmSound.play(loop: true);
    if (!mounted) return;
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            AppIcon('hourglass', size: 48, color: ctx.accent),
            const SizedBox(height: 12),
            Text(tr('timer_done'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: ctx.accent),
              onPressed: () {
                AlarmSound.stop();
                Navigator.pop(ctx);
              },
              child: Text(tr('ok')),
            ),
          ]),
        ),
      ),
    );
  }

  String _fmt(Duration d) {
    final secs = (d.inMilliseconds / 1000).ceil();
    final h = secs ~/ 3600;
    final m = (secs % 3600) ~/ 60;
    final s = secs % 60;
    String two(int n) => n.toString().padLeft(2, '0');
    return nd(h > 0 ? '${two(h)}:${two(m)}:${two(s)}' : '${two(m)}:${two(s)}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(tr('timer')), backgroundColor: Colors.transparent),
      body: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          if (!_active)
            SizedBox(
              width: 300,
              child: Ltr(
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                  NumberSpinner(min: 0, max: 23, value: _h, label: tr('hours'), onChanged: (v) => _h = v),
                  NumberSpinner(min: 0, max: 59, value: _m, label: tr('minutes'), onChanged: (v) => _m = v),
                  NumberSpinner(min: 0, max: 59, value: _s, label: tr('seconds'), onChanged: (v) => _s = v),
                ]),
              ),
            )
          else
            SizedBox(
              width: 250,
              height: 250,
              child: Stack(children: [
                SizedBox.expand(
                  child: CircularProgressIndicator(
                    value: _total.inMilliseconds == 0 ? 0 : _left.inMilliseconds / _total.inMilliseconds,
                    strokeWidth: 10,
                    strokeCap: StrokeCap.round,
                    backgroundColor: context.accent.withValues(alpha: 0.15),
                    color: context.accent,
                  ),
                ),
                Center(child: Ltr(child: Text(_fmt(_left), style: const TextStyle(fontSize: 44, fontWeight: FontWeight.w500)))),
              ]),
            ),
          const SizedBox(height: 36),
          Row(mainAxisSize: MainAxisSize.min, children: [
            if (_active) ...[
              OutlinedButton(onPressed: _reset, child: Text(tr('reset'))),
              const SizedBox(width: 14),
            ],
            FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: context.accent, minimumSize: const Size(150, 52)),
              onPressed: _running ? _pause : _start,
              icon: AppIcon(_running ? 'pause' : 'play', color: Colors.white, size: 20),
              label: Text(_running ? tr('pause') : (_active ? tr('resume') : tr('start')),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ]),
        ]),
      ),
    );
  }
}
