import 'package:karaoke/src/utils/logger.dart';

final class ExampleRepository {
  static final ExampleRepository _instance = ExampleRepository._internal();
  ExampleRepository._internal();
  factory ExampleRepository.getInstance() => _instance;

  Future<void> init() async {
    // Simulate some initialization work
    await Future.delayed(const Duration(seconds: 1));

    Logger.info('Example repository successfully initialized', name: 'ExampleRepository.init');
  }
}