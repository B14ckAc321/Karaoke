import 'dart:io';

import 'package:karaoke/src/utils/logger.dart';

enum EnvironmentEnum {
  development,
  test,
  staging,
  integration,
  production,
}


final class Environment {
  factory Environment.getInstance() => _instance;
  // Singleton instance
  Environment._internal() {
    _checkIfCorrectVariables();
  }
  static final Environment _instance = Environment._internal();

  // TODO: Declare your own environment variables here and in the .env file
  static const String _environmentKey = 'ENVIRONMENT';
  static const String _apiUrlKey = 'API_URL';

  final String apiUrl = const String.fromEnvironment(_apiUrlKey);
  late final EnvironmentEnum environment;

  void _checkIfCorrectVariables() {
    const String environmentString = String.fromEnvironment(_environmentKey);
    if (environmentString.isEmpty) _exitBecauseOfEmptyKey(key: _environmentKey, exitCode: 1);
    if (!EnvironmentEnum.values.any((environment) => environment.name == environmentString)) {
      Logger.log(
        'FATAL! $_environmentKey value is invalid. Valid values are: ${EnvironmentEnum.values.join(', ')}',
        name: 'Env._checkIfCorrectVariables',
        level: LogLevel.error,
      );
      exit(11);
    }

    environment = EnvironmentEnum.values.firstWhere((environment) => environment.name == environmentString);
    if (apiUrl.isEmpty) {
      _exitBecauseOfEmptyKey(key: _apiUrlKey, exitCode: 2);
    }
    // TODO: Check other environment variables here
  }

  void _exitBecauseOfEmptyKey({required String key, required int exitCode}) {
    Logger.log(
      'FATAL! $key key is not set or empty.',
      name: 'Env._checkIfCorrectVariables',
      level: LogLevel.error,
    );
    exit(exitCode); // The handling of exit codes is platform specific
  }
}
