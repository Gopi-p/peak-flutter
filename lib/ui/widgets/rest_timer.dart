import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';

import '../../core/utils.dart';
import '../../services/notification_service.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';

class RestTimer extends StatefulWidget {
  const RestTimer({
    super.key,
    required this.defaultSeconds,
    this.onComplete,
  });

  final int defaultSeconds;
  final VoidCallback? onComplete;

  @override
  State<RestTimer> createState() => _RestTimerState();
}

class _RestTimerState extends State<RestTimer> {
  late int _remaining;
  bool _running = true;
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    _remaining = widget.defaultSeconds;
    _start();
  }

  @override
  void dispose() {
    _tick?.cancel();
    NotificationService.instance.cancelRestComplete();
    super.dispose();
  }

  void _start() {
    setState(() => _running = true);
    NotificationService.instance.scheduleRestComplete(_remaining);
    _tick?.cancel();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        if (_remaining > 0) _remaining -= 1;
        if (_remaining <= 0) {
          _running = false;
          _tick?.cancel();
          _onDone();
        }
      });
    });
  }

  void _pause() {
    setState(() => _running = false);
    _tick?.cancel();
    NotificationService.instance.cancelRestComplete();
  }

  void _reset() {
    _tick?.cancel();
    NotificationService.instance.cancelRestComplete();
    setState(() => _remaining = widget.defaultSeconds);
    _start();
  }

  Future<void> _onDone() async {
    HapticFeedback.mediumImpact();
    final has = await Vibration.hasVibrator();
    if (has == true) {
      Vibration.vibrate(duration: 120);
    }
    widget.onComplete?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: PeakColors.surfaceContainer,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: PeakColors.outlineVariant.withValues(alpha: 0.5), width: 0.5),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 96,
            child: Text(
              formatDuration(_remaining),
              style: PeakType.headlineLg().copyWith(
                fontFeatures: const [FontFeature.tabularFigures()],
                color: _remaining <= 3 ? PeakColors.primary : PeakColors.foreground,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: _MiniBtn(
                    icon: _running ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    onTap: _running ? _pause : _start,
                  ),
                ),
                const SizedBox(width: 8),
                _MiniBtn(icon: Icons.refresh_rounded, onTap: _reset),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniBtn extends StatelessWidget {
  const _MiniBtn({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: PeakColors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: PeakColors.foreground),
      ),
    );
  }
}
