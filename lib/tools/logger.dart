import 'package:logger/logger.dart';

final appLogger = Logger(
  printer: PrettyPrinter(
    methodCount: 1, // Number of method calls to be displayed
    errorMethodCount: 8, // Number of method calls if stacktrace is provided
    lineLength: 120, // Width of the output
    colors: true, // Colorful log messages
    printEmojis: true, // Print an emoji for each log message
    dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart, // Should each log print contain a timestamp
  ),
);

// You can also create a simple logger
// final appLogger = Logger();

void logDebug(dynamic message) {
  appLogger.d(message);
}

void logInfo(dynamic message) {
  appLogger.i(message);
}

void logWarning(dynamic message) {
  appLogger.w(message);
}

void logError(dynamic message, [dynamic error, StackTrace? stackTrace]) {
  appLogger.e(message, error: error, stackTrace: stackTrace);
}

void logVerbose(dynamic message) {
  appLogger.t(message);
}
