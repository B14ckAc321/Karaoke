import 'package:karaoke/src/services/backend_service.dart';

final class SongRepository {
  SongRepository._internal();
  static final SongRepository _instance = SongRepository._internal();
  static SongRepository getInstance() => _instance;

  final BackendService _backend = BackendService.getInstance();

  Future<void> init() async {}

  Future<void> addSong({required String title}) =>
      _backend.addSong(title: title);

  Future<void> setYoutubeUrl({required String id, String? youtubeUrl}) => _backend.setYoutubeUrl(id: id, youtubeUrl: youtubeUrl);

  void updateScore(String id, {int? delta, int? set}) => _backend.updateScore(id, delta: delta, set: set);
  void controlTimer(String action, {int? durationSeconds}) => _backend.controlTimer(action, durationSeconds: durationSeconds);
  Future<void> deleteSong(String id) => _backend.deleteSong(id);
}


