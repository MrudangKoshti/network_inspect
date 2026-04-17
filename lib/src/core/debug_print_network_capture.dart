import 'dart:collection';

import 'package:flutter/foundation.dart';

import '../domain/entities/network_log_entry.dart';

typedef EntrySink = Future<void> Function(NetworkLogEntry entry);

class DebugPrintNetworkCapture {
  DebugPrintNetworkCapture._();

  static final DebugPrintNetworkCapture instance = DebugPrintNetworkCapture._();

  DebugPrintCallback? _original;
  EntrySink? _sink;
  final Queue<_PendingRequest> _requestQueue = Queue<_PendingRequest>();
  _PendingRequest? _buildingRequest;
  _PendingResponse? _buildingResponse;
  bool _isActive = false;

  void start(EntrySink sink) {
    if (_isActive) {
      _sink = sink;
      return;
    }
    _sink = sink;
    _original = debugPrint;
    _isActive = true;

    debugPrint = (String? message, {int? wrapWidth}) {
      if (message != null) {
        _handleMessage(message);
      }
      final original = _original;
      if (original != null) {
        original(message, wrapWidth: wrapWidth);
      }
    };
  }

  void stop() {
    if (!_isActive) return;
    final original = _original;
    if (original != null) {
      debugPrint = original;
    }
    _sink = null;
    _original = null;
    _requestQueue.clear();
    _buildingRequest = null;
    _buildingResponse = null;
    _isActive = false;
  }

  void _handleMessage(String message) {
    final lines = message.split('\n');
    for (final rawLine in lines) {
      _handleLine(rawLine);
    }
  }

  void _handleLine(String rawLine) {
    final line = rawLine.trimRight();
    if (line.trim().isEmpty) return;

    if (line.contains('HTTP REQUEST (MULTIPART)')) {
      _finalizeCurrentRequestIfAny();
      _buildingRequest = _PendingRequest(isMultipart: true)..addRawLine(line);
      return;
    }
    if (line.contains('HTTP REQUEST')) {
      _finalizeCurrentRequestIfAny();
      _buildingRequest = _PendingRequest()..addRawLine(line);
      return;
    }
    if (line.contains('HTTP RESPONSE')) {
      _finalizeCurrentResponseIfAny();
      final duration = RegExp(r'\[(\d+)\s*ms\]').firstMatch(line);
      _buildingResponse = _PendingResponse(
        durationMs: duration != null ? int.tryParse(duration.group(1)!) : null,
      )..addRawLine(line);
      return;
    }

    if (_buildingRequest != null) {
      _consumeRequestLine(line);
      return;
    }
    if (_buildingResponse != null) {
      _consumeResponseLine(line);
    }
  }

  void _consumeRequestLine(String line) {
    final req = _buildingRequest!;
    req.addRawLine(line);

    if (_isBottomBorder(line)) {
      _requestQueue.add(req);
      _buildingRequest = null;
      return;
    }

    if (_isSectionDivider(line)) {
      return;
    }

    final method = _extractField(line, 'Method:');
    if (method != null) {
      req.method = method;
      req.isCollectingBody = false;
      return;
    }
    final url = _extractField(line, 'URL:');
    if (url != null) {
      req.url = url;
      req.isCollectingBody = false;
      return;
    }
    final body = _extractField(line, 'Body:');
    if (body != null) {
      req.bodyBuffer
        ..clear()
        ..write(body);
      req.isCollectingBody = true;
      return;
    }
    final fields = _extractField(line, 'Fields:');
    if (fields != null) {
      req.bodyBuffer
        ..clear()
        ..write(fields);
      req.isCollectingBody = true;
      return;
    }
    final files = _extractField(line, 'Files:');
    if (files != null) {
      req.files = files;
      req.isCollectingBody = false;
      return;
    }

    if (req.isCollectingBody && _isJsonContinuationLine(line)) {
      req.bodyBuffer
        ..write('\n')
        ..write(_stripPipePrefix(line));
      return;
    }

    req.isCollectingBody = false;
  }

  void _consumeResponseLine(String line) {
    final res = _buildingResponse!;
    res.addRawLine(line);

    if (_isBottomBorder(line)) {
      if (res.isChunkMode && res.chunkBuffer.isNotEmpty) {
        res.body = res.chunkBuffer.toString().trim();
      } else if (res.bodyBuffer.isNotEmpty) {
        res.body = res.bodyBuffer.toString().trim();
      }
      _emitResponse(res);
      _buildingResponse = null;
      return;
    }

    if (_isSectionDivider(line)) {
      return;
    }

    final status = _extractField(line, 'Status:');
    if (status != null) {
      res.statusCode = int.tryParse(status);
      res.isCollectingBody = false;
      return;
    }

    if (_extractField(line, 'Body (') != null && line.endsWith('):')) {
      res.isChunkMode = true;
      res.isCollectingBody = false;
      return;
    }

    final body = _extractField(line, 'Body:');
    if (body != null) {
      res.bodyBuffer
        ..clear()
        ..write(body);
      res.isCollectingBody = true;
      res.isChunkMode = false;
      return;
    }

    if (res.isChunkMode) {
      if (!_looksLikeBoxLine(line)) {
        res.chunkBuffer
          ..write(line)
          ..write('\n');
      }
      return;
    }

    if (res.isCollectingBody && _isJsonContinuationLine(line)) {
      res.bodyBuffer
        ..write('\n')
        ..write(_stripPipePrefix(line));
      return;
    }

    res.isCollectingBody = false;
  }

  void _emitResponse(_PendingResponse response) {
    final sink = _sink;
    if (sink == null) return;

    final request = _requestQueue.isNotEmpty
        ? _requestQueue.removeFirst()
        : _PendingRequest();
    final method = request.method ?? 'GET';
    final url = request.url ?? 'Unknown URL';
    final requestBody = request.bodyBuffer.isEmpty
        ? (request.files != null ? 'Files: ${request.files}' : null)
        : request.bodyBuffer.toString().trim();

    sink(
      NetworkLogEntry(
        id: '${DateTime.now().microsecondsSinceEpoch}',
        timestamp: DateTime.now(),
        method: method,
        url: url,
        requestBody: requestBody,
        responseBody: response.body,
        statusCode: response.statusCode,
        durationMs: response.durationMs,
        isMultipart: request.isMultipart,
        rawRequest: request.rawBuffer.toString().trim(),
        rawResponse: response.rawBuffer.toString().trim(),
      ),
    );
  }

  void _finalizeCurrentRequestIfAny() {
    final req = _buildingRequest;
    if (req == null) return;
    _requestQueue.add(req);
    _buildingRequest = null;
  }

  void _finalizeCurrentResponseIfAny() {
    final res = _buildingResponse;
    if (res == null) return;
    _emitResponse(res);
    _buildingResponse = null;
  }

  bool _isSectionDivider(String line) {
    final trimmed = line.trim();
    return trimmed.startsWith('╠') || trimmed.startsWith('╔');
  }

  bool _isBottomBorder(String line) {
    return line.trim().startsWith('╚');
  }

  bool _looksLikeBoxLine(String line) {
    final trimmed = line.trim();
    return trimmed.startsWith('║') ||
        trimmed.startsWith('╚') ||
        trimmed.startsWith('╔') ||
        trimmed.startsWith('╠');
  }

  bool _isJsonContinuationLine(String line) {
    final trimmed = line.trimLeft();
    return trimmed.startsWith('║') || trimmed.startsWith('|');
  }

  String _stripPipePrefix(String line) {
    final trimmed = line.trimLeft();
    if (trimmed.startsWith('║')) {
      return trimmed.substring(1).trimLeft();
    }
    if (trimmed.startsWith('|')) {
      return trimmed.substring(1).trimLeft();
    }
    return trimmed;
  }

  String? _extractField(String line, String key) {
    final trimmed = line.trimLeft();
    if (!(trimmed.startsWith('║') || trimmed.startsWith('|'))) {
      return null;
    }
    final withoutPipe = trimmed.substring(1).trimLeft();
    if (!withoutPipe.startsWith(key)) {
      return null;
    }
    return withoutPipe.substring(key.length).trimLeft();
  }
}

class _PendingRequest {
  _PendingRequest({this.isMultipart = false});

  final bool isMultipart;
  String? method;
  String? url;
  String? files;
  final StringBuffer bodyBuffer = StringBuffer();
  final StringBuffer rawBuffer = StringBuffer();
  bool isCollectingBody = false;

  void addRawLine(String line) {
    rawBuffer
      ..write(line)
      ..write('\n');
  }
}

class _PendingResponse {
  _PendingResponse({this.durationMs});

  final int? durationMs;
  int? statusCode;
  String? body;
  final StringBuffer bodyBuffer = StringBuffer();
  final StringBuffer chunkBuffer = StringBuffer();
  final StringBuffer rawBuffer = StringBuffer();
  bool isChunkMode = false;
  bool isCollectingBody = false;

  void addRawLine(String line) {
    rawBuffer
      ..write(line)
      ..write('\n');
  }
}
