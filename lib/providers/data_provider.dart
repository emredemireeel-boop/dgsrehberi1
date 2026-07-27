import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/study_session.dart';
import '../models/daily_routine.dart';

class DataProvider with ChangeNotifier {
  List<StudySession> _sessions = [];
  List<StudySession> get sessions => _sessions;

  DailyRoutine? _todayRoutine;
  DailyRoutine? get todayRoutine => _todayRoutine;

  DateTime? _dgsTargetDate;
  DateTime? get dgsTargetDate => _dgsTargetDate;

  List<String> _completedTopics = [];
  List<String> get completedTopics => _completedTopics;

  // Günlük hedef (dakika)
  int _dailyGoalMinutes = 120;
  int get dailyGoalMinutes => _dailyGoalMinutes;

  // Streak
  int _currentStreak = 0;
  int _longestStreak = 0;
  int get currentStreak => _currentStreak;
  int get longestStreak => _longestStreak;

  DataProvider() {
    loadSessions();
    loadRoutines();
    loadTargetDateAndTopics();
    _loadSettings();
  }

  // ── Günlük ilerleme ─────────────────────────────────────────────────────
  int get todayStudiedSeconds {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    return _sessions
        .where((s) =>
            s.date.isAfter(todayStart.subtract(const Duration(seconds: 1))))
        .fold(0, (sum, s) => sum + s.durationSeconds);
  }

  double get todayGoalProgress {
    if (_dailyGoalMinutes <= 0) return 0.0;
    return (todayStudiedSeconds / (_dailyGoalMinutes * 60)).clamp(0.0, 1.0);
  }

  // ── Konu bazlı istatistik ────────────────────────────────────────────────
  Map<String, int> get subjectMinutesThisWeek {
    final now = DateTime.now();
    final start = _getStartOfWeek(now);
    final weeklySessions = _sessions
        .where(
            (s) => s.date.isAfter(start.subtract(const Duration(seconds: 1))))
        .toList();

    final result = <String, int>{};
    for (final s in weeklySessions) {
      final label = s.subject.isEmpty ? 'Genel' : s.subject;
      result[label] = (result[label] ?? 0) + (s.durationSeconds ~/ 60);
    }
    return result;
  }

  // ── Settings ─────────────────────────────────────────────────────────────
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _dailyGoalMinutes = prefs.getInt('daily_goal_minutes') ?? 120;
    _currentStreak = prefs.getInt('current_streak') ?? 0;
    _longestStreak = prefs.getInt('longest_streak') ?? 0;
    notifyListeners();
  }

  Future<void> setDailyGoal(int minutes) async {
    _dailyGoalMinutes = minutes;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('daily_goal_minutes', minutes);
    notifyListeners();
  }

  // ── Streak ────────────────────────────────────────────────────────────────
  void _updateStreak() {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final yesterdayStart = todayStart.subtract(const Duration(days: 1));

    // Bugün herhangi bir oturum var mı?
    final hasToday = _sessions.any(
        (s) => s.date.isAfter(todayStart.subtract(const Duration(seconds: 1))));
    // Dün oturum var mı?
    final hasYesterday = _sessions.any((s) =>
        s.date.isAfter(yesterdayStart.subtract(const Duration(seconds: 1))) &&
        s.date.isBefore(todayStart));

    if (hasToday) {
      if (!hasYesterday && _currentStreak == 0) {
        _currentStreak = 1;
      } else if (hasYesterday) {
        // sadece bugün ilk kez kaydedildiyse artır
        final todayCount = _sessions
            .where((s) =>
                s.date.isAfter(todayStart.subtract(const Duration(seconds: 1))))
            .length;
        if (todayCount == 1) _currentStreak++;
      }
      if (_currentStreak > _longestStreak) _longestStreak = _currentStreak;
    }
    _saveStreakToPrefs();
  }

  Future<void> _saveStreakToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('current_streak', _currentStreak);
    await prefs.setInt('longest_streak', _longestStreak);
  }

  // ── Sessions ──────────────────────────────────────────────────────────────
  Future<void> loadSessions() async {
    final prefs = await SharedPreferences.getInstance();
    final String? sessionsJson = prefs.getString('study_sessions');
    if (sessionsJson != null) {
      final List<dynamic> decoded = jsonDecode(sessionsJson);
      _sessions = decoded.map((e) => StudySession.fromJson(e)).toList();
      notifyListeners();
    } else {
      _sessions = [];
      notifyListeners();
    }
  }

  Future<void> loadTargetDateAndTopics() async {
    final prefs = await SharedPreferences.getInstance();

    // Load DGS target date
    final String? dateStr = prefs.getString('dgs_target_date');
    if (dateStr != null) {
      _dgsTargetDate = DateTime.tryParse(dateStr);
    }

    // Load completed topics
    _completedTopics = prefs.getStringList('completed_topics') ?? [];
    notifyListeners();
  }

  Future<void> setDgsTargetDate(DateTime date) async {
    _dgsTargetDate = date;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('dgs_target_date', date.toIso8601String());
    notifyListeners();
  }

  Future<void> toggleTopic(String topicName) async {
    if (_completedTopics.contains(topicName)) {
      _completedTopics.remove(topicName);
    } else {
      _completedTopics.add(topicName);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('completed_topics', _completedTopics);
    notifyListeners();
  }

  Future<void> addSession(StudySession session) async {
    _sessions.add(session);
    _updateStreak();
    notifyListeners();
    await _saveToPrefs();
  }

  Future<void> addManualLog(int verbal, int numerical) async {
    final session = StudySession(
      id: DateTime.now().toIso8601String(),
      date: DateTime.now(),
      durationSeconds: 0,
      breakSeconds: 0,
      verbalQuestions: verbal,
      numericalQuestions: numerical,
    );
    await addSession(session);
  }

  Future<void> _saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded =
        jsonEncode(_sessions.map((e) => e.toJson()).toList());
    await prefs.setString('study_sessions', encoded);
  }

  DateTime _getStartOfWeek(DateTime date) =>
      DateTime(date.year, date.month, date.day - date.weekday + 1);
  DateTime _getStartOfMonth(DateTime date) =>
      DateTime(date.year, date.month, 1);
  DateTime _getStartOfYear(DateTime date) => DateTime(date.year, 1, 1);

  List<StudySession> getThisWeekSessions() {
    final now = DateTime.now();
    final start = _getStartOfWeek(now);
    return _sessions
        .where(
            (s) => s.date.isAfter(start.subtract(const Duration(seconds: 1))))
        .toList();
  }

  List<StudySession> getThisMonthSessions() {
    final now = DateTime.now();
    final start = _getStartOfMonth(now);
    return _sessions
        .where(
            (s) => s.date.isAfter(start.subtract(const Duration(seconds: 1))))
        .toList();
  }

  List<StudySession> getThisYearSessions() {
    final now = DateTime.now();
    final start = _getStartOfYear(now);
    return _sessions
        .where(
            (s) => s.date.isAfter(start.subtract(const Duration(seconds: 1))))
        .toList();
  }

  // ── Bugünkü oturumlar ─────────────────────────────────────────────────────
  List<StudySession> getTodaySessions() {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    return _sessions
        .where((s) =>
            s.date.isAfter(todayStart.subtract(const Duration(seconds: 1))))
        .toList()
        .reversed
        .toList();
  }

  String get _todayDateString {
    final now = DateTime.now();
    return "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
  }

  Future<void> loadRoutines() async {
    final prefs = await SharedPreferences.getInstance();

    List<String> templates = prefs.getStringList('routine_templates') ??
        [
          "30 Problem",
          "30 Paragraf",
          "30 Geometri",
          "10 Sözel Mantık",
          "10 Sayısal Mantık"
        ];

    String todayKey = 'routine_$_todayDateString';
    String? todayRoutineJson = prefs.getString(todayKey);

    if (todayRoutineJson != null) {
      _todayRoutine = DailyRoutine.fromJson(jsonDecode(todayRoutineJson));
    } else {
      _todayRoutine = DailyRoutine(
        dateString: _todayDateString,
        items: templates
            .map((t) => RoutineItem(
                id: DateTime.now().microsecondsSinceEpoch.toString() + t,
                title: t))
            .toList(),
      );
      await saveTodayRoutine();
    }
    notifyListeners();
  }

  Future<void> toggleRoutineItem(String id) async {
    if (_todayRoutine == null) return;
    final itemIndex = _todayRoutine!.items.indexWhere((i) => i.id == id);
    if (itemIndex != -1) {
      bool isNowCompleted = !_todayRoutine!.items[itemIndex].isCompleted;
      _todayRoutine!.items[itemIndex].isCompleted = isNowCompleted;

      if (isNowCompleted) {
        _autoLogRoutineQuestions(_todayRoutine!.items[itemIndex].title);
      }

      notifyListeners();
      await saveTodayRoutine();
    }
  }

  Future<void> _autoLogRoutineQuestions(String title) async {
    final match = RegExp(r'^(\d+)\s*(.*)').firstMatch(title.trim());
    if (match != null) {
      final count = int.tryParse(match.group(1) ?? '0') ?? 0;
      if (count > 0) {
        final subject = match.group(2)?.toLowerCase() ?? '';

        int sayisalCount = 0;
        int sozelCount = 0;

        if (subject.contains('geometri') ||
            subject.contains('problem') ||
            subject.contains('sayısal') ||
            subject.contains('matematik') ||
            subject.contains('cebir')) {
          sayisalCount = count;
        } else if (subject.contains('paragraf') ||
            subject.contains('sözel') ||
            subject.contains('türkçe') ||
            subject.contains('anlam')) {
          sozelCount = count;
        }

        if (sayisalCount > 0 || sozelCount > 0) {
          await addManualLog(sozelCount, sayisalCount);
        }
      }
    }
  }

  Future<void> addRoutineTemplate(String title) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> templates = prefs.getStringList('routine_templates') ??
        [
          "30 Problem",
          "30 Paragraf",
          "30 Geometri",
          "10 Sözel Mantık",
          "10 Sayısal Mantık"
        ];
    templates.add(title);
    await prefs.setStringList('routine_templates', templates);

    if (_todayRoutine != null) {
      _todayRoutine!.items.add(RoutineItem(
          id: DateTime.now().microsecondsSinceEpoch.toString(), title: title));
      await saveTodayRoutine();
    }
    notifyListeners();
  }

  Future<void> removeRoutineTemplate(String id, String title) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> templates = prefs.getStringList('routine_templates') ??
        [
          "30 Problem",
          "30 Paragraf",
          "30 Geometri",
          "10 Sözel Mantık",
          "10 Sayısal Mantık"
        ];
    templates.remove(title);
    await prefs.setStringList('routine_templates', templates);

    if (_todayRoutine != null) {
      _todayRoutine!.items.removeWhere((i) => i.id == id);
      await saveTodayRoutine();
    }
    notifyListeners();
  }

  Future<void> saveTodayRoutine() async {
    if (_todayRoutine == null) return;
    final prefs = await SharedPreferences.getInstance();
    String todayKey = 'routine_${_todayRoutine!.dateString}';
    await prefs.setString(todayKey, jsonEncode(_todayRoutine!.toJson()));
  }

  Future<void> resetAllData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('study_sessions');
    await prefs.remove('routine_templates');
    await prefs.remove('completed_topics');
    await prefs.remove('current_streak');
    await prefs.remove('longest_streak');

    // Temizle rutin gününü
    String todayKey = 'routine_$_todayDateString';
    await prefs.remove(todayKey);

    _sessions.clear();
    _completedTopics.clear();
    _currentStreak = 0;
    _longestStreak = 0;

    // Yeniden yükleyip boş güncel rutini oluştur
    await loadRoutines();

    notifyListeners();
  }
}
