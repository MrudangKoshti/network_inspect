import '../repositories/network_log_repository.dart';

class ClearNetworkLogsUseCase {
  ClearNetworkLogsUseCase(this._repository);

  final NetworkLogRepository _repository;

  Future<void> call() {
    return _repository.clearLogs();
  }
}
