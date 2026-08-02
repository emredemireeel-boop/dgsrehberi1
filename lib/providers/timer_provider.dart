import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

import '../services/timer_foreground_service.dart';
import '../screens/home_screen.dart';

enum TimerMode { serbest, pomodoro, derinOdak, maraton }

class TimerProvider with ChangeNotifier, WidgetsBindingObserver {
  TimerProvider() {
    WidgetsBinding.instance.addObserver(this);
  }

  TimerMode _currentMode = TimerMode.serbest;

  int _secondsElapsed = 0;
  int _breakSecondsElapsed = 0;

  // Pomodoro Mantığı: 1'den _totalSets'e kadar
  int _currentSet = 1;
  final int _totalSets = 4;

  Timer? _timer;
  DateTime? _lastTickAt;
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
    _isRunning = true;
    _isBreakMode = false;
    _startClock();
    unawaited(_startForegroundService());
    notifyListeners();
  }

  void pauseTimer() {
    _syncElapsedTime(notify: false);
    _timer?.cancel();
    _timer = null;
    _lastTickAt = null;
    _isRunning = false;
    _updateNotificationForced();
    notifyListeners();
  }

  void startBreak() {
    _isRunning = true;
    _isBreakMode = true;
    _startClock();
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
    _timer = null;
    _lastTickAt = null;
    _secondsElapsed = 0;
    _breakSecondsElapsed = 0;
    _currentSet = 1;
    _isRunning = false;
    _isBreakMode = false;
    _stopForegroundService();
    notifyListeners();
  }

  void _startClock() {
    _timer?.cancel();
    _lastTickAt = DateTime.now();
    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _syncElapsedTime(),
    );
  }

  void _syncElapsedTime({bool notify = true}) {
    if (!_isRunning || _lastTickAt == null) return;

    final now = DateTime.now();
    final elapsedSeconds = now.difference(_lastTickAt!).inSeconds;
    if (elapsedSeconds <= 0) return;

    _lastTickAt = _lastTickAt!.add(Duration(seconds: elapsedSeconds));
    var finished = false;

    if (_isBreakMode) {
      _breakSecondsElapsed += elapsedSeconds;
      if (_currentMode != TimerMode.serbest &&
          _breakSecondsElapsed >= breakTargetSeconds) {
        _breakSecondsElapsed = breakTargetSeconds;
        finished = true;
      }
    } else {
      _secondsElapsed += elapsedSeconds;
      if (_currentMode != TimerMode.serbest &&
          _secondsElapsed >= focusTargetSeconds) {
        _secondsElapsed = focusTargetSeconds;
        finished = true;
      }
    }

    if (finished) {
      _timer?.cancel();
      _timer = null;
      _lastTickAt = null;
      _isRunning = false;
      HapticFeedback.heavyImpact();
    }

    _updateNotification();
    if (notify) notifyListeners();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _syncElapsedTime();
    }
  }

  // ─── Foreground Service Helpers ──────────────────────────────────────────

  bool get _supportsForegroundService =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  Future<void> _startForegroundService() async {
    if (!_supportsForegroundService) return;

    final permission =
        await FlutterForegroundTask.checkNotificationPermission();
    if (permission != NotificationPermission.granted) {
      await FlutterForegroundTask.requestNotificationPermission();
    }

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
    if (!_supportsForegroundService) return;
    // Saniyede en fazla 1 kez güncelle (throttle)
    final int now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastNotifUpdate < 900) return;
    _lastNotifUpdate = now;
    _doUpdateNotification();
  }

  void _updateNotificationForced() {
    if (!_supportsForegroundService) return;
    _lastNotifUpdate = 0;
    _doUpdateNotification();
  }

  Future<void> _doUpdateNotification() async {
    if (!_supportsForegroundService) return;
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
    if (!_supportsForegroundService) return;
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
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    if (_supportsForegroundService) {
      FlutterForegroundTask.removeTaskDataCallback(_onTaskData);
    }
    super.dispose();
  }
}
