import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/network_log_entry.dart';
import '../../domain/usecases/clear_network_logs_usecase.dart';
import '../../domain/usecases/get_network_logs_stream_usecase.dart';

part 'network_monitor_event.dart';
part 'network_monitor_state.dart';

class NetworkMonitorBloc
    extends Bloc<NetworkMonitorEvent, NetworkMonitorState> {
  NetworkMonitorBloc({
    required GetNetworkLogsStreamUseCase getLogsStream,
    required ClearNetworkLogsUseCase clearLogs,
    required bool initialVisible,
  })  : _getLogsStream = getLogsStream,
        _clearLogs = clearLogs,
        super(
          NetworkMonitorState(
            enabled: initialVisible,
            logs: const <NetworkLogEntry>[],
            selectedLog: null,
          ),
        ) {
    on<NetworkMonitorEnableChanged>(_onEnableChanged);
    on<NetworkMonitorClearPressed>(_onClear);
    on<NetworkMonitorDetailRequested>(_onDetailRequested);
    on<NetworkMonitorDetailClosed>(_onDetailClosed);
    on<_NetworkMonitorLogsUpdated>(_onLogsUpdated);

    _logsSub = _getLogsStream().listen((logs) {
      add(_NetworkMonitorLogsUpdated(logs));
    });
  }

  final GetNetworkLogsStreamUseCase _getLogsStream;
  final ClearNetworkLogsUseCase _clearLogs;

  StreamSubscription<List<NetworkLogEntry>>? _logsSub;

  Future<void> _onEnableChanged(
    NetworkMonitorEnableChanged event,
    Emitter<NetworkMonitorState> emit,
  ) async {
    emit(state.copyWith(enabled: event.enabled));
  }

  Future<void> _onClear(
    NetworkMonitorClearPressed event,
    Emitter<NetworkMonitorState> emit,
  ) async {
    await _clearLogs();
    emit(state.copyWith(clearSelectedLog: true));
  }

  void _onDetailRequested(
    NetworkMonitorDetailRequested event,
    Emitter<NetworkMonitorState> emit,
  ) {
    emit(state.copyWith(selectedLog: event.entry));
  }

  void _onDetailClosed(
    NetworkMonitorDetailClosed event,
    Emitter<NetworkMonitorState> emit,
  ) {
    emit(state.copyWith(clearSelectedLog: true));
  }

  void _onLogsUpdated(
    _NetworkMonitorLogsUpdated event,
    Emitter<NetworkMonitorState> emit,
  ) {
    emit(state.copyWith(logs: event.logs));
  }

  @override
  Future<void> close() async {
    await _logsSub?.cancel();
    return super.close();
  }
}
