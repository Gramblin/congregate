import 'dart:developer';
import 'dart:math' as math;

import 'package:congregate/src/utils/supabase_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RecoveryRepository {
  RecoveryRepository(this._client);
  final SupabaseClient _client;

  /// Generates a cryptographically secure 128-bit token formatted as
  /// XXXX-XXXX-XXXX-XXXX-XXXX-XXXX-XXXX-XXXX (32 uppercase hex chars).
  String _generateToken() {
    final rng = math.Random.secure();
    final bytes = List<int>.generate(16, (_) => rng.nextInt(256));
    final hex = bytes
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join()
        .toUpperCase();
    // Group into 8 blocks of 4 for readability
    return List.generate(8, (i) => hex.substring(i * 4, i * 4 + 4)).join('-');
  }

  /// Generates a new token, stores its SHA-256 hash in the DB via the
  /// security-definer RPC (plaintext never persisted), and returns the
  /// plaintext for the user to copy once.
  Future<String> generateAndSaveToken() async {
    final token = _generateToken();
    try {
      await _client.rpc<void>(
        'save_recovery_token',
        params: {'p_token': token},
      );
      return token;
    } catch (e, st) {
      log('RecoveryRepository.generateAndSaveToken error: $e\n$st');
      rethrow;
    }
  }

  /// Sends the plaintext token to the Edge Function, which hashes it,
  /// looks up the matching user, and returns a fresh session.
  Future<void> recoverAccount(String token) async {
    try {
      final response = await _client.functions.invoke(
        'recover-account',
        body: {'token': token},
      );

      if (response.status != 200) {
        final message = (response.data as Map<String, dynamic>?)?['error']
            as String? ??
            'Recovery failed';
        throw Exception(message);
      }

      final data = response.data as Map<String, dynamic>;
      final refreshToken = data['refresh_token'] as String;

      await _client.auth.setSession(refreshToken);
    } catch (e, st) {
      log('RecoveryRepository.recoverAccount error: $e\n$st');
      rethrow;
    }
  }
}

final recoveryRepositoryProvider = Provider<RecoveryRepository>((ref) {
  return RecoveryRepository(ref.watch(supabaseProvider).client);
});
