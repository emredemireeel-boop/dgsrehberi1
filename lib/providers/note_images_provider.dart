import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import '../models/note_image_item.dart';

class NoteImagesProvider with ChangeNotifier {
  List<NoteImageItem> _items = [];
  List<NoteImageItem> get items => _items;

  NoteImagesProvider() {
    loadItems();
  }

  Future<String> getNoteImagesDirectoryPath() async {
    final dir = await getApplicationDocumentsDirectory();
    final notesDir = Directory(p.join(dir.path, 'DGSRehberi_Notlar'));
    if (!await notesDir.exists()) {
      await notesDir.create(recursive: true);
    }
    return notesDir.path;
  }

  Future<void> loadItems() async {
    try {
      final dirPath = await getNoteImagesDirectoryPath();
      final dir = Directory(dirPath);
      final metaFile = File(p.join(dirPath, 'metadata.json'));

      Map<String, dynamic> metadataMap = {};
      if (await metaFile.exists()) {
        final content = await metaFile.readAsString();
        if (content.isNotEmpty) {
          metadataMap = jsonDecode(content) as Map<String, dynamic>;
        }
      }

      final imageFiles = dir
          .listSync()
          .whereType<File>()
          .where((f) =>
              f.path.toLowerCase().endsWith('.png') ||
              f.path.toLowerCase().endsWith('.jpg') ||
              f.path.toLowerCase().endsWith('.jpeg'))
          .toList();

      List<NoteImageItem> loaded = [];
      bool changed = false;

      for (var f in imageFiles) {
        if (metadataMap.containsKey(f.path)) {
          loaded.add(NoteImageItem.fromJson(
              metadataMap[f.path] as Map<String, dynamic>));
        } else {
          final newItem = NoteImageItem(
            filePath: f.path,
            createdAt: f.lastModifiedSync(),
          );
          loaded.add(newItem);
          metadataMap[f.path] = newItem.toJson();
          changed = true;
        }
      }

      // Silinmiş dosyaların stale key'lerini temizle
      final activeKeys = imageFiles.map((f) => f.path).toSet();
      final stale =
          metadataMap.keys.where((k) => !activeKeys.contains(k)).toList();
      for (final k in stale) {
        metadataMap.remove(k);
        changed = true;
      }

      _items = loaded;
      _items.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      if (changed) {
        await _saveMetaFile(metaFile);
      }

      notifyListeners();
    } catch (e) {
      debugPrint('NoteImages yüklenirken hata: $e');
    }
  }

  Future<void> _saveMetaFile(File metaFile) async {
    final map = <String, dynamic>{};
    for (var item in _items) {
      map[item.filePath] = item.toJson();
    }
    await metaFile.writeAsString(jsonEncode(map));
  }

  Future<void> _saveMetadata() async {
    final dirPath = await getNoteImagesDirectoryPath();
    final metaFile = File(p.join(dirPath, 'metadata.json'));
    await _saveMetaFile(metaFile);
  }

  Future<void> updateItem(NoteImageItem item) async {
    final idx = _items.indexWhere((i) => i.filePath == item.filePath);
    if (idx != -1) {
      _items[idx] = item;
      await _saveMetadata();
      notifyListeners();
    }
  }

  Future<void> deleteItem(NoteImageItem item) async {
    try {
      final file = File(item.filePath);
      if (await file.exists()) await file.delete();
      _items.removeWhere((i) => i.filePath == item.filePath);
      await _saveMetadata();
      notifyListeners();
    } catch (e) {
      debugPrint('Not resmi silinirken hata: $e');
    }
  }
}
