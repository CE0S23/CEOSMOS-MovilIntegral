import 'package:ceosmos_movil_integral/app.dart';
import 'package:ceosmos_movil_integral/core/app_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'E2E Android: demo, session completion, and history record',
    (tester) async {
      final state = AppState(startTicker: false);
      addTearDown(state.dispose);

      await tester.pumpWidget(CeosmosApp(state: state));
      await tester.pumpAndSettle();
      expect(find.text('Vuelve a tu centro.'), findsOneWidget);

      await tester.ensureVisible(find.text('Explorar demo'));
      await tester.tap(find.text('Explorar demo'));
      await tester.pumpAndSettle();
      expect(find.text('Hola, Explorador ✦'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.explore_outlined).last);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Órbita tranquila'));
      await tester.tap(find.text('Órbita tranquila').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('5 min').last);
      await tester.tap(find.text('Comenzar sesión'));
      await tester.pumpAndSettle();
      expect(find.text('Objetivo: 5 minutos'), findsOneWidget);

      await tester.ensureVisible(find.text('Terminar sesión'));
      await tester.tap(find.text('Terminar sesión'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Terminar'));
      await tester.pumpAndSettle();
      expect(state.workspace.history, hasLength(1));
      expect(state.workspace.history.single.mediaId, 'orbit');

      await tester.tap(find.byIcon(Icons.person_outline_rounded).last);
      await tester.pumpAndSettle();
      expect(find.text('Órbita tranquila'), findsOneWidget);
      expect(find.text('1 sesiones'), findsOneWidget);
      expect(find.text('Finalizada'), findsOneWidget);
    },
  );
}
