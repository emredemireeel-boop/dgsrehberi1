import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/plan_block.dart';
import '../models/note_item.dart';

class PlanProvider with ChangeNotifier {
  List<PlanBlock> _blocks = [];
  List<NoteItem> _notes = [];

  List<PlanBlock> get allBlocks => _blocks;
  List<NoteItem> get allNotes => _notes;

  PlanProvider() {
    _load();
  }

  // ── PLAN BLOCKS ──────────────────────────────────────────────────────────

  List<PlanBlock> getBlocksForDate(String dateKey) {
    return _blocks.where((b) => b.dateKey == dateKey).toList()
      ..sort((a, b) => (a.startHour * 60 + a.startMinute)
          .compareTo(b.startHour * 60 + b.startMinute));
  }

  int minutesForDay(String dateKey) {
    return _blocks
        .where((b) => b.dateKey == dateKey)
        .fold(0, (sum, b) => sum + b.durationMinutes);
  }

  Map<String, int> minutesPerDayForMonth(int year, int month) {
    final result = <String, int>{};
    for (final b in _blocks) {
      if (b.dateKey.startsWith(
          '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}')) {
        result[b.dateKey] = (result[b.dateKey] ?? 0) + b.durationMinutes;
      }
    }
    return result;
  }

  Future<void> addBlock(PlanBlock block) async {
    _blocks.add(block);
    notifyListeners();
    await _saveBlocks();
  }

  Future<void> removeBlock(String id) async {
    _blocks.removeWhere((b) => b.id == id);
    notifyListeners();
    await _saveBlocks();
  }

  Future<void> toggleBlock(String id) async {
    final idx = _blocks.indexWhere((b) => b.id == id);
    if (idx != -1) {
      _blocks[idx].isCompleted = !_blocks[idx].isCompleted;
      notifyListeners();
      await _saveBlocks();
    }
  }

  // ── NOTES ────────────────────────────────────────────────────────────────

  List<NoteItem> get sortedNotes {
    final pinned = _notes.where((n) => n.isPinned).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final unpinned = _notes.where((n) => !n.isPinned).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return [...pinned, ...unpinned];
  }

  Future<void> addNote(NoteItem note) async {
    _notes.add(note);
    notifyListeners();
    await _saveNotes();
  }

  Future<void> removeNote(String id) async {
    _notes.removeWhere((n) => n.id == id);
    notifyListeners();
    await _saveNotes();
  }

  Future<void> togglePin(String id) async {
    final idx = _notes.indexWhere((n) => n.id == id);
    if (idx != -1) {
      _notes[idx].isPinned = !_notes[idx].isPinned;
      notifyListeners();
      await _saveNotes();
    }
  }

  // ── PERSISTENCE ──────────────────────────────────────────────────────────

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();

    final blocksJson = prefs.getString('plan_blocks');
    if (blocksJson != null) {
      final List<dynamic> decoded = jsonDecode(blocksJson);
      _blocks = decoded.map((e) => PlanBlock.fromJson(e)).toList();
    }

    final notesJson = prefs.getString('plan_notes');
    if (notesJson != null) {
      final List<dynamic> decoded = jsonDecode(notesJson);
      _notes = decoded.map((e) => NoteItem.fromJson(e)).toList();
    }

    notifyListeners();
  }

  Future<void> _saveBlocks() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'plan_blocks', jsonEncode(_blocks.map((b) => b.toJson()).toList()));
  }

  Future<void> _saveNotes() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'plan_notes', jsonEncode(_notes.map((n) => n.toJson()).toList()));
  }

  Future<void> resetAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('plan_blocks');
    await prefs.remove('plan_notes');
    _blocks.clear();
    _notes.clear();
    notifyListeners();
  }
}
