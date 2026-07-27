import 'package:flutter_foreground_task/flutter_foreground_task.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Bildirim aksiyon ID'leri (buton tıklamalarını tanımlamak için)
// ─────────────────────────────────────────────────────────────────────────────
class FgAction {
  static const pause = 'pause';
  static const resume = 'resume';
  static const startBreak = 'start_break';
  static const endBreak = 'end_break';
  static const stop = 'stop';
}

// ─────────────────────────────────────────────────────────────────────────────
// Foreground Task Handler — izole vm:entry-point
// ─────────────────────────────────────────────────────────────────────────────
@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(TimerTaskHandler());
}

class TimerTaskHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {}

  @override
  void onRepeatEvent(DateTime timestamp) {
    // Bildirim metni TimerProvider'dan updateService çağrısıyla güncelleniyor.
    // Burada ek işlem gerekmez.
  }

  @override
  void onReceiveData(Object data) {
    // TimerProvider tarafından gönderilen veri — bu handler
    // sadece iletişim köprüsü olarak kullanılıyor.
  }

  @override
  Future<void> onDestroy(DateTime timestamp) async {}

  @override
  void onNotificationButtonPressed(String id) {
    // Buton tıklamalarını ana isolate'e ilet
    FlutterForegroundTask.sendDataToMain(id);
  }

  @override
  void onNotificationPressed() {
    // Bildirime tıklanınca uygulamayı öne getir ve sayaç sekmesini açmasını iste
    FlutterForegroundTask.launchApp();
    FlutterForegroundTask.sendDataToMain('open_timer_screen');
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TimerForegroundService — yardımcı sınıf
// TimerProvider tarafından kullanılır
// ─────────────────────────────────────────────────────────────────────────────
class TimerForegroundService {
  /// Foreground task sistemini hazırlar (main'de çağrılır)
  static void init() {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'dgs_timer_channel',
        channelName: 'DGS Rehberi Zamanlayıcı',
        channelDescription: 'Çalışma zamanlayıcısı arka planda çalışıyor',
        channelImportance: NotificationChannelImportance.HIGH,
        priority: NotificationPriority.HIGH,
        enableVibration: false,
        playSound: false,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: true,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(5000),
        autoRunOnBoot: false,
        allowWakeLock: true,
        allowWifiLock: false,
      ),
    );
  }

  /// Zamanlayıcı başlatılınca foreground service'i başlat
  static Future<void> startService({
    required String modeName,
    required bool isBreak,
    required bool isRunning,
  }) async {
    final List<NotificationButton> buttons =
        _buildButtons(isBreak: isBreak, isRunning: isRunning);

    await FlutterForegroundTask.startService(
      serviceId: 2501,
      notificationTitle:
          isBreak ? '☕ $modeName — Mola' : '📚 $modeName — Çalışıyor',
      notificationText: isBreak ? 'Mola başladı' : 'Çalışma başladı',
      notificationButtons: buttons,
      callback: startCallback,
    );
  }

  /// Zamanlayıcı durumu değişince bildirimi güncelle
  static Future<void> updateService({
    required String modeName,
    required bool isBreak,
    required bool isRunning,
    required int seconds,
  }) async {
    final List<NotificationButton> buttons =
        _buildButtons(isBreak: isBreak, isRunning: isRunning);

    final int hrs = seconds ~/ 3600;
    final int mins = (seconds % 3600) ~/ 60;
    final int secs = seconds % 60;
    final String timeStr = hrs > 0
        ? '${hrs.toString().padLeft(2, '0')}:${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}'
        : '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';

    final String body =
        isBreak ? 'Mola süresi: $timeStr' : 'Çalışma süresi: $timeStr';

    await FlutterForegroundTask.updateService(
      notificationTitle:
          isBreak ? '☕ $modeName — Mola' : '📚 $modeName — Çalışıyor',
      notificationText: body,
      notificationButtons: buttons,
    );
  }

  /// Foreground servisi durdur (timer sıfırlanınca)
  static Future<void> stopService() async {
    await FlutterForegroundTask.stopService();
  }

  /// Aksiyon butonlarını duruma göre oluştur
  static List<NotificationButton> _buildButtons({
    required bool isBreak,
    required bool isRunning,
  }) {
    if (isBreak) {
      return [
        const NotificationButton(id: FgAction.endBreak, text: '▶ Devam Et'),
        const NotificationButton(id: FgAction.stop, text: '⏹ Bitir'),
      ];
    } else if (isRunning) {
      return [
        const NotificationButton(id: FgAction.pause, text: '⏸ Duraklat'),
        const NotificationButton(id: FgAction.startBreak, text: '☕ Mola'),
        const NotificationButton(id: FgAction.stop, text: '⏹ Bitir'),
      ];
    } else {
      return [
        const NotificationButton(id: FgAction.resume, text: '▶ Devam'),
        const NotificationButton(id: FgAction.stop, text: '⏹ Bitir'),
      ];
    }
  }
}
