import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'backend_host_stub.dart' if (dart.library.html) 'backend_host_web.dart';

class ThemeService with ChangeNotifier {
  ThemeService._internal();
  static final ThemeService _instance = ThemeService._internal();
  static ThemeService getInstance() => _instance;

  late final String baseUrl;
  io.Socket? _socket;
  Map<String, String> _settings = {};

  Map<String, String> get settings => _settings;

  String get primaryColor => _settings['primaryColor'] ?? '#FF6B9D';
  String get secondaryColor => _settings['secondaryColor'] ?? '#C44569';
  String get backgroundColor => _settings['backgroundColor'] ?? '#0b0f1a';
  String get cardColor => _settings['cardColor'] ?? '#11182b';
  String get textColor => _settings['textColor'] ?? '#FFFFFF';
  String get accentColor => _settings['accentColor'] ?? '#FFD93D';
  String get buttonColor => _settings['buttonColor'] ?? '#2196F3';
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
    _connectSocket();
  }

  void _connectSocket() {
    _socket = io.io(
      baseUrl,
      io.OptionBuilder()
          .setTransports(['websocket', 'polling'])
          .enableReconnection()
          .disableAutoConnect()
          .build(),
    );
    _socket!.on('connect', (_) {
      // Reload settings when reconnected to ensure we have latest
      loadSettings();
    });
    _socket!.on('theme:update', (data) {
      try {
        Map<String, dynamic> settingsMap;
        if (data is Map) {
          settingsMap = Map<String, dynamic>.from(data);
        } else if (data is String) {
          settingsMap = jsonDecode(data) as Map<String, dynamic>;
        } else {
          // If format is unexpected, reload from server
          loadSettings();
          return;
        }
        _settings = settingsMap.map((key, value) => MapEntry(key, value.toString()));
        notifyListeners();
      } catch (e) {
        // If socket update fails, reload from server
        loadSettings();
      }
    });
    _socket!.connect();
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
    // Merge new settings with existing
    final updatedSettings = {..._settings, ...newSettings};
    try {
      // Send to server
      final resp = await http.post(
        Uri.parse('$baseUrl/theme'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(updatedSettings),
      );
      if (resp.statusCode == 200) {
        // Update local settings
        _settings = updatedSettings;
        // Reload from server to ensure consistency (this will also trigger Socket.IO broadcast)
        await Future<void>.delayed(const Duration(milliseconds: 100));
        await loadSettings();
      } else {
        // If save fails, still update locally
        _settings = updatedSettings;
        notifyListeners();
      }
    } catch (e) {
      // If save fails, still update locally
      _settings = updatedSettings;
      notifyListeners();
    }
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
