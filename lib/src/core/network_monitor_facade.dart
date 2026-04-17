import 'package:flutter/foundation.dart';

import '../data/repositories/in_memory_network_log_repository.dart';
import 'debug_print_network_capture.dart';
import '../domain/entities/network_log_entry.dart';
import '../domain/repositories/network_log_repository.dart';

class NetworkMonitorFacade {
  NetworkMonitorFacade._(this.repository);

  static final NetworkMonitorFacade instance = NetworkMonitorFacade._(
    InMemoryNetworkLogRepository(),
  );

  final NetworkLogRepository repository;

  void ensureCaptureStarted() {
    if (!kDebugMode) {
      return;
    }
    DebugPrintNetworkCapture.instance.start((entry) {
      return repository.addLog(entry);
    });
  }

  Future<void> clear() {
    if (!kDebugMode) {
      return Future<void>.value();
    }
    return repository.clearLogs();
  }

  Future<void> log({
    required String method,
    required String url,
    String? requestBody,
    String? requestHeaders,
    String? responseBody,
    String? responseHeaders,
    int? statusCode,
    int? durationMs,
    String? error,
    bool isMultipart = false,
    String? rawRequest,
    String? rawResponse,
  }) {
    if (!kDebugMode) {
      return Future<void>.value();
    }

    return repository.addLog(
      NetworkLogEntry(
        id: '${DateTime.now().microsecondsSinceEpoch}',
        timestamp: DateTime.now(),
        method: method,
        url: url,
        requestBody: requestBody,
        requestHeaders: requestHeaders,
        responseBody: responseBody,
        responseHeaders: responseHeaders,
        statusCode: statusCode,
        durationMs: durationMs,
        error: error,
        isMultipart: isMultipart,
        rawRequest: rawRequest,
        rawResponse: rawResponse,
      ),
    );
  }
}
