import 'package:flutter/material.dart';
import '../controllers/matches_controller.dart';
import '../controllers/auth_controller.dart';
import '../models/match.dart';
import '../models/chat_message.dart';
import '../services/socket_service.dart';

class MatchesPage extends StatefulWidget {
  final MatchesController matchesController;
  final AuthController authController;
  final SocketService socketService;

  const MatchesPage({
    super.key,
    required this.matchesController,
    required this.authController,
    required this.socketService,
  });

  @override
  State<MatchesPage> createState() => _MatchesPageState();
}

class _MatchesPageState extends State<MatchesPage> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _showMatches = true; // toggles between match list and chat on mobile

  static const _red = Color(0xFFD44B3A);
  static const _orange = Color(0xFFE07A30);
  static const _bg = Color(0xFFF7F5F2);
  static const _border = Color(0xFFE4E0DB);
  static const _textPrimary = Color(0xFF1A1714);
  static const _textSecondary = Color(0xFF5C5752);
  static const _textMuted = Color(0xFF9E9894);
  static const _bubbleOther = Color(0xFFEDEAE6);

  @override
  void initState() {
    super.initState();
    // Load matches when page opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.matchesController.loadMatches();
    });
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage() {
    final text = _inputController.text.trim();
    final chatId = widget.matchesController.chatId;
    if (text.isEmpty || chatId == null) return;

    // Optimistic update
    final optimistic = ChatMessage(
      id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
      senderId: widget.authController.user?.id ?? '',
      text: text,
      sentAt: DateTime.now(),
      isOwn: true,
    );
    widget.matchesController.addMessage(optimistic);
    widget.socketService.sendMessage(chatId, text);
    _inputController.clear();
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: _buildAppBar(),
      body: AnimatedBuilder(
        animation: widget.matchesController,
        builder: (context, _) {
          _scrollToBottom();
          return Row(
            children: [
              // ── Match list sidebar (always visible on tablet, toggleable on phone)
              if (_showMatches || _isWide(context))
                _buildMatchList(),

              // ── Chat window
              if (!_showMatches || _isWide(context))
                Expanded(child: _buildChatWindow()),
            ],
          );
        },
      ),
    );
  }

  bool _isWide(BuildContext context) =>
      MediaQuery.of(context).size.width >= 700;

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: _bg,
      elevation: 0,
      title: RichText(
        text: const TextSpan(
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: _textPrimary,
          ),
          children: [
            TextSpan(text: 'hot take'),
            TextSpan(text: '.', style: TextStyle(color: _red)),
          ],
        ),
      ),
      actions: [
        if (!_isWide(context))
          IconButton(
            icon: Icon(
              _showMatches ? Icons.chat_bubble_outline : Icons.people_outline,
              color: _textSecondary,
            ),
            onPressed: () => setState(() => _showMatches = !_showMatches),
          ),
        IconButton(
          icon: const Icon(Icons.logout_outlined, color: _textSecondary),
          onPressed: () => widget.authController.logout(),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: _border),
      ),
    );
  }

  // ── Match list ─────────────────────────────────────────────────────────────
  Widget _buildMatchList() {
    final controller = widget.matchesController;

    return Container(
      width: _isWide(context) ? 300 : double.infinity,
      decoration: const BoxDecoration(
        border: Border(right: BorderSide(color: _border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section label
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
            child: Text(
              'YOUR MATCHES',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.5,
                color: _textMuted,
              ),
            ),
          ),

          if (controller.isBusy)
            const Expanded(
              child: Center(
                child: CircularProgressIndicator(color: _red),
              ),
            )
          else if (controller.matches.isEmpty)
            Expanded(
              child: Center(
                child: Text(
                  'no matches yet',
                  style: TextStyle(
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                    color: _textMuted,
                  ),
                ),
              ),
            )
          else
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                itemCount: controller.matches.length,
                separatorBuilder: (_, __) => const SizedBox(height: 4),
                itemBuilder: (context, index) {
                  final match = controller.matches[index];
                  final isSelected = controller.selectedMatch?.userId == match.userId;
                  return _MatchTile(
                    match: match,
                    isSelected: isSelected,
                    onTap: () async {
                      await controller.selectMatch(match);
                      if (!_isWide(context)) {
                        setState(() => _showMatches = false);
                      }
                      // Join the new chat room in socket
                      if (controller.chatId != null) {
                        widget.socketService.joinChat(controller.chatId!);
                      }
                    },
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  // ── Chat window ────────────────────────────────────────────────────────────
  Widget _buildChatWindow() {
    final controller = widget.matchesController;
    final match = controller.selectedMatch;

    if (match == null) {
      return Center(
        child: Text(
          'select a match to start chatting',
          style: TextStyle(
            fontSize: 13,
            fontStyle: FontStyle.italic,
            color: _textMuted,
          ),
        ),
      );
    }

    return Column(
      children: [
        // Header
        _buildChatHeader(match),

        // Messages
        Expanded(
          child: controller.isLoadingChat
              ? const Center(child: CircularProgressIndicator(color: _red))
              : controller.messages.isEmpty
                  ? Center(
                      child: Text(
                        'say something real...',
                        style: TextStyle(
                          fontSize: 13,
                          fontStyle: FontStyle.italic,
                          color: _textMuted,
                        ),
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      itemCount: controller.messages.length,
                      itemBuilder: (context, index) {
                        return _MessageBubble(
                            message: controller.messages[index]);
                      },
                    ),
        ),

        // Input
        _buildInput(),
      ],
    );
  }

  Widget _buildChatHeader(Match match) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Back button on mobile
          if (!_isWide(context))
            GestureDetector(
              onTap: () => setState(() => _showMatches = true),
              child: Row(
                children: [
                  const Icon(Icons.arrow_back_ios, size: 14, color: _textMuted),
                  Text('matches',
                      style: TextStyle(fontSize: 12, color: _textMuted)),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          const SizedBox(height: 4),
          Text(
            match.username,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: _textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          // Tags
          Wrap(
            spacing: 6,
            children: match.tags
                .map((tag) => _TagChip(label: tag))
                .toList(),
          ),
          const SizedBox(height: 6),
          Text(
            '${match.score}% match · ${match.sharedTags.length} shared interests',
            style: const TextStyle(fontSize: 12, color: _textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildInput() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 16),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: _border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _inputController,
              style: const TextStyle(fontSize: 14, color: _textPrimary),
              decoration: InputDecoration(
                hintText: 'say something real...',
                hintStyle: TextStyle(
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                  color: _textMuted,
                ),
                filled: true,
                fillColor: const Color(0xFFF0ECE7),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _red, width: 1.5),
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
              ),
              onSubmitted: (_) => _sendMessage(),
              textInputAction: TextInputAction.send,
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: _red,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.arrow_forward,
                  color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Match tile widget ─────────────────────────────────────────────────────────
class _MatchTile extends StatelessWidget {
  final Match match;
  final bool isSelected;
  final VoidCallback onTap;

  const _MatchTile({
    required this.match,
    required this.isSelected,
    required this.onTap,
  });

  static const _red = Color(0xFFD44B3A);
  static const _border = Color(0xFFE4E0DB);
  static const _textPrimary = Color(0xFF1A1714);
  static const _textMuted = Color(0xFF9E9894);
  static const _textSecondary = Color(0xFF5C5752);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFD44B3A).withOpacity(0.06)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFD44B3A).withOpacity(0.3)
                : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFFEDE9E4),
                shape: BoxShape.circle,
                border: Border.all(color: _border),
              ),
              child: Center(
                child: Text(
                  match.username[0].toUpperCase(),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: _textSecondary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),

            // Name + interests
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    match.username,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: _textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    match.tags.take(3).join(' · '),
                    style: const TextStyle(fontSize: 11, color: _textMuted),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Score
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${match.score}',
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: _red,
                  ),
                ),
                const Text(
                  'match',
                  style: TextStyle(fontSize: 10, color: _textMuted),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Message bubble widget ─────────────────────────────────────────────────────
class _MessageBubble extends StatelessWidget {
  final ChatMessage message;

  const _MessageBubble({required this.message});

  static const _red = Color(0xFFD44B3A);
  static const _bubbleOther = Color(0xFFEDEAE6);
  static const _textMuted = Color(0xFF9E9894);

  @override
  Widget build(BuildContext context) {
    final timeStr =
        '${message.sentAt.hour % 12 == 0 ? 12 : message.sentAt.hour % 12}:'
        '${message.sentAt.minute.toString().padLeft(2, '0')} '
        '${message.sentAt.hour >= 12 ? 'PM' : 'AM'}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: message.isOwn
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.65,
            ),
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
              decoration: BoxDecoration(
                color: message.isOwn ? _red : _bubbleOther,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(message.isOwn ? 16 : 4),
                  bottomRight: Radius.circular(message.isOwn ? 4 : 16),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    message.text,
                    style: TextStyle(
                      fontSize: 14,
                      color: message.isOwn
                          ? Colors.white
                          : const Color(0xFF1A1714),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    timeStr,
                    style: TextStyle(
                      fontSize: 10,
                      color: message.isOwn
                          ? Colors.white.withOpacity(0.65)
                          : _textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Tag chip widget ───────────────────────────────────────────────────────────
class _TagChip extends StatelessWidget {
  final String label;
  const _TagChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFF0ECE7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFDDD9D4)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          color: Color(0xFF5C5752),
        ),
      ),
    );
  }
}