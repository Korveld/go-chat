// lib/screens/home/widgets/new_chat_dialog.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/user.dart';
import '../../../services/auth_service.dart';
import '../../../providers/conversations_provider.dart';
import '../home_screen.dart';

class NewChatDialog extends ConsumerStatefulWidget {
  const NewChatDialog({super.key});

  @override
  ConsumerState<NewChatDialog> createState() => _NewChatDialogState();
}

class _NewChatDialogState extends ConsumerState<NewChatDialog> {
  final _searchController = TextEditingController();
  List<User> _searchResults = [];
  bool _isLoading = false;
  bool _isSearching = false;
  bool _hasSearched = false;
  Timer? _debounce;

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();

    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _hasSearched = false;
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);

    _debounce = Timer(const Duration(milliseconds: 300), () {
      _searchUsers(query.trim());
    });
  }

  Future<void> _searchUsers(String query) async {
    try {
      final api = ref.read(apiServiceProvider);
      final users = await api.searchUsers(query);
      if (mounted) {
        setState(() {
          _searchResults = users;
          _hasSearched = true;
          _isSearching = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _searchResults = [];
          _hasSearched = true;
          _isSearching = false;
        });
      }
    }
  }

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

            // Search bar
            TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search by username, email or phone...',
                prefixIcon: Icon(Icons.search, color: AppColors.textMuted),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, color: AppColors.textMuted),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppColors.surfaceLight,
              ),
            ),
            const SizedBox(height: 16),

            // Users list
            Expanded(
              child: _buildContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isSearching) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!_hasSearched) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_search,
              size: 64,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: 16),
            Text(
              'Search for users',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Enter a username, email or phone number',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 48,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: 16),
            Text(
              'No users found',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final user = _searchResults[index];
        return UserTile(
          user: user,
          onTap: () => _startChat(user),
          isLoading: _isLoading,
        );
      },
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