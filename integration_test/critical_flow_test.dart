// Prueba E2E en dispositivo/emulador contra la API REAL de CEOSMOS.
//
//   flutter test integration_test/critical_flow_test.dart -d emulator-5554 \
//     --dart-define=E2E_EMAIL=usuario@ceosmos.test \
//     --dart-define=E2E_PASSWORD='Ceosmos#Dev2026'
//
// Requiere la API levantada (ver REPORTE_FINAL.md). Las credenciales no se
// guardan en el código.
import 'package:ceosmos_movil_integral/core/app_state.dart';
import 'package:ceosmos_movil_integral/data/api_client.dart';
import 'package:ceosmos_movil_integral/data/auth_repository.dart';
import 'package:ceosmos_movil_integral/data/catalog.dart';
import 'package:ceosmos_movil_integral/data/ceosmos_repository.dart';
import 'package:ceosmos_movil_integral/core/config.dart';
import 'package:ceosmos_movil_integral/data/token_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

const _email = String.fromEnvironment('E2E_EMAIL');
const _password = String.fromEnvironment('E2E_PASSWORD');

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('E2E: login real → favorito → sesión guardada en PostgreSQL → logout', (tester) async {
    expect(_email, isNotEmpty, reason: 'Define E2E_EMAIL y E2E_PASSWORD con --dart-define');
    final api = ApiClient(baseUrl: AppConfig.apiBaseUrl);
    final state = AppState(
      auth: AuthRepository(api, MemoryTokenStore()),
      data: CeosmosRepository(api),
      startTicker: false,
    );
    addTearDown(state.dispose);

    await state.acceptSession(await state.auth.login(_email, _password));
    expect(state.status, AuthStatus.signedIn);
    expect(state.dataError, isNull);
    final antes = state.workspace.history.length;

    final eraFavorito = state.workspace.favorites.contains('ocean');
    await state.toggleFavorite('ocean');
    expect((await state.data.favorites()).contains('ocean'), !eraFavorito);
    await state.toggleFavorite('ocean'); // deja el estado como estaba

    state.startSession(catalog.first, 5);
    await state.finishSession();
    final remoto = await state.data.focusSessions();
    expect(remoto.length, antes + 1);
    expect(remoto.first.contentKey, catalog.first.id);
    expect(state.workspace.history.first.synced, isTrue);

    await state.signOut();
    expect(state.user, isNull);
    await expectLater(state.data.favorites(), throwsA(isA<ApiException>()));
  });
}
