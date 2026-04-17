import '../entities/network_log_entry.dart';
import '../repositories/network_log_repository.dart';

class AddNetworkLogUseCase {
  AddNetworkLogUseCase(this._repository);

  final NetworkLogRepository _repository;

  Future<void> call(NetworkLogEntry entry) {
    return _repository.addLog(entry);
  }
}
