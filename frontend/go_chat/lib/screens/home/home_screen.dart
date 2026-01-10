// lib/screens/home/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../services/auth_service.dart';
import 'widgets/conversations_sidebar.dart';
import 'widgets/chat_area.dart';

final selectedConversationProvider = StateProvider<int?>((ref) => null);

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedConversation = ref.watch(selectedConversationProvider);

    return Scaffold(
      body: Row(
        children: [
          // Left sidebar - Conversations list
          const ConversationsSidebar(),

          // Right area - Chat messages
          Expanded(
            child: selectedConversation == null
                ? const EmptyState()
                : ChatArea(conversationId: selectedConversation),
          ),
        ],
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 80,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: 16),
            Text(
              'Select a conversation to start chatting',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}