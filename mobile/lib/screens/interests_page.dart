import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../controllers/auth_controller.dart';
import '../config/api_config.dart';

class InterestsPage extends StatefulWidget {
  final AuthController authController;
  final VoidCallback? onSubmitted;

  const InterestsPage({
    super.key,
    required this.authController,
    this.onSubmitted,
  });

  @override
  State<InterestsPage> createState() => _InterestsPageState();
}

class _InterestsPageState extends State<InterestsPage> {
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _tagInputController = TextEditingController();

  List<String> _tags = [];
  String _tagError = '';
  bool _isSubmitting = false;
  bool _paradiseMode = false;
  bool _leineckerMode = false;

  static const _suggestions = [
    'cooking', 'music', 'climate', 'gaming', 'politics', 'startups'
  ];

  static const _red = Color(0xFFE24B4A);
  static const _orange = Color(0xFFEF9F27);
  static const _textPrimary = Color(0xFF1A1714);
  static const _textMuted = Color(0xFF888780);
  static const _border = Color(0xFFE4E0DB);
  static const _bg = Color(0xFFF7F5F2);

  @override
  void dispose() {
    _bioController.dispose();
    _tagInputController.dispose();
    super.dispose();
  }

  void _addTag(String tag) {
    final cleaned = tag.trim().toLowerCase();
    if (cleaned.isEmpty) return;
    if (cleaned.length > 30) {
      setState(() => _tagError = 'tags must be 30 characters or fewer.');
      return;
    }
    if (_tags.length >= 10) {
      setState(() => _tagError = 'you can only add up to 10 tags.');
      return;
    }
    if (_tags.contains(cleaned)) {
      setState(() => _tagError = '"$cleaned" is already added.');
      return;
    }
    setState(() {
      _tagError = '';
      if (cleaned == 'paradise') _paradiseMode = true;
      if (cleaned == 'leinecker') _leineckerMode = true;
      _tags = [..._tags, cleaned];
    });
  }

  void _removeTag(String tag) {
    setState(() {
      if (tag == 'paradise') _paradiseMode = false;
      if (tag == 'leinecker') _leineckerMode = false;
      _tags = _tags.where((t) => t != tag).toList();
    }); 
  }

  Future<void> _handleSubmit() async {
    if (_bioController.text.trim().isEmpty) {
      setState(() => _tagError = 'please enter a bio before submitting.');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final token = widget.authController.token;
      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/api/interests'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'bio': _bioController.text.trim(),
          'tags': _tags,
        }),
      );

      if (response.statusCode == 200) {
        widget.onSubmitted?.call();
      } else {
        debugPrint('Failed to save interests: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error submitting interests: $e');
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Background changes in paradise mode
    final bgDecoration = _paradiseMode
        ? const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFf4845f), Color(0xFFf7b46a), Color(0xFFf5d08a)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          )
        : const BoxDecoration(color: Color(0xFFF7F5F2));

    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 700),
        decoration: bgDecoration,
        child: SafeArea(
          child: Stack(
            children: [

              // ── Palm trees in paradise mode ───────────────────────────
              if (_paradiseMode) ...[
                Positioned(
                  bottom: 0,
                  left: -20,
                  child: CustomPaint(
                    size: const Size(140, 280),
                    painter: _PalmTreePainter(flipped: false),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: -20,
                  child: CustomPaint(
                    size: const Size(140, 280),
                    painter: _PalmTreePainter(flipped: true),
                  ),
                ),
              ],

              // ── Main scrollable content ───────────────────────────────
              SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    // ── Paradise banner ───────────────────────────────
                    if (_paradiseMode) ...[
                      Center(
                        child: Text(
                          '🌴 paradise mode unlocked 🌴',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

              // ── Heading ──────────────────────────────────────────────────
              const Text(
                "what's on your mind?",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: _textPrimary,
                  fontFamily: 'monospace',
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'this is how we find your people. be honest, be specific.',
                style: TextStyle(
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                  color: _textMuted,
                ),
              ),
              const SizedBox(height: 24),

              // ── Bio textarea ─────────────────────────────────────────────
              Stack(
                children: [
                  TextField(
                    controller: _bioController,
                    maxLength: 500,
                    maxLines: 6,
                    buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'what are you into? be specific...',
                      hintStyle: const TextStyle(color: Color(0xFFAAA49C)),
                      filled: true,
                      fillColor: const Color(0xFFF0ECE7),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: const BorderSide(color: _red, width: 1.5),
                      ),
                      contentPadding: const EdgeInsets.fromLTRB(16, 14, 16, 36),
                    ),
                  ),
                  // Character counter
                  Positioned(
                    bottom: 10,
                    right: 14,
                    child: Text(
                      '${_bioController.text.length}/500',
                      style: const TextStyle(
                        fontSize: 11,
                        color: _textMuted,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ── Interest tags label ───────────────────────────────────────
              const Text(
                'INTEREST TAGS',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 2,
                  color: _textMuted,
                ),
              ),
              const SizedBox(height: 8),

              // ── Tag input ────────────────────────────────────────────────
              TextField(
                controller: _tagInputController,
                decoration: InputDecoration(
                  hintText: 'type and press Enter',
                  hintStyle: const TextStyle(color: Color(0xFFAAA49C)),
                  filled: true,
                  fillColor: const Color(0xFFF0ECE7),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: const BorderSide(color: _red, width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14,
                  ),
                ),
                textInputAction: TextInputAction.done,
                onSubmitted: (value) {
                  _addTag(value);
                  _tagInputController.clear();
                },
              ),

              // ── Tag error ────────────────────────────────────────────────
              if (_tagError.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  _tagError,
                  style: const TextStyle(fontSize: 12, color: _red),
                ),
              ],
              const SizedBox(height: 12),

              // ── Tag pills ────────────────────────────────────────────────
              if (_tags.isNotEmpty) ...[
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _tags.map((tag) => _TagPill(
                    label: tag,
                    onRemove: () => _removeTag(tag),
                  )).toList(),
                ),
                const SizedBox(height: 16),
              ],

              // ── Suggestions label ────────────────────────────────────────
              const Text(
                'SUGGESTIONS',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 2,
                  color: _textMuted,
                ),
              ),
              const SizedBox(height: 8),

              // ── Suggestion chips ─────────────────────────────────────────
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _suggestions.map((s) => GestureDetector(
                  onTap: () => _addTag(s),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: _border),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '+ $s',
                      style: const TextStyle(
                        fontSize: 12,
                        color: _textMuted,
                      ),
                    ),
                  ),
                )).toList().cast<Widget>(),
              ),
              const SizedBox(height: 24),

              // ── Tips box ─────────────────────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: _border),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'tips for better matches',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'monospace',
                        letterSpacing: 0.5,
                        color: _textPrimary,
                      ),
                    ),
                    const Divider(height: 20),
                    _TipItem(
                      color: _red,
                      title: 'be specific, not generic',
                      description: 'Not "music" — "alt rock and music composition"',
                    ),
                    const SizedBox(height: 12),
                    _TipItem(
                      color: _orange,
                      title: 'share your current obsessions',
                      description: 'What can you not stop thinking about?',
                    ),
                    const SizedBox(height: 12),
                    _TipItem(
                      color: _red,
                      title: 'include your hot takes',
                      description: 'Strong opinions attract interesting people.',
                    ),
                    const Divider(height: 20),
                    const Text(
                      'up to 10 tags · 500 character bio',
                      style: TextStyle(
                        fontSize: 11,
                        color: _textMuted,
                        fontFamily: 'monospace',
                      ),
                    ),
                      // ── Leinecker easter egg ──────────────────
                          if (_leineckerMode) ...[
                            const Divider(height: 20),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.asset(
                                'assets/leinecker.png',
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Center(
                              child: Text(
                                '🤿 found the professor',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontStyle: FontStyle.italic,
                                  color: _textMuted,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ── Submit button ─────────────────────────────────
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed:
                            _isSubmitting ? null : _handleSubmit,
                        style: FilledButton.styleFrom(
                          backgroundColor: _orange,
                          padding:
                              const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'find my matches →',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Tag pill widget ───────────────────────────────────────────────────────────
class _TagPill extends StatelessWidget {
  final String label;
  final VoidCallback onRemove;

  const _TagPill({required this.label, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFFFE9E8),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFFE24B4A),
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(
              Icons.close,
              size: 14,
              color: Color(0xFFE24B4A),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Tip item widget ───────────────────────────────────────────────────────────
class _TipItem extends StatelessWidget {
  final Color color;
  final String title;
  final String description;

  const _TipItem({
    required this.color,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 4,
          height: 40,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'monospace',
                  color: Color(0xFF1A1714),
                ),
              ),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                  color: Color(0xFF888780),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Palm tree painter ─────────────────────────────────────────────────────────
class _PalmTreePainter extends CustomPainter {
  final bool flipped;
  const _PalmTreePainter({required this.flipped});

  @override
  void paint(Canvas canvas, Size size) {
    if (flipped) {
      canvas.translate(size.width, 0);
      canvas.scale(-1, 1);
    }

    final trunkPaint = Paint()
      ..color = const Color(0xFF5a3e1b)
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final frondPaint = Paint()
      ..color = const Color(0xFF2d6a2d)
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final frondPaint2 = Paint()
      ..color = const Color(0xFF3a8a3a)
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final coconutPaint = Paint()
      ..color = const Color(0xFF8B6914)
      ..style = PaintingStyle.fill;

    // Trunk
    final trunkPath = Path()
      ..moveTo(size.width * 0.48, size.height)
      ..cubicTo(
        size.width * 0.45, size.height * 0.75,
        size.width * 0.43, size.height * 0.5,
        size.width * 0.50, size.height * 0.25,
      );
    canvas.drawPath(trunkPath, trunkPaint);

    // Fronds
    final fronds = [
      [0.50, 0.25, 0.20, 0.05, -0.05, -0.10],
      [0.50, 0.25, 0.80, 0.05, 1.05, -0.10],
      [0.50, 0.25, 0.40, 0.00, 0.30, -0.15],
      [0.50, 0.25, 0.60, 0.00, 0.70, -0.15],
      [0.50, 0.25, 0.10, 0.20, -0.05, 0.18],
      [0.50, 0.25, 0.90, 0.20, 1.05, 0.18],
    ];

    for (final f in fronds) {
      final path = Path()
        ..moveTo(size.width * f[0], size.height * f[1])
        ..cubicTo(
          size.width * f[2], size.height * f[3],
          size.width * f[4], size.height * f[5],
          size.width * f[4], size.height * f[5],
        );
      canvas.drawPath(path, frondPaint);
    }

    // Inner fronds
    final innerFronds = [
      [0.50, 0.25, 0.45, 0.10, 0.38, 0.02],
      [0.50, 0.25, 0.55, 0.10, 0.63, 0.02],
    ];

    for (final f in innerFronds) {
      final path = Path()
        ..moveTo(size.width * f[0], size.height * f[1])
        ..cubicTo(
          size.width * f[2], size.height * f[3],
          size.width * f[4], size.height * f[5],
          size.width * f[4], size.height * f[5],
        );
      canvas.drawPath(path, frondPaint2);
    }

    // Coconuts
    canvas.drawCircle(
        Offset(size.width * 0.48, size.height * 0.28), 6, coconutPaint);
    canvas.drawCircle(
        Offset(size.width * 0.54, size.height * 0.30), 6, coconutPaint);
    canvas.drawCircle(
        Offset(size.width * 0.50, size.height * 0.33), 6, coconutPaint);
  }

  @override
  bool shouldRepaint(_PalmTreePainter oldDelegate) =>
      oldDelegate.flipped != flipped;
}