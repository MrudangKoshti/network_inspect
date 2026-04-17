import '../repositories/network_log_repository.dart';

class GetMonitorEnabledStreamUseCase {
  GetMonitorEnabledStreamUseCase(this._repository);

  final NetworkLogRepository _repository;

  Stream<bool> call() {
    return _repository.watchEnabled();
  }
}
