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

  Future<void> init() async {
    final host = getBackendHost();
    baseUrl = 'http://$host:8082';
    _connectSocket();
    // Warm-up: fetch state once via REST in case socket is delayed
    try {
      final resp = await http.get(Uri.parse('$baseUrl/state'));
      if (resp.statusCode == 200) {
        final json = jsonDecode(resp.body) as Map<String, dynamic>;
        _applyState(json);
      }
    } catch (_) {}
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
    _socket!.on('state:update', (data) {
      if (data is Map) _applyState(jsonDecode(jsonEncode(data)) as Map<String, dynamic>);
    });
    _socket!.connect();
  }

  void _applyState(Map<String, dynamic> json) {
    final songs = ((json['songs'] as List).cast<Map<String, dynamic>>()).map(SongModel.fromJson).toList();
    final timer = TimerModel.fromJson(json['timer'] as Map<String, dynamic>);
    _state = AppData(songs: songs, timer: timer);
    notifyListeners();
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

  void updateScore(String id, {int? delta, int? set}) {
    _socket?.emit('score:update', {"id": id, if (delta != null) "delta": delta, if (set != null) "set": set});
  }

  void controlTimer(String action, {int? durationSeconds}) {
    _socket?.emit('timer:control', {"action": action, if (durationSeconds != null) "durationSeconds": durationSeconds});
  }
}


