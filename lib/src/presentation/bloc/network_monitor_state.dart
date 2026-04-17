part of 'network_monitor_bloc.dart';

class NetworkMonitorState extends Equatable {
  const NetworkMonitorState({
    required this.enabled,
    required this.logs,
    this.selectedLog,
  });

  final bool enabled;
  final List<NetworkLogEntry> logs;
  final NetworkLogEntry? selectedLog;

  NetworkMonitorState copyWith({
    bool? enabled,
    List<NetworkLogEntry>? logs,
    NetworkLogEntry? selectedLog,
    bool clearSelectedLog = false,
  }) {
    return NetworkMonitorState(
      enabled: enabled ?? this.enabled,
      logs: logs ?? this.logs,
      selectedLog: clearSelectedLog ? null : (selectedLog ?? this.selectedLog),
    );
  }

  @override
  List<Object?> get props => [enabled, logs, selectedLog];
}
