import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'backend_host_stub.dart' if (dart.library.html) 'backend_host_web.dart' show getBackendHost;

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
    // Use same URL logic as BackendService
    final host = getBackendHost();
    final isLocalDev = host == 'localhost' || host == '127.0.0.1';
    
    if (isLocalDev) {
      baseUrl = 'http://$host:8082';
    } else {
      // In production, use HTTPS (same as BackendService)
      baseUrl = 'https://$host';
    }
    
    debugPrint('ThemeService baseUrl: $baseUrl');
    
    // Load settings first, then connect socket
    await loadSettings();
    _connectSocket();
  }

  void _connectSocket() {
    debugPrint('Connecting ThemeService Socket.IO to: $baseUrl');
    _socket = io.io(
      baseUrl,
      io.OptionBuilder()
          .setTransports(['websocket', 'polling'])
          .enableReconnection()
          .disableAutoConnect()
          .build(),
    );
    _socket!.on('connect', (_) {
      debugPrint('ThemeService Socket.IO connected');
      // Reload settings when reconnected to ensure we have latest
      loadSettings();
    });
    _socket!.on('disconnect', (_) {
      debugPrint('ThemeService Socket.IO disconnected');
    });
    _socket!.on('error', (err) {
      debugPrint('ThemeService Socket.IO error: $err');
    });
    _socket!.on('theme:update', (data) {
      debugPrint('ThemeService received theme:update event');
      try {
        Map<String, dynamic> settingsMap;
        if (data is Map) {
          settingsMap = Map<String, dynamic>.from(data);
        } else if (data is String) {
          settingsMap = jsonDecode(data) as Map<String, dynamic>;
        } else {
          debugPrint('Unexpected theme:update format, reloading from server');
          loadSettings();
          return;
        }
        _settings = settingsMap.map((key, value) => MapEntry(key, value.toString()));
        debugPrint('Theme settings updated via Socket.IO: ${_settings.length} settings');
        notifyListeners();
      } catch (e) {
        debugPrint('Error processing theme:update: $e, reloading from server');
        // If socket update fails, reload from server
        loadSettings();
      }
    });
    _socket!.connect();
  }

  Future<void> loadSettings() async {
    try {
      debugPrint('Loading theme settings from: $baseUrl/theme');
      final resp = await http.get(Uri.parse('$baseUrl/theme')).timeout(
        const Duration(seconds: 5),
        onTimeout: () => throw TimeoutException('Theme load timeout'),
      );
      if (resp.statusCode == 200) {
        final settingsMap = jsonDecode(resp.body) as Map;
        _settings = Map<String, String>.from(settingsMap);
        debugPrint('Theme settings loaded: ${_settings.length} settings');
        notifyListeners();
      } else {
        debugPrint('Failed to load theme settings: ${resp.statusCode}');
      }
    } catch (e) {
      debugPrint('Error loading theme settings: $e');
    }
  }

  Future<void> saveSettings(Map<String, String> newSettings) async {
    // Merge new settings with existing
    final updatedSettings = {..._settings, ...newSettings};
    debugPrint('Saving theme settings: ${newSettings.keys.join(', ')}');
    try {
      // Send to server
      final resp = await http.post(
        Uri.parse('$baseUrl/theme'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(updatedSettings),
      ).timeout(
        const Duration(seconds: 5),
        onTimeout: () => throw TimeoutException('Theme save timeout'),
      );
      if (resp.statusCode == 200) {
        debugPrint('Theme settings saved successfully');
        // Update local settings immediately
        _settings = updatedSettings;
        notifyListeners();
        // Wait a bit for Socket.IO broadcast, then reload to ensure consistency
        await Future<void>.delayed(const Duration(milliseconds: 200));
        await loadSettings();
      } else {
        debugPrint('Failed to save theme settings: ${resp.statusCode}');
        // If save fails, still update locally
        _settings = updatedSettings;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error saving theme settings: $e');
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
