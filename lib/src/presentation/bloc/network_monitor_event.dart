part of 'network_monitor_bloc.dart';

sealed class NetworkMonitorEvent {
  const NetworkMonitorEvent();
}

class NetworkMonitorEnableChanged extends NetworkMonitorEvent {
  const NetworkMonitorEnableChanged(this.enabled);

  final bool enabled;
}

class NetworkMonitorClearPressed extends NetworkMonitorEvent {
  const NetworkMonitorClearPressed();
}

class NetworkMonitorDetailRequested extends NetworkMonitorEvent {
  const NetworkMonitorDetailRequested(this.entry);

  final NetworkLogEntry entry;
}

class NetworkMonitorDetailClosed extends NetworkMonitorEvent {
  const NetworkMonitorDetailClosed();
}

class _NetworkMonitorLogsUpdated extends NetworkMonitorEvent {
  const _NetworkMonitorLogsUpdated(this.logs);

  final List<NetworkLogEntry> logs;
}
