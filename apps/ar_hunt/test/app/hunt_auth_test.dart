import 'package:ar_hunt/app/auth/hunt_auth.dart';
import 'package:ar_hunt/app/demo/demo_hunt.dart';
import 'package:ar_hunt/core/config/app_config.dart';
import 'package:ar_hunt/core/errors/app_failure.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('player names', () {
    test('the shared profiles table accepts 3 to 24 letters', () {
      expect(huntNameProblem('Raj'), isNull);
      expect(huntNameProblem('A' * 24), isNull);
      expect(huntNameProblem('Sharuk'), isNull);
    });

    test('too short is refused, not counting spaces', () {
      expect(huntNameProblem(''), isNotNull);
      expect(huntNameProblem('Al'), isNotNull);
      expect(huntNameProblem('  Al   '), isNotNull);
    });

    test('too long is refused', () {
      expect(huntNameProblem('A' * 25), isNotNull);
    });

    test('spaces around a name do not count against it', () {
      expect(huntNameProblem('  ${'A' * 24}  '), isNull);
    });
  });

  group('this app connects to', () {
    final config = AppConfig.fromEnvironment();

    test('its own Habba Hunt database, not the team project', () {
      expect(config.supabaseUrl, contains('jxpedobynwyxdwjlqjwk'));
      expect(config.supabaseUrl, isNot(contains('jddpkaxjchxldcpmdrbq')));
      expect(config.hasSupabase, isTrue);
    });

    test('with its public key only, never a secret one', () {
      expect(config.supabaseAnonKey, startsWith('sb_publishable_'));
    });
  });

  test('joining without a server explains itself', () async {
    final auth = HuntAuth(const AppConfig(environment: AppEnvironment.dev));
    await expectLater(auth.join('Sharuk'), throwsA(isA<UnexpectedFailure>()));
    expect(await auth.watchSession().first, isNull);
  });

  test('demo mode is off unless asked for', () {
    expect(huntDemoMode, isFalse);
  });
}
