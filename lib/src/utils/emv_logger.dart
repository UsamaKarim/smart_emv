import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

/// Configurable logging utility for the EMV NFC process.
class EmvLogger {
  /// Whether logging is currently enabled.
  final bool enabled;

  /// Creates an [EmvLogger] with configured [enabled] status.
  const EmvLogger({this.enabled = kDebugMode});

  /// Logs a message to the console if logging is enabled.
  void log(
    String message, {
    String name = 'SmartEmv',
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (enabled) {
      developer.log(message, name: name, error: error, stackTrace: stackTrace);
    }
  }

  /// Logs the transmission of an APDU command and response.
  void logApdu(String command, String response) {
    if (enabled) {
      log('--> APDU TX: $command', name: 'SmartEmv.APDU');
      log('<-- APDU RX: $response', name: 'SmartEmv.APDU');
    }
  }
}
