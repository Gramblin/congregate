import 'dart:async';
import 'dart:developer';

import 'package:app_links/app_links.dart';
import 'package:congregate/src/features/group/data/group_invitations_remote_repository.dart';
import 'package:congregate/src/utils/supabase_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DeepLinkHandler {
  DeepLinkHandler(this.ref);

  final WidgetRef ref;
  final _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;

  /// Initialize deep link handling
  Future<void> initialize(BuildContext context) async {
    // Handle initial link (when app is opened from terminated state)
    try {
      final initialLink = await _appLinks.getInitialLink();
      if (initialLink != null) {
        _handleDeepLink(initialLink, context);
      }
    } catch (e) {
      log('Error getting initial link: $e');
    }

    // Handle links while app is running
    _linkSubscription = _appLinks.uriLinkStream.listen(
      (uri) => _handleDeepLink(uri, context),
      onError: (err) => log('Deep link error: $err'),
    );
  }

  /// Handle incoming deep link
  Future<void> _handleDeepLink(Uri uri, BuildContext context) async {
    log('Received deep link: $uri');

    // Example: myapp://invite/ABC12345
    if (uri.pathSegments.isNotEmpty && uri.pathSegments.first == 'invite') {
      if (uri.pathSegments.length > 1) {
        final inviteCode = uri.pathSegments[1];
        await _handleInviteLink(inviteCode, context);
      }
    }
  }

  /// Handle group invite link
  Future<void> _handleInviteLink(
    String inviteCode,
    BuildContext context,
  ) async {
    try {
      final userId = ref.read(supabaseProvider).client.auth.currentUser?.id;
      if (userId == null) {
        // User not logged in - show login screen first
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please log in to accept the invitation'),
            ),
          );
        }
        return;
      }

      // Show loading
      if (context.mounted) {
        await showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(),
          ),
        );
      }

      // Accept the invitation
      final repo = ref.read(groupInvitationsRepositoryProvider);
      await repo.acceptInvitation(
        inviteCode: inviteCode,
        userId: userId,
      );

      // Close loading dialog
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      // Show success message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Successfully joined the group!'),
            backgroundColor: Colors.green,
          ),
        );
      }

      // TODO: Navigate to the group details screen
      // Navigator.push(context, MaterialPageRoute(...));
    } catch (e) {
      log('Error handling invite: $e');

      // Close loading dialog if still open
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      // Show error message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to join group: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Dispose resources
  void dispose() {
    _linkSubscription?.cancel();
  }
}
