import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/deneme_kaydi.dart';

class DenemeProvider with ChangeNotifier {
  List<DenemeKaydi> _denemeler = [];
  List<DenemeKaydi> get denemeler => List.unmodifiable(_denemeler);

  DenemeProvider() {
    _loadDenemeler();
  }

  Future<void> _loadDenemeler() async {
    final prefs = await SharedPreferences.getInstance();
    final String? json = prefs.getString('deneme_kayitlari');
    if (json != null) {
      final List<dynamic> decoded = jsonDecode(json);
      _denemeler = decoded
          .map((e) => DenemeKaydi.fromJson(e as Map<String, dynamic>))
          .toList();
      _denemeler.sort((a, b) => b.tarih.compareTo(a.tarih));
      notifyListeners();
    }
  }

  Future<void> _saveDenemeler() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(_denemeler.map((e) => e.toJson()).toList());
    await prefs.setString('deneme_kayitlari', encoded);
  }

  Future<void> denemeleriKaydet(DenemeKaydi kayit) async {
    _denemeler.insert(0, kayit);
    notifyListeners();
    await _saveDenemeler();
  }

  Future<void> denemeleriSil(String id) async {
    _denemeler.removeWhere((d) => d.id == id);
    notifyListeners();
    await _saveDenemeler();
  }

  double get ortalamaToplamNet {
    if (_denemeler.isEmpty) return 0;
    return _denemeler.map((d) => d.toplamNet).reduce((a, b) => a + b) /
        _denemeler.length;
  }

  double get enYuksekNet {
    if (_denemeler.isEmpty) return 0;
    return _denemeler.map((d) => d.toplamNet).reduce((a, b) => a > b ? a : b);
  }

  double get gelisimTrend {
    if (_denemeler.length < 2) return 0;
    final first = _denemeler[_denemeler.length - 1].toplamNet;
    final last = _denemeler[0].toplamNet;
    return last - first;
  }

  String onerilAd() => 'Deneme ${_denemeler.length + 1}';
}
