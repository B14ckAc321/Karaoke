import 'dart:developer' as developer;

/// Represents the severity level of a log message.
enum LogLevel {
  /// Log level for all information like the content of variables, list etc...
  verbose,

  /// Log level for debugging information.
  debug,

  /// Log level for general informational messages.
  info,

  /// Log level for warnings that do not necessarily indicate an error.
  ///
  /// Should be shown to the user. (e.g. "No internet connection" or "Invalid credentials")
  warning,

  /// Log level for errors that indicate a failure in the program.
  ///
  /// Should not be shown to the user and goes to Sentry.
  error,
}

/// A utility class for logging messages with various log levels.
final class Logger {

  /// A flag that determines if debug logs should be shown.
  ///
  /// When set to `false`, debug-level logs will not be displayed.
  static LogLevel _logLevel = LogLevel.info;

  /// Sets the log level for the logger.
  ///
  /// The log level determines which logs are displayed.
  /// [LogLevel.verbose] will display all logs.
  /// [LogLevel.debug] will display all logs except verbose logs.
  /// [LogLevel.info] will display all logs except verbose and debug logs.
  static set logLevel(LogLevel level) {
    // LogLevel should be verbose, debug or info
    if (level != LogLevel.verbose && level != LogLevel.debug && level != LogLevel.info) {
      throw ArgumentError('Invalid log level: $level, must be either ${LogLevel.verbose.name}, ${LogLevel.debug.name} or ${LogLevel.info.name}');
    }
    _logLevel = level;
  }

  /// Logs a message with the specified parameters.
  ///
  /// The [message] parameter is the content to be logged.
  ///
  /// The [name] parameter specifies the source or category of the log.
  ///
  /// The [level] parameter defines the log level (e.g., `LogLevel.debug`).
  /// Defaults to `LogLevel.debug`.
  ///
  /// The [error] parameter, if provided, includes the error object in the log.
  ///
  /// The [stackTrace] parameter, if provided, includes the stack trace in the log.
  static void log(
      String message, {
        required String name,
        LogLevel level = LogLevel.debug,
        Object? error,
        StackTrace? stackTrace,
      }) {
    final timestamp = DateTime.now().toIso8601String();

    // Automatically set the log level to error if an error or stack trace is present.
    if ((error != null || stackTrace != null) && level.index < LogLevel.warning.index) {
      level = LogLevel.error;
    }

    // Skip logging when the log level is lower than the current log level.
    if (level.index < _logLevel.index) {
      return;
    }

    // Use the `developer.log` function for output.
    developer.log(
      message,
      name: '[${_getLevelString(level)}] [$timestamp] $name',
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// Logs an info message with the specified parameters.
  static void info(String message, {
        required String name
  }) {
    return log(message, name: name, level: LogLevel.info);
  }

  /// Logs a verbose message with the specified parameters.
  static void verbose(String message, {
        required String name
  }) {
    return log(message, name: name, level: LogLevel.verbose);
  }

  /// Logs a debug message with the specified parameters.
  static void debug(String message, {
        required String name
  }) {
    return log(message, name: name, level: LogLevel.debug);
  }

  /// Logs a warning message with the specified parameters.
  static void warning(String message, {
        required String name,
        Object? error,
        StackTrace? stackTrace,
  }) {
    return log(message, name: name, level: LogLevel.warning);
  }

  /// Logs an error message with the specified parameters.
  static void error(String message, {
        required String name,
        Object? error,
        StackTrace? stackTrace,
  }) {
    return log(message, name: name, level: LogLevel.error);
  }

  /// Converts a [LogLevel] to its corresponding string representation.
  ///
  /// The string representation is returned in uppercase format.
  ///
  /// For example, `LogLevel.debug` will be returned as `DEBUG`.
  static String _getLevelString(LogLevel level) {
    return level.name.toUpperCase();
  }
}
