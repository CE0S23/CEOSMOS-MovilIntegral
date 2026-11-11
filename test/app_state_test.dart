import 'package:flutter_test/flutter_test.dart';
import 'package:ceosmos_movil_integral/core/app_state.dart';
import 'package:ceosmos_movil_integral/data/auth_repository.dart';
import 'package:ceosmos_movil_integral/data/catalog.dart';
import 'package:ceosmos_movil_integral/domain/models.dart';

void main() {
  test(
    'Registration normalizes email, rejects duplicates and incorrect passwords',
    () async {
      final auth = MemoryAuthRepository();
      final account = await auth.register(
        'César',
        ' CESAR@example.com ',
        'prueba123',
      );
      expect(account.user.email, 'cesar@example.com');
      expect(
        (await auth.login('CESAR@example.com', 'prueba123')).user.id,
        account.user.id,
      );
      await expectLater(
        auth.login('cesar@example.com', 'incorrecta'),
        throwsA(isA<AuthFailure>()),
      );
      await expectLater(
        auth.register('Otro', 'cesar@example.com', 'prueba123'),
        throwsA(isA<AuthFailure>()),
      );
      await expectLater(
        auth.register('A', 'incorrecto', '12'),
        throwsA(isA<AuthFailure>()),
      );
    },
  );

  test(
    'Timer excludes paused time and automatically records exactly one completion',
    () async {
      var now = DateTime(2026, 10, 8, 12);
      final state = AppState(
        now: () => now,
        auth: MemoryAuthRepository(now: () => now),
        startTicker: false,
      );
      addTearDown(state.dispose);
      state.acceptSession(await state.auth.enterDemo());
      state.startSession(catalog.first, 5);
      now = now.add(const Duration(seconds: 40));
      state.togglePause();
      now = now.add(const Duration(minutes: 10));
      expect(state.elapsed.inSeconds, 40);
      state.togglePause();
      now = now.add(const Duration(minutes: 5));
      state.tick();
      state.tick();
      expect(state.hasSession, isFalse);
      expect(state.workspace.history, hasLength(1));
      expect(state.workspace.history.single.durationSeconds, 300);
      expect(state.workspace.history.single.completed, isTrue);
    },
  );

  test(
    'User workspaces are isolated and survive logout only during this run',
    () async {
      final state = AppState(startTicker: false);
      addTearDown(state.dispose);
      state.acceptSession(
        await state.auth.register('Uno', 'uno@example.com', 'prueba123'),
      );
      state.toggleFavorite('orbit');
      state.toggleDevice('wearable');
      state.setPreferredMinutes(15);
      state.startSession(catalog.first, 5);
      await state.signOut();
      expect(state.hasSession, isFalse);
      state.acceptSession(
        await state.auth.register('Dos', 'dos@example.com', 'prueba123'),
      );
      expect(state.workspace.favorites, isEmpty);
      expect(state.workspace.history, isEmpty);
      expect(state.workspace.devices, isEmpty);
      await state.signOut();
      state.acceptSession(
        await state.auth.login('uno@example.com', 'prueba123'),
      );
      expect(state.workspace.favorites, {'orbit'});
      expect(state.workspace.history, hasLength(1));
      expect(state.workspace.devices.single.userId, state.user!.id);
      expect(state.workspace.preferredMinutes, 15);
      await expectLater(
        MemoryAuthRepository().login('uno@example.com', 'prueba123'),
        throwsA(isA<AuthFailure>()),
      );
    },
  );

  test('Session expiry logs out and closes focus activity', () async {
    var now = DateTime(2026, 10, 8, 12);
    final state = AppState(
      now: () => now,
      auth: MemoryAuthRepository(now: () => now),
      startTicker: false,
    );
    addTearDown(state.dispose);
    state.acceptSession(await state.auth.enterDemo());
    state.startSession(catalog.first, 25);
    now = now.add(const Duration(hours: 2));
    state.tick();
    expect(state.user, isNull);
    expect(state.hasSession, isFalse);
    expect(state.notice, isNotNull);
  });

  test(
    'Changing scenes saves previous session; invalid duration cannot mutate it',
    () async {
      final state = AppState(startTicker: false);
      addTearDown(state.dispose);
      state.acceptSession(await state.auth.enterDemo());
      state.startSession(catalog.first, 5);
      expect(() => state.startSession(catalog[1], 0), throwsArgumentError);
      expect(state.currentMedia, catalog.first);
      state.startSession(catalog[1], 15);
      expect(state.workspace.history.single.mediaId, catalog.first.id);
      expect(state.currentMedia, catalog[1]);
    },
  );

  test(
    'Search combines accents, type, mode and favorites; unknown query is empty',
    () {
      expect(filterCatalog(query: 'ORBITA').single.id, 'orbit');
      expect(
        filterCatalog(mode: FocusMode.relax, kind: MediaKind.audio).single.id,
        'forest',
      );
      expect(
        filterCatalog(favorites: {'nebula'}, kind: MediaKind.audio),
        isEmpty,
      );
      expect(filterCatalog(query: 'nada-que-exista'), isEmpty);
    },
  );
}
