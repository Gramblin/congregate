import 'package:congregate/src/features/group/data/group_invitations_remote_repository.dart';
import 'package:congregate/src/features/group/domain/group_invitation.dart';
import 'package:congregate/src/utils/supabase_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class GroupInviteScreen extends ConsumerStatefulWidget {
  const GroupInviteScreen({required this.inviteCode, super.key});

  final String inviteCode;

  @override
  ConsumerState<GroupInviteScreen> createState() => _GroupInviteScreenState();
}

class _GroupInviteScreenState extends ConsumerState<GroupInviteScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  GroupInvitation? _invitation;

  @override
  void initState() {
    super.initState();
    _loadInvitation();
  }

  Future<void> _loadInvitation() async {
    try {
      final repo = ref.read(groupInvitationsRepositoryProvider);
      final invitation = await repo.getInvitationByCode(widget.inviteCode);

      if (mounted) {
        setState(() {
          _invitation = invitation;
          _isLoading = false;
        });
      }
    } on Exception catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _acceptInvite() async {
    final userId = ref.read(supabaseProvider).client.auth.currentUser?.id;
    if (userId == null) return;

    setState(() => _isLoading = true);

    try {
      final repo = ref.read(groupInvitationsRepositoryProvider);
      await repo.acceptInvitation(
        inviteCode: widget.inviteCode,
        userId: userId,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Successfully joined the group!'),
            backgroundColor: Colors.green,
          ),
        );
        context.go('/communities'); // Navigate to home
      }
    } on Exception catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null || _invitation == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Invalid Invite')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                _errorMessage ?? 'Invitation not found',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.go('/communities'),
                child: const Text('Go to Home'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Group Invitation')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.group, size: 64, color: Colors.blue),
            const SizedBox(height: 24),
            const Text(
              "You've been invited to join a prayer group!",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Invite Code: ${widget.inviteCode}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _acceptInvite,
              child: const Text('Accept Invitation'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => context.go('/communities'),
              child: const Text('Decline'),
            ),
          ],
        ),
      ),
    );
  }
}
