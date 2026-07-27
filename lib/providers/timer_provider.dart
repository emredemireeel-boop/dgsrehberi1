import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

import '../services/timer_foreground_service.dart';
import '../screens/home_screen.dart';

enum TimerMode { serbest, pomodoro, derinOdak, maraton }

class TimerProvider with ChangeNotifier {
  TimerMode _currentMode = TimerMode.serbest;

  int _secondsElapsed = 0;
  int _breakSecondsElapsed = 0;

  // Pomodoro Mantığı: 1'den _totalSets'e kadar
  int _currentSet = 1;
  final int _totalSets = 4;

  Timer? _timer;
  bool _isRunning = false;
  bool _isBreakMode = false;

  // Foreground service bildirim güncelleme throttle
  int _lastNotifUpdate = 0;

  int get focusTargetSeconds {
    switch (_currentMode) {
      case TimerMode.pomodoro:
        return 25 * 60;
      case TimerMode.derinOdak:
        return 60 * 60;
      case TimerMode.maraton:
        return 120 * 60;
      case TimerMode.serbest:
        return 0;
    }
  }

  int get breakTargetSeconds {
    switch (_currentMode) {
      case TimerMode.pomodoro:
        return _currentSet >= _totalSets ? 15 * 60 : 5 * 60;
      case TimerMode.derinOdak:
        return 15 * 60;
      case TimerMode.maraton:
        return 30 * 60;
      case TimerMode.serbest:
        return 0;
    }
  }

  TimerMode get currentMode => _currentMode;
  int get secondsElapsed => _secondsElapsed;
  int get breakSecondsElapsed => _breakSecondsElapsed;
  bool get isRunning => _isRunning;
  bool get isBreakMode => _isBreakMode;

  int get currentSet => _currentSet;
  int get totalSets => _totalSets;

  String get modeLabel {
    switch (_currentMode) {
      case TimerMode.serbest:
        return 'Serbest';
      case TimerMode.pomodoro:
        return 'Pomodoro';
      case TimerMode.derinOdak:
        return 'Derin Odak';
      case TimerMode.maraton:
        return 'Maraton';
    }
  }

  double get focusProgress {
    if (_currentMode == TimerMode.serbest) return 0.0;
    return _secondsElapsed / focusTargetSeconds;
  }

  double get breakProgress {
    if (_currentMode == TimerMode.serbest) return 0.0;
    return _breakSecondsElapsed / breakTargetSeconds;
  }

  String _formatDiff(int remaining) {
    int hours = remaining ~/ 3600;
    int minutes = (remaining % 3600) ~/ 60;
    int seconds = remaining % 60;
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String get formattedTime {
    if (_currentMode == TimerMode.serbest) {
      return _formatDiff(_secondsElapsed);
    } else {
      int remaining = focusTargetSeconds - _secondsElapsed;
      if (remaining < 0) remaining = 0;
      return _formatDiff(remaining);
    }
  }

  String get formattedBreakTime {
    if (_currentMode == TimerMode.serbest) {
      return _formatDiff(_breakSecondsElapsed);
    } else {
      int remaining = breakTargetSeconds - _breakSecondsElapsed;
      if (remaining < 0) remaining = 0;
      return _formatDiff(remaining);
    }
  }

  void setMode(TimerMode mode) {
    _currentMode = mode;
    resetTimer();
  }

  void startTimer() {
    if (_timer != null) _timer!.cancel();
    _isRunning = true;
    _isBreakMode = false;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_currentMode != TimerMode.serbest &&
          _secondsElapsed >= focusTargetSeconds) {
        pauseTimer();
        HapticFeedback.heavyImpact();
        notifyListeners();
        return;
      }
      _secondsElapsed++;
      _updateNotification();
      notifyListeners();
    });
    _startForegroundService();
    notifyListeners();
  }

  void pauseTimer() {
    _timer?.cancel();
    _isRunning = false;
    _updateNotificationForced();
    notifyListeners();
  }

  void startBreak() {
    if (_timer != null) _timer!.cancel();
    _isRunning = true;
    _isBreakMode = true;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_currentMode != TimerMode.serbest &&
          _breakSecondsElapsed >= breakTargetSeconds) {
        pauseTimer();
        HapticFeedback.heavyImpact();
        notifyListeners();
        return;
      }
      _breakSecondsElapsed++;
      _updateNotification();
      notifyListeners();
    });
    _updateNotificationForced();
    notifyListeners();
  }

  void endBreak() {
    pauseTimer();
    _isBreakMode = false;
    _breakSecondsElapsed = 0;
    if (_currentMode == TimerMode.pomodoro) {
      _currentSet++;
      if (_currentSet > _totalSets) _currentSet = 1;
    }
    _secondsElapsed = 0;
    _updateNotificationForced();
    notifyListeners();
  }

  void skipToBreak() {
    _secondsElapsed = focusTargetSeconds;
    startBreak();
  }

  void skipToWork() {
    endBreak();
  }

  void resetTimer() {
    _timer?.cancel();
    _secondsElapsed = 0;
    _breakSecondsElapsed = 0;
    _currentSet = 1;
    _isRunning = false;
    _isBreakMode = false;
    _stopForegroundService();
    notifyListeners();
  }

  // ─── Foreground Service Helpers ──────────────────────────────────────────

  Future<void> _startForegroundService() async {
    // Önceki dinleyicileri temizle ve yeniden dinle
    FlutterForegroundTask.removeTaskDataCallback(_onTaskData);
    FlutterForegroundTask.addTaskDataCallback(_onTaskData);

    final bool alreadyRunning = await FlutterForegroundTask.isRunningService;
    if (alreadyRunning) {
      _updateNotificationForced();
      return;
    }
    await TimerForegroundService.startService(
      modeName: modeLabel,
      isBreak: _isBreakMode,
      isRunning: _isRunning,
    );
  }

  void _updateNotification() {
    // Saniyede en fazla 1 kez güncelle (throttle)
    final int now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastNotifUpdate < 900) return;
    _lastNotifUpdate = now;
    _doUpdateNotification();
  }

  void _updateNotificationForced() {
    _lastNotifUpdate = 0;
    _doUpdateNotification();
  }

  Future<void> _doUpdateNotification() async {
    final bool running = await FlutterForegroundTask.isRunningService;
    if (!running) return;
    final int displaySeconds =
        _isBreakMode ? _breakSecondsElapsed : _secondsElapsed;

    TimerForegroundService.updateService(
      modeName: modeLabel,
      isBreak: _isBreakMode,
      isRunning: _isRunning,
      seconds: displaySeconds,
    );
  }

  Future<void> _stopForegroundService() async {
    FlutterForegroundTask.removeTaskDataCallback(_onTaskData);
    await TimerForegroundService.stopService();
  }

  /// Bildirim buton tıklamalarını işle (arka plan isolate'ten gelir)
  void _onTaskData(Object data) {
    if (data is! String) return;

    if (data == 'open_timer_screen') {
      homeScreenKey.currentState?.switchToTimer();
      return;
    }

    switch (data) {
      case FgAction.pause:
        pauseTimer();
        break;
      case FgAction.resume:
        startTimer();
        break;
      case FgAction.startBreak:
        startBreak();
        break;
      case FgAction.endBreak:
        endBreak();
        startTimer();
        break;
      case FgAction.stop:
        resetTimer();
        break;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    FlutterForegroundTask.removeTaskDataCallback(_onTaskData);
    super.dispose();
  }
}
