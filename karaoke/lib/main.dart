import 'package:flutter/material.dart';
import 'package:karaoke/src/utils/logger.dart';

import 'package:karaoke/src/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // TODO: Chose the log level
  Logger.logLevel = LogLevel.debug;
  runApp(const Karaoke());
}