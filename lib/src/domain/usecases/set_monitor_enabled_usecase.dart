import '../repositories/network_log_repository.dart';

class SetMonitorEnabledUseCase {
  SetMonitorEnabledUseCase(this._repository);

  final NetworkLogRepository _repository;

  Future<void> call(bool value) {
    return _repository.setEnabled(value);
  }
}
