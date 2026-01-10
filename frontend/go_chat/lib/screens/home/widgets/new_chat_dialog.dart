// lib/screens/home/widgets/new_chat_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/user.dart';
import '../../../services/auth_service.dart';
import '../../../providers/conversations_provider.dart';
import '../home_screen.dart';

final usersProvider = FutureProvider<List<User>>((ref) async {
  final api = ref.read(apiServiceProvider);
  return api.getUsers();
});

class NewChatDialog extends ConsumerStatefulWidget {
  const NewChatDialog({super.key});

  @override
  ConsumerState<NewChatDialog> createState() => _NewChatDialogState();
}

class _NewChatDialogState extends ConsumerState<NewChatDialog> {
  bool _isLoading = false;

  Future<void> _startChat(User user) async {
    setState(() => _isLoading = true);

    try {
      final api = ref.read(apiServiceProvider);
      final conversation = await api.createConversation(
        type: 'direct',
        participantId: user.id,
      );

      if (mounted) {
        // Add conversation to the list and select it
        ref.read(conversationsNotifierProvider.notifier).addConversation(conversation);
        ref.read(selectedConversationProvider.notifier).state = conversation.id;

        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start chat: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(usersProvider);

    return Dialog(
      backgroundColor: AppColors.surface,
      child: Container(
        width: 500,
        height: 600,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Start New Chat',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Search bar (for future implementation)
            TextField(
              decoration: InputDecoration(
                hintText: 'Search users...',
                prefixIcon: Icon(Icons.search, color: AppColors.textMuted),
                filled: true,
                fillColor: AppColors.surfaceLight,
              ),
            ),
            const SizedBox(height: 16),

            // Users list
            Expanded(
              child: usersAsync.when(
                data: (users) {
                  if (users.isEmpty) {
                    return Center(
                      child: Text(
                        'No users found',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      final user = users[index];
                      return UserTile(
                        user: user,
                        onTap: () => _startChat(user),
                        isLoading: _isLoading,
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, color: AppColors.error),
                      const SizedBox(height: 8),
                      Text(
                        'Failed to load users',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                      TextButton(
                        onPressed: () => ref.refresh(usersProvider),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class UserTile extends StatelessWidget {
  final User user;
  final VoidCallback onTap;
  final bool isLoading;

  const UserTile({
    super.key,
    required this.user,
    required this.onTap,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      enabled: !isLoading,
      leading: CircleAvatar(
        backgroundColor: AppColors.primary,
        child: Text(
          user.username[0].toUpperCase(),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Text(user.username),
      subtitle: Text(
        user.status,
        style: TextStyle(
          color: user.status == 'online' ? AppColors.online : AppColors.offline,
          fontSize: 12,
        ),
      ),
      trailing: user.status == 'online'
          ? Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          color: AppColors.online,
          shape: BoxShape.circle,
        ),
      )
          : null,
      onTap: isLoading ? null : onTap,
    );
  }
}