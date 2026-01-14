import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'backend_host_stub.dart' if (dart.library.html) 'backend_host_web.dart';

class ThemeService with ChangeNotifier {
  ThemeService._internal();
  static final ThemeService _instance = ThemeService._internal();
  static ThemeService getInstance() => _instance;

  late final String baseUrl;
  Map<String, String> _settings = {};

  Map<String, String> get settings => _settings;

  String get primaryColor => _settings['primaryColor'] ?? '#FF6B9D';
  String get secondaryColor => _settings['secondaryColor'] ?? '#C44569';
  String get backgroundColor => _settings['backgroundColor'] ?? '#0b0f1a';
  String get cardColor => _settings['cardColor'] ?? '#11182b';
  String get textColor => _settings['textColor'] ?? '#FFFFFF';
  String get accentColor => _settings['accentColor'] ?? '#FFD93D';
  String get fontFamily => _settings['fontFamily'] ?? 'Roboto';
  double get titleFontSize => double.tryParse(_settings['titleFontSize'] ?? '28') ?? 28;
  double get scoreFontSize => double.tryParse(_settings['scoreFontSize'] ?? '32') ?? 32;
  double get timerFontSize => double.tryParse(_settings['timerFontSize'] ?? '64') ?? 64;
  String? get backgroundImageUrl => _settings['backgroundImageUrl'];
  String? get logoImageUrl => _settings['logoImageUrl'];

  Future<void> init() async {
    final host = getBackendHost();
    baseUrl = 'http://$host:8082';
    await loadSettings();
  }

  Future<void> loadSettings() async {
    try {
      final resp = await http.get(Uri.parse('$baseUrl/theme'));
      if (resp.statusCode == 200) {
        _settings = Map<String, String>.from(jsonDecode(resp.body) as Map);
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> saveSettings(Map<String, String> newSettings) async {
    _settings = {..._settings, ...newSettings};
    try {
      await http.post(Uri.parse('$baseUrl/theme'), headers: {'Content-Type': 'application/json'}, body: jsonEncode(_settings));
      notifyListeners();
    } catch (_) {}
  }

  Future<String?> uploadImage(List<int> imageBytes, String filename) async {
    try {
      final uri = Uri.parse('$baseUrl/images');
      final request = http.MultipartRequest('POST', uri);
      request.files.add(http.MultipartFile.fromBytes('image', imageBytes, filename: filename));
      final resp = await request.send();
      if (resp.statusCode == 200) {
        final body = await resp.stream.bytesToString();
        final json = jsonDecode(body) as Map<String, dynamic>;
        return json['url'] as String?;
      }
    } catch (_) {}
    return null;
  }

  Future<List<Map<String, String>>> listImages() async {
    try {
      final resp = await http.get(Uri.parse('$baseUrl/images'));
      if (resp.statusCode == 200) {
        final list = jsonDecode(resp.body) as List;
        return list.map((e) => Map<String, String>.from(e as Map)).toList();
      }
    } catch (_) {}
    return [];
  }

  Future<void> deleteImage(String filename) async {
    try {
      await http.delete(Uri.parse('$baseUrl/images/$filename'));
      await loadSettings();
    } catch (_) {}
  }
}
