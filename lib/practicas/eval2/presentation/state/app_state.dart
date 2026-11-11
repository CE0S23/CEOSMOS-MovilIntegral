import '../../core/network/api_client.dart';
import '../../core/storage/secure_storage.dart';
import '../../data/repositories/repositories.dart';

/// Contenedor simple de dependencias compartidas por las pantallas.
class AppState {
  static final storage = SecureStorage();
  static final api = ApiClient(storage);
  static final auth = AuthRepository(api);
  static final appointments = AppointmentRepository(api);
  static final healthInfo = HealthInfoRepository(api);
  static final lab = LabRepository(api);
}

/// Estados de pantalla: cargando / datos / vacio / error / degradado.
enum ViewStatus { loading, data, empty, error, degraded }
