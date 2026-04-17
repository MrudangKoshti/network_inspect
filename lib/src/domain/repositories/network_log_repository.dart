import '../entities/network_log_entry.dart';

abstract class NetworkLogRepository {
  Stream<List<NetworkLogEntry>> watchLogs();
  List<NetworkLogEntry> currentLogs();
  Future<void> addLog(NetworkLogEntry entry);
  Future<void> clearLogs();

  Stream<bool> watchEnabled();
  bool isEnabled();
  Future<void> setEnabled(bool value);
}
