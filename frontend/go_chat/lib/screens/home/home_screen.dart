// lib/screens/home/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/conversations_provider.dart';
import '../../providers/unread_provider.dart';
import 'widgets/conversations_sidebar.dart';
import 'widgets/chat_area.dart';

final selectedConversationProvider = StateProvider<int?>((ref) => null);

// Sidebar width constraints
const double _minSidebarWidth = 200;
const double _maxSidebarWidth = 500;
const double _defaultSidebarWidth = 300;

// Mobile breakpoint
const double _mobileBreakpoint = 600;

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  double _sidebarWidth = _defaultSidebarWidth;
  bool _isResizing = false;

  void _onDragUpdate(DragUpdateDetails details) {
    setState(() {
      _sidebarWidth += details.delta.dx;
      _sidebarWidth = _sidebarWidth.clamp(_minSidebarWidth, _maxSidebarWidth);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Initialize conversations when authenticated
    ref.watch(conversationsInitProvider);

    // Listen for new messages to track unread counts
    ref.watch(unreadListenerProvider);

    final selectedConversation = ref.watch(selectedConversationProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < _mobileBreakpoint;

    // Set background color based on active view for edge-to-edge effect
    final backgroundColor = isMobile
        ? (selectedConversation == null ? AppColors.sidebar : AppColors.surface)
        : null;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: isMobile
          ? SafeArea(child: _buildMobileLayout(selectedConversation))
          : _buildDesktopLayout(selectedConversation),
    );
  }

  Widget _buildMobileLayout(int? selectedConversation) {
    // On mobile: show sidebar by default, show chat when conversation selected
    if (selectedConversation == null) {
      return const ConversationsSidebar(width: double.infinity);
    }
    return ChatArea(
      conversationId: selectedConversation,
      showBackButton: true,
      onBack: () {
        ref.read(selectedConversationProvider.notifier).state = null;
      },
    );
  }

  Widget _buildDesktopLayout(int? selectedConversation) {
    return Row(
      children: [
        // Left sidebar - Conversations list
        ConversationsSidebar(width: _sidebarWidth),

        // Resize handle
        MouseRegion(
          cursor: SystemMouseCursors.resizeColumn,
          child: GestureDetector(
            onHorizontalDragStart: (_) => setState(() => _isResizing = true),
            onHorizontalDragUpdate: _onDragUpdate,
            onHorizontalDragEnd: (_) => setState(() => _isResizing = false),
            child: Container(
              width: 4,
              color: _isResizing ? AppColors.primary : AppColors.divider,
            ),
          ),
        ),

        // Right area - Chat messages
        Expanded(
          child: selectedConversation == null
              ? const EmptyState()
              : ChatArea(conversationId: selectedConversation),
        ),
      ],
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