import '../entities/network_log_entry.dart';
import '../repositories/network_log_repository.dart';

class GetNetworkLogsStreamUseCase {
  GetNetworkLogsStreamUseCase(this._repository);

  final NetworkLogRepository _repository;

  Stream<List<NetworkLogEntry>> call() {
    return _repository.watchLogs();
  }
}
