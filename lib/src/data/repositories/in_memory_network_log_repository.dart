import 'dart:async';

import '../../domain/entities/network_log_entry.dart';
import '../../domain/repositories/network_log_repository.dart';

class InMemoryNetworkLogRepository implements NetworkLogRepository {
  InMemoryNetworkLogRepository({this.maxEntries = 500});

  final int maxEntries;

  final List<NetworkLogEntry> _entries = <NetworkLogEntry>[];
  final StreamController<List<NetworkLogEntry>> _logsController =
      StreamController<List<NetworkLogEntry>>.broadcast();
  final StreamController<bool> _enabledController =
      StreamController<bool>.broadcast();

  bool _enabled = true;

  @override
  Future<void> addLog(NetworkLogEntry entry) async {
    _entries.insert(0, entry);
    if (_entries.length > maxEntries) {
      _entries.removeRange(maxEntries, _entries.length);
    }
    _logsController.add(List<NetworkLogEntry>.unmodifiable(_entries));
  }

  @override
  Future<void> clearLogs() async {
    _entries.clear();
    _logsController.add(const <NetworkLogEntry>[]);
  }

  @override
  List<NetworkLogEntry> currentLogs() {
    return List<NetworkLogEntry>.unmodifiable(_entries);
  }

  @override
  bool isEnabled() => _enabled;

  @override
  Future<void> setEnabled(bool value) async {
    _enabled = value;
    _enabledController.add(_enabled);
    _logsController.add(List<NetworkLogEntry>.unmodifiable(_entries));
  }

  @override
  Stream<bool> watchEnabled() async* {
    yield _enabled;
    yield* _enabledController.stream;
  }

  @override
  Stream<List<NetworkLogEntry>> watchLogs() async* {
    yield List<NetworkLogEntry>.unmodifiable(_entries);
    yield* _logsController.stream;
  }
}
