import 'dart:async';
import 'package:flutter/material.dart';
import 'package:karaoke/src/repositories/example_repository.dart';
import 'package:karaoke/src/utils/logger.dart';
import 'package:karaoke/src/services/backend_service.dart';
import 'package:karaoke/src/services/theme_service.dart';

final class AppService with ChangeNotifier {
  AppService._internal();
  factory AppService.getInstance() => _instance;
  static final AppService _instance = AppService._internal();

  bool _initialized = false;
  bool get initialized => _initialized;

  set initialized(bool value) {
    _initialized = value;
    notifyListeners();
  }

  /// This method is called when the app starts.
  /// It initializes all the services and repositories.
  Future<void> onAppStart(BuildContext context) async {
    // Await for all the services to be initialized
    // All services or repositories instances in this function will
    try {
      await Future.wait([
        ExampleRepository.getInstance().init(),
        BackendService.getInstance().init().timeout(const Duration(seconds: 10)),
        ThemeService.getInstance().init(),
      ]).timeout(const Duration(seconds: 15));
    } catch (e) {
      Logger.info('Error during initialization (continuing anyway): $e', name: 'AppService.onAppStart');
      // Continue anyway - don't block the app from loading
    }

    // Other initialization code can go here

    Logger.info('Application initialization complete', name: 'AppService.onAppStart');
    _initialized = true;
    notifyListeners();
  }
}