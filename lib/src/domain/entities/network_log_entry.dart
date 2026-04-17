import 'package:equatable/equatable.dart';

class NetworkLogEntry extends Equatable {
  const NetworkLogEntry({
    required this.id,
    required this.timestamp,
    required this.method,
    required this.url,
    this.requestBody,
    this.requestHeaders,
    this.responseBody,
    this.responseHeaders,
    this.statusCode,
    this.durationMs,
    this.error,
    this.isMultipart = false,
    this.rawRequest,
    this.rawResponse,
  });

  final String id;
  final DateTime timestamp;
  final String method;
  final String url;
  final String? requestBody;
  final String? requestHeaders;
  final String? responseBody;
  final String? responseHeaders;
  final int? statusCode;
  final int? durationMs;
  final String? error;
  final bool isMultipart;
  final String? rawRequest;
  final String? rawResponse;

  @override
  List<Object?> get props => [
        id,
        timestamp,
        method,
        url,
        requestBody,
        requestHeaders,
        responseBody,
        responseHeaders,
        statusCode,
        durationMs,
        error,
        isMultipart,
        rawRequest,
        rawResponse,
      ];
}
