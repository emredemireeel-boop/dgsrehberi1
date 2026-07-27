import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import '../models/question_item.dart';

class QuestionsProvider with ChangeNotifier {
  List<QuestionItem> _questions = [];

  List<QuestionItem> get questions => _questions;

  // Bugün tekrar edilmesi gereken soruları döndürür
  List<QuestionItem> get dueQuestions {
    return _questions.where((q) => q.isDueToday()).toList();
  }

  QuestionsProvider() {
    loadQuestions();
  }

  Future<void> loadQuestions() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final questionsDir = Directory(p.join(dir.path, 'DGSRehberi_Sorular'));
      if (!await questionsDir.exists()) {
        await questionsDir.create(recursive: true);
      }

      final metaFile = File(p.join(questionsDir.path, 'metadata.json'));
      Map<String, dynamic> metadataMap = {};
      if (await metaFile.exists()) {
        final content = await metaFile.readAsString();
        if (content.isNotEmpty) {
          metadataMap = jsonDecode(content) as Map<String, dynamic>;
        }
      }

      final files = questionsDir.listSync();
      final imageFiles = files.whereType<File>().where((f) {
        final lower = f.path.toLowerCase();
        return lower.endsWith('.png') ||
            lower.endsWith('.jpg') ||
            lower.endsWith('.jpeg');
      }).toList();

      List<QuestionItem> loadedItems = [];
      bool metadataChanged = false;

      // Her resim dosyasını kontrol et
      for (var f in imageFiles) {
        if (metadataMap.containsKey(f.path)) {
          loadedItems.add(QuestionItem.fromJson(metadataMap[f.path]));
        } else {
          // Resim var ama meta-verisi yok (yeni çekilmiş ekran görüntüsü)
          final newItem = QuestionItem(
            filePath: f.path,
            createdAt: f.lastModifiedSync(),
          );
          loadedItems.add(newItem);
          metadataMap[f.path] = newItem.toJson();
          metadataChanged = true;
          // we will save just once at the end.
        }
      }

      _questions = loadedItems;
      // En yeni önce
      _questions.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      if (metadataChanged ||
          loadedItems.length > metadataMap.keys.length ||
          loadedItems.length < metadataMap.keys.length) {
        await _saveMetadataSync(metaFile);
      }

      notifyListeners();
    } catch (e) {
      debugPrint("Soruları yüklerken hata oluştu: $e");
    }
  }

  Future<void> _saveMetadataSync(File metaFile) async {
    Map<String, dynamic> outputMap = {};
    for (var q in _questions) {
      outputMap[q.filePath] = q.toJson();
    }
    await metaFile.writeAsString(jsonEncode(outputMap));
  }

  Future<void> _saveMetadata() async {
    final dir = await getApplicationDocumentsDirectory();
    final metaFile =
        File(p.join(dir.path, 'DGSRehberi_Sorular', 'metadata.json'));
    await _saveMetadataSync(metaFile);
  }

  Future<void> updateQuestion(QuestionItem item) async {
    final index = _questions.indexWhere((q) => q.filePath == item.filePath);
    if (index != -1) {
      _questions[index] = item;
      await _saveMetadata();
      notifyListeners();
    }
  }

  Future<void> deleteQuestion(QuestionItem item) async {
    try {
      final file = File(item.filePath);
      if (await file.exists()) {
        await file.delete();
      }
      _questions.removeWhere((q) => q.filePath == item.filePath);
      await _saveMetadata();
      notifyListeners();
    } catch (e) {
      debugPrint("Soru silinirken hata oluştu: $e");
    }
  }

  Future<String> getQuestionsDirectoryPath() async {
    final dir = await getApplicationDocumentsDirectory();
    final questionsDir = Directory(p.join(dir.path, 'DGSRehberi_Sorular'));
    if (!await questionsDir.exists()) {
      await questionsDir.create(recursive: true);
    }
    return questionsDir.path;
  }
}
