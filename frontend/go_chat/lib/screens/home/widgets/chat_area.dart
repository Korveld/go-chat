// lib/screens/home/widgets/chat_area.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../services/auth_service.dart';
import '../../../models/user.dart';
import '../../../providers/conversations_provider.dart';
import '../../../providers/messages_provider.dart';
import 'widgets/message_bubble.dart';

class ChatArea extends ConsumerStatefulWidget {
  final int conversationId;
  final bool showBackButton;
  final VoidCallback? onBack;

  const ChatArea({
    super.key,
    required this.conversationId,
    this.showBackButton = false,
    this.onBack,
  });

  @override
  ConsumerState<ChatArea> createState() => _ChatAreaState();
}

class _ChatAreaState extends ConsumerState<ChatArea> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  int? _previousMessageCount;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(messagesNotifierProvider.notifier).loadMessages(widget.conversationId);
    });
  }

  @override
  void didUpdateWidget(ChatArea oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.conversationId != widget.conversationId) {
      // Delay to avoid modifying provider during build
      Future.microtask(() {
        ref.read(messagesNotifierProvider.notifier).loadMessages(widget.conversationId);
      });
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    }
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(conversationMessagesProvider(widget.conversationId));
    final isLoading = ref.watch(conversationLoadingProvider(widget.conversationId));
    final error = ref.watch(conversationErrorProvider(widget.conversationId));
    final authState = ref.watch(authNotifierProvider);
    final conversationsState = ref.watch(conversationsNotifierProvider);

    final currentUserId = authState.value?.id ?? 0;
    final conversation = conversationsState.value?.firstWhere(
      (c) => c.id == widget.conversationId,
      orElse: () => conversationsState.value!.first,
    );

    // Auto-scroll when new messages arrive
    if (_previousMessageCount != null && messages.length > _previousMessageCount!) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    }
    _previousMessageCount = messages.length;

    // Get display name and online status
    final displayName = conversation?.getDisplayName(currentUserId) ?? 'Chat';
    final isGroup = conversation?.type == 'group';
    final isOnline = conversation?.isOtherUserOnline(currentUserId) ?? false;

    return Container(
      color: AppColors.background,
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border(
                bottom: BorderSide(color: AppColors.divider),
              ),
            ),
            child: Row(
              children: [
                if (widget.showBackButton) ...[
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: widget.onBack,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 12),
                ],
                CircleAvatar(
                  backgroundColor: AppColors.primary,
                  child: Icon(
                    isGroup ? Icons.group : Icons.person,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      if (!isGroup)
                        Text(
                          isOnline ? 'Online' : 'Offline',
                          style: TextStyle(
                            color: isOnline ? AppColors.online : AppColors.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      if (isGroup)
                        Text(
                          '${conversation?.participants.length ?? 0} members',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Messages
          Expanded(
            child: _buildMessagesArea(messages, isLoading, error, authState),
          ),

          // Message Input
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border(
                top: BorderSide(color: AppColors.divider),
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: () {
                    // TODO: Add attachment functionality
                  },
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      hintStyle: TextStyle(color: AppColors.textMuted),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: AppColors.surfaceLight,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                    ),
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.send, color: AppColors.primary),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    ref.read(messagesNotifierProvider.notifier).sendMessage(
      widget.conversationId,
      text,
    );

    _messageController.clear();
  }

  Widget _buildMessagesArea(
    List<Message> messages,
    bool isLoading,
    String? error,
    AsyncValue<User?> authState,
  ) {
    if (isLoading && messages.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (error != null && messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: AppColors.error, size: 48),
            const SizedBox(height: 16),
            Text(
              'Failed to load messages',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            TextButton(
              onPressed: () => ref
                  .read(messagesNotifierProvider.notifier)
                  .loadMessages(widget.conversationId),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 64,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: 16),
            Text(
              'No messages yet',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Send a message to start the conversation',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

    final currentUserId = authState.value?.id ?? 0;

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        final isMe = message.senderId == currentUserId;
        final showAvatar =
            index == 0 || messages[index - 1].senderId != message.senderId;

        return MessageBubble(
          message: message,
          isMe: isMe,
          showAvatar: showAvatar,
        );
      },
    );
  }
}