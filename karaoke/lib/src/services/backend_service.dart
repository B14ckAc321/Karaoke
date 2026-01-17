import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'backend_host_stub.dart' if (dart.library.html) 'backend_host_web.dart';

class SongModel {
  final String id;
  final String title;
  final String? artist;
  final int score;
  final String? youtubeUrl;
  const SongModel({required this.id, required this.title, this.artist, required this.score, this.youtubeUrl});
  static SongModel fromJson(Map<String, dynamic> j) => SongModel(
    id: j['id'] as String,
    title: j['title'] as String,
    artist: j['artist'] as String?,
    score: (j['score'] as num).toInt(),
    youtubeUrl: j['youtubeUrl'] as String?,
  );
}

class TimerModel {
  final int durationSeconds;
  final int remainingSeconds;
  final bool isRunning;
  const TimerModel({required this.durationSeconds, required this.remainingSeconds, required this.isRunning});
  static TimerModel fromJson(Map<String, dynamic> j) => TimerModel(
    durationSeconds: (j['durationSeconds'] as num).toInt(),
    remainingSeconds: (j['remainingSeconds'] as num).toInt(),
    isRunning: j['isRunning'] as bool,
  );
}

class AppData {
  final List<SongModel> songs;
  final TimerModel timer;
  const AppData({required this.songs, required this.timer});
}

class BackendService with ChangeNotifier {
  BackendService._internal();
  static final BackendService _instance = BackendService._internal();
  static BackendService getInstance() => _instance;

  late final String baseUrl;
  io.Socket? _socket;
  AppData? _state;
  AppData? get state => _state;
  
  bool _isConnected = false;
  bool get isConnected => _isConnected;
  String _connectionStatus = 'Connecting...';
  String get connectionStatus => _connectionStatus;

  String _getCurrentOrigin() {
    // In production, always use HTTPS (Railway provides HTTPS)
    // Get the hostname and construct the URL with HTTPS
    final host = getBackendHost();
    return 'https://$host';
  }

  Future<void> init() async {
    // Use full URLs to avoid go_router intercepting API calls
    // Check if we're in a browser and can detect the protocol
    final host = getBackendHost();
    // For Railway/production: use same origin with current protocol
    // For local dev: use explicit port 8082
    final isLocalDev = host == 'localhost' || host == '127.0.0.1';
    
    if (isLocalDev) {
      baseUrl = 'http://$host:8082';
    } else {
      // In production, use current origin (same protocol and host)
      // This ensures HTTPS is used if the site is HTTPS
      // Use window.location to get the current protocol
      if (kIsWeb) {
        // Get protocol and host from current page URL
        // This will be resolved at compile time via conditional import
        baseUrl = _getCurrentOrigin();
      } else {
        baseUrl = 'https://$host';
      }
    }
    
    debugPrint('Backend baseUrl: $baseUrl');
    
    // For Socket.IO, use the baseUrl
    _connectSocket(baseUrl);
    // Warm-up: fetch state once via REST in case socket is delayed
    try {
      _updateConnectionStatus('Testing HTTP connection...', false);
      final stateUrl = '$baseUrl/state';
      debugPrint('Fetching initial state from: $stateUrl');
      final resp = await http.get(Uri.parse(stateUrl)).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw TimeoutException('Connection timeout'),
      );
      debugPrint('State response: ${resp.statusCode}');
      if (resp.statusCode == 200) {
        final json = jsonDecode(resp.body) as Map<String, dynamic>;
        debugPrint('State received: ${json['songs']?.length ?? 0} songs');
        _applyState(json);
        _updateConnectionStatus('HTTP connection OK, waiting for WebSocket...', false);
      } else {
        debugPrint('HTTP error: ${resp.statusCode} - ${resp.body}');
        _updateConnectionStatus('HTTP error: ${resp.statusCode}', false);
        // Set empty state so UI doesn't show loading forever
        _applyState({'songs': <dynamic>[], 'timer': {'durationSeconds': 60, 'remainingSeconds': 60, 'isRunning': false}});
      }
    } catch (e) {
      debugPrint('Failed to fetch initial state: $e');
      _updateConnectionStatus('HTTP connection failed: $e', false);
      // Set empty state so UI doesn't show loading forever
      _applyState({'songs': <dynamic>[], 'timer': {'durationSeconds': 60, 'remainingSeconds': 60, 'isRunning': false}});
    }
  }

  void _connectSocket([String? url]) {
    // If url is null/empty, Socket.IO will use current origin
    _updateConnectionStatus('Connecting to backend...', false);
    _socket = io.io(
      url ?? '',
      io.OptionBuilder()
          .setTransports(['websocket', 'polling'])
          .enableReconnection()
          .disableAutoConnect()
          .build(),
    );
    _socket!.on('state:update', (data) {
      if (data is Map) _applyState(jsonDecode(jsonEncode(data)) as Map<String, dynamic>);
    });
    
    // Listen for immediate score updates (without reordering)
    _socket!.on('score:updated', (data) {
      if (data is Map) {
        final id = data['id'] as String?;
        final score = data['score'] as num?;
        if (id != null && score != null && _state != null) {
          // Update score immediately without reordering
          final songIndex = _state!.songs.indexWhere((s) => s.id == id);
          if (songIndex >= 0) {
            final updatedSong = SongModel(
              id: _state!.songs[songIndex].id,
              title: _state!.songs[songIndex].title,
              artist: _state!.songs[songIndex].artist,
              score: score.toInt(),
              youtubeUrl: _state!.songs[songIndex].youtubeUrl,
            );
            _state = AppData(
              songs: [
                ..._state!.songs.sublist(0, songIndex),
                updatedSong,
                ..._state!.songs.sublist(songIndex + 1),
              ],
              timer: _state!.timer,
            );
            notifyListeners();
          }
        }
      }
    });
    
    _socket!.on('connect', (_) {
      debugPrint('Socket.IO connected');
      _updateConnectionStatus('Connected', true);
    });
    _socket!.on('disconnect', (_) {
      debugPrint('Socket.IO disconnected');
      _updateConnectionStatus('Disconnected', false);
    });
    _socket!.on('error', (err) {
      debugPrint('Socket.IO error: $err');
      _updateConnectionStatus('Connection error: $err', false);
    });
    _socket!.on('connect_error', (err) {
      debugPrint('Socket.IO connect_error: $err');
      _updateConnectionStatus('Connection failed: $err', false);
    });
    _socket!.connect();
  }
  
  void _updateConnectionStatus(String status, bool connected) {
    _connectionStatus = status;
    _isConnected = connected;
    notifyListeners();
  }

  void _applyState(Map<String, dynamic> json) {
    try {
      final songsList = json['songs'];
      final songs = (songsList is List ? songsList : <dynamic>[])
          .cast<Map<String, dynamic>>()
          .map(SongModel.fromJson)
          .toList();
      final timer = TimerModel.fromJson(json['timer'] as Map<String, dynamic>);
      _state = AppData(songs: songs, timer: timer);
      debugPrint('State applied: ${songs.length} songs');
      notifyListeners();
    } catch (e) {
      debugPrint('Error applying state: $e');
      debugPrint('State JSON: $json');
      // Set empty state on error so UI doesn't show loading forever
      _state = AppData(
        songs: [],
        timer: TimerModel(durationSeconds: 60, remainingSeconds: 60, isRunning: false),
      );
      notifyListeners();
    }
  }

  // Commands
  Future<void> addSong({required String title}) async {
    await http.post(Uri.parse('$baseUrl/songs'), headers: {'Content-Type': 'application/json'}, body: jsonEncode({
      'title': title,
    }));
  }

  Future<void> setYoutubeUrl({required String id, String? youtubeUrl}) async {
    await http.post(Uri.parse('$baseUrl/songs/$id/url'), headers: {'Content-Type': 'application/json'}, body: jsonEncode({'youtubeUrl': youtubeUrl}));
  }

  Future<void> updateSong({required String id, String? title, String? artist}) async {
    await http.post(Uri.parse('$baseUrl/songs/$id/update'), headers: {'Content-Type': 'application/json'}, body: jsonEncode({
      if (title != null) 'title': title,
      if (artist != null) 'artist': artist,
    }));
  }

  void updateScore(String id, {int? delta, int? set}) {
    _socket?.emit('score:update', {"id": id, if (delta != null) "delta": delta, if (set != null) "set": set});
  }

  void controlTimer(String action, {int? durationSeconds}) {
    _socket?.emit('timer:control', {"action": action, if (durationSeconds != null) "durationSeconds": durationSeconds});
  }

  Future<void> deleteSong(String id) async {
    await http.delete(Uri.parse('$baseUrl/songs/$id'));
  }
}


