import 'package:flutter/material.dart';
import 'dart:math' as math;

/// ==================== ADVANCED CHAT FEATURES ====================
///
/// Premium UI Components:
/// 🎤 Voice Output Visualization (Audio Spectrum)
/// ⌨️ Typing Indicator with Animated Dots
/// 💬 Message Reactions (Like, Love, Laugh, etc.)
/// 🌊 Audio Waveform Player
/// ✨ Particle Effects
/// 🎯 Context Indicators
/// 📊 Sentiment Visualization
///
/// ==============================================================

// ==================== VOICE OUTPUT VISUALIZER ====================

class VoiceOutputVisualizer extends StatefulWidget {
  final bool isPlaying;
  final double intensity; // 0.0 to 1.0

  const VoiceOutputVisualizer({
    super.key,
    required this.isPlaying,
    this.intensity = 0.5,
  });

  @override
  State<VoiceOutputVisualizer> createState() => _VoiceOutputVisualizerState();
}

class _VoiceOutputVisualizerState extends State<VoiceOutputVisualizer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );

    if (widget.isPlaying) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(VoiceOutputVisualizer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying && !oldWidget.isPlaying) {
      _controller.repeat();
    } else if (!widget.isPlaying && oldWidget.isPlaying) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1A1E3A),
            const Color(0xFF0A0E27),
          ],
        ),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: const Color(0xFF00BFA5).withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
// Speaker icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF00BFA5),
                  const Color(0xFF00E5FF),
                ],
              ),
            ),
            child: Icon(
              widget.isPlaying ? Icons.volume_up : Icons.volume_off,
              color: Colors.white,
              size: 20,
            ),
          ),

          const SizedBox(width: 16),

// Audio bars
          Expanded(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(30, (index) {
                    final random = math.Random(index);
                    final baseHeight = 4.0 + random.nextDouble() * 10;
                    final animatedHeight = widget.isPlaying
                        ? baseHeight +
                        (math.sin(_controller.value * 2 * math.pi +
                            index * 0.5) *
                            15 *
                            widget.intensity)
                        : 4.0;

                    return Container(
                      width: 2,
                      height: animatedHeight.abs(),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            const Color(0xFF00BFA5),
                            const Color(0xFF00E5FF),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(2),
                        boxShadow: [
                          BoxShadow(
                            color:
                            const Color(0xFF00BFA5).withOpacity(0.5),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    );
                  }),
                );
              },
            ),
          ),

          const SizedBox(width: 16),

// Time/status
          Text(
            widget.isPlaying ? 'Speaking...' : 'Idle',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== TYPING INDICATOR ====================

class TypingIndicator extends StatefulWidget {
  final String userName;
  final bool showAvatar;

  const TypingIndicator({
    super.key,
    this.userName = 'Annie',
    this.showAvatar = true,
  });

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.showAvatar) ...[
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF00BFA5),
                    const Color(0xFF00E5FF),
                  ],
                ),
              ),
              child: const Icon(
                Icons.psychology,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
          ],

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1E3A),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
// Typing dots
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(3, (index) {
                    return AnimatedBuilder(
                      animation: _controller,
                      builder: (context, child) {
                        final delay = index * 0.2;
                        final value = (_controller.value + delay) % 1.0;
                        final opacity = 0.3 + (0.7 * math.sin(value * math.pi));
                        final scale =
                            0.7 + (0.3 * math.sin(value * math.pi));

                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          child: Opacity(
                            opacity: opacity,
                            child: Transform.scale(
                              scale: scale,
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: [
                                      const Color(0xFF00BFA5),
                                      const Color(0xFF00E5FF),
                                    ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF00BFA5)
                                          .withOpacity(0.5),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  }),
                ),

                const SizedBox(height: 4),

// Typing text
                Text(
                  '${widget.userName} is thinking...',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== MESSAGE REACTIONS ====================

class MessageReactions extends StatefulWidget {
  final Function(String reaction)? onReactionTap;
  final Map<String, int> reactions;

  const MessageReactions({
    super.key,
    this.onReactionTap,
    this.reactions = const {},
  });

  @override
  State<MessageReactions> createState() => _MessageReactionsState();
}

class _MessageReactionsState extends State<MessageReactions> {
  bool _showReactionPicker = false;

  final List<ReactionEmoji> _availableReactions = [
    ReactionEmoji('👍', 'thumbs_up', 'Like'),
    ReactionEmoji('❤️', 'heart', 'Love'),
    ReactionEmoji('😂', 'laugh', 'Funny'),
    ReactionEmoji('😮', 'wow', 'Wow'),
    ReactionEmoji('😢', 'sad', 'Sad'),
    ReactionEmoji('🙏', 'thanks', 'Thank You'),
    ReactionEmoji('💡', 'idea', 'Helpful'),
    ReactionEmoji('🎉', 'celebrate', 'Celebrate'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
// Existing reactions
        if (widget.reactions.isNotEmpty)
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: widget.reactions.entries.map((entry) {
              final emoji = _availableReactions.firstWhere(
                    (r) => r.id == entry.key,
                orElse: () => ReactionEmoji('❓', entry.key, 'Unknown'),
              );

              return _buildReactionChip(emoji, entry.value);
            }).toList(),
          ),

        const SizedBox(height: 8),

// Add reaction button
        GestureDetector(
          onTap: () {
            setState(() => _showReactionPicker = !_showReactionPicker);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1E3A),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF00BFA5).withOpacity(0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.add_reaction_outlined,
                  size: 16,
                  color: Colors.white.withOpacity(0.7),
                ),
                const SizedBox(width: 6),
                Text(
                  'React',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),

// Reaction picker
        if (_showReactionPicker) ...[
          const SizedBox(height: 12),
          _buildReactionPicker(),
        ],
      ],
    );
  }

  Widget _buildReactionChip(ReactionEmoji emoji, int count) {
    return GestureDetector(
      onTap: () => widget.onReactionTap?.call(emoji.id),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF00BFA5).withOpacity(0.2),
              const Color(0xFF00E5FF).withOpacity(0.2),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFF00BFA5).withOpacity(0.5),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              emoji.emoji,
              style: const TextStyle(fontSize: 16),
            ),
            if (count > 1) ...[
              const SizedBox(width: 6),
              Text(
                '$count',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildReactionPicker() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1E3A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF00BFA5).withOpacity(0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: _availableReactions.map((emoji) {
          return GestureDetector(
            onTap: () {
              widget.onReactionTap?.call(emoji.id);
              setState(() => _showReactionPicker = false);
            },
            child: Tooltip(
              message: emoji.label,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFF0A0E27),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF00BFA5).withOpacity(0.3),
                  ),
                ),
                child: Center(
                  child: Text(
                    emoji.emoji,
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class ReactionEmoji {
  final String emoji;
  final String id;
  final String label;

  ReactionEmoji(this.emoji, this.id, this.label);
}

// ==================== AUDIO WAVEFORM PLAYER ====================

class AudioWaveformPlayer extends StatefulWidget {
  final String audioUrl;
  final Duration duration;
  final bool isPlaying;
  final Function()? onPlayPause;

  const AudioWaveformPlayer({
    super.key,
    required this.audioUrl,
    required this.duration,
    this.isPlaying = false,
    this.onPlayPause,
  });

  @override
  State<AudioWaveformPlayer> createState() => _AudioWaveformPlayerState();
}

class _AudioWaveformPlayerState extends State<AudioWaveformPlayer>
    with SingleTickerProviderStateMixin {
  late AnimationController _progressController;
  double _progress = 0.0;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..addListener(() {
      setState(() => _progress = _progressController.value);
    });

    if (widget.isPlaying) {
      _progressController.forward();
    }
  }

  @override
  void didUpdateWidget(AudioWaveformPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying && !oldWidget.isPlaying) {
      _progressController.forward();
    } else if (!widget.isPlaying && oldWidget.isPlaying) {
      _progressController.stop();
    }
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1E3A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF00BFA5).withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
// Play/Pause button
          GestureDetector(
            onTap: widget.onPlayPause,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF00BFA5),
                    const Color(0xFF00E5FF),
                  ],
                ),
              ),
              child: Icon(
                widget.isPlaying ? Icons.pause : Icons.play_arrow,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),

          const SizedBox(width: 12),

// Waveform
          Expanded(
            child: CustomPaint(
              size: const Size(double.infinity, 40),
              painter: WaveformPainter(
                progress: _progress,
                isPlaying: widget.isPlaying,
              ),
            ),
          ),

          const SizedBox(width: 12),

// Duration
          Text(
            _formatDuration(widget.duration),
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
}

class WaveformPainter extends CustomPainter {
  final double progress;
  final bool isPlaying;

  WaveformPainter({required this.progress, required this.isPlaying});

  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(42);
    final barCount = 50;
    final barWidth = size.width / barCount;

    for (int i = 0; i < barCount; i++) {
      final barHeight = 10 + random.nextDouble() * (size.height - 10);
      final x = i * barWidth;
      final y = (size.height - barHeight) / 2;

      final paint = Paint()
        ..color = (i / barCount) < progress
            ? const Color(0xFF00BFA5)
            : const Color(0xFF00BFA5).withOpacity(0.3)
        ..style = PaintingStyle.fill;

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, barWidth - 2, barHeight),
          const Radius.circular(2),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(WaveformPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.isPlaying != isPlaying;
  }
}

// ==================== PARTICLE EFFECTS ====================

class MessageParticleEffect extends StatefulWidget {
  final Widget child;
  final bool trigger;

  const MessageParticleEffect({
    super.key,
    required this.child,
    this.trigger = false,
  });

  @override
  State<MessageParticleEffect> createState() => _MessageParticleEffectState();
}

class _MessageParticleEffectState extends State<MessageParticleEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<Particle> _particles = [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..addListener(() {
      setState(() {});
    });
  }

  @override
  void didUpdateWidget(MessageParticleEffect oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.trigger && !oldWidget.trigger) {
      _triggerParticles();
    }
  }

  void _triggerParticles() {
    _particles.clear();
    final random = math.Random();

    for (int i = 0; i < 20; i++) {
      _particles.add(Particle(
        x: random.nextDouble() * 100 - 50,
        y: random.nextDouble() * 100 - 50,
        size: 2 + random.nextDouble() * 4,
        color: i % 2 == 0
            ? const Color(0xFF00BFA5)
            : const Color(0xFF00E5FF),
      ));
    }

    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        widget.child,
        if (_particles.isNotEmpty)
          ...(_particles.map((particle) {
            return Positioned(
              left: particle.x * _controller.value,
              top: particle.y * _controller.value,
              child: Opacity(
                opacity: 1 - _controller.value,
                child: Container(
                  width: particle.size,
                  height: particle.size,
                  decoration: BoxDecoration(
                    color: particle.color,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: particle.color.withOpacity(0.5),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList()),
      ],
    );
  }
}

class Particle {
  final double x;
  final double y;
  final double size;
  final Color color;

  Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.color,
  });
}

// ==================== CONTEXT INDICATOR ====================

class ContextIndicator extends StatelessWidget {
  final String context;
  final IconData icon;
  final Color color;

  const ContextIndicator({
    super.key,
    required this.context,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            this.context,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  static ContextIndicator fromContextType(String contextType) {
    switch (contextType) {
      case 'emergency':
        return const ContextIndicator(
          context: 'Emergency',
          icon: Icons.warning,
          color: Color(0xFFFF4444),
        );
      case 'problem_solving':
        return const ContextIndicator(
          context: 'Problem Solving',
          icon: Icons.lightbulb,
          color: Color(0xFFFFAA00),
        );
      case 'companionship':
        return const ContextIndicator(
          context: 'Companion Mode',
          icon: Icons.favorite,
          color: Color(0xFFFF4081),
        );
      case 'planning':
        return const ContextIndicator(
          context: 'Planning',
          icon: Icons.calendar_today,
          color: Color(0xFF2196F3),
        );
      default:
        return const ContextIndicator(
          context: 'Casual',
          icon: Icons.chat,
          color: Color(0xFF00BFA5),
        );
    }
  }
}

// ==================== SENTIMENT VISUALIZATION ====================

class SentimentVisualization extends StatelessWidget {
  final String emotion;
  final double intensity; // 0.0 to 1.0

  const SentimentVisualization({
    super.key,
    required this.emotion,
    this.intensity = 0.5,
  });

  @override
  Widget build(BuildContext context) {
    final emotionData = _getEmotionData(emotion);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: emotionData.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: emotionData.color.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            emotionData.icon,
            color: emotionData.color,
            size: 20,
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                emotionData.label,
                style: TextStyle(
                  color: emotionData.color,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              SizedBox(
                width: 100,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: intensity,
                    backgroundColor: Colors.white.withOpacity(0.1),
                    valueColor: AlwaysStoppedAnimation(emotionData.color),
                    minHeight: 4,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  EmotionData _getEmotionData(String emotion) {
    switch (emotion.toLowerCase()) {
      case 'happy':
      case 'excited':
        return EmotionData(
          label: 'Happy',
          icon: Icons.sentiment_very_satisfied,
          color: const Color(0xFF4CAF50),
        );
      case 'sad':
        return EmotionData(
          label: 'Sad',
          icon: Icons.sentiment_dissatisfied,
          color: const Color(0xFF2196F3),
        );
      case 'anxious':
      case 'stressed':
        return EmotionData(
          label: 'Anxious',
          icon: Icons.sentiment_neutral,
          color: const Color(0xFFFF9800),
        );
      case 'angry':
        return EmotionData(
          label: 'Angry',
          icon: Icons.sentiment_very_dissatisfied,
          color: const Color(0xFFF44336),
        );
      case 'calm':
        return EmotionData(
          label: 'Calm',
          icon: Icons.spa,
          color: const Color(0xFF00BFA5),
        );
      default:
        return EmotionData(
          label: 'Neutral',
          icon: Icons.sentiment_neutral,
          color: const Color(0xFF9E9E9E),
        );
    }
  }
}

class EmotionData {
  final String label;
  final IconData icon;
  final Color color;

  EmotionData({
    required this.label,
    required this.icon,
    required this.color,
  });
}

// ==================== MESSAGE SWIPE ACTIONS ====================

class SwipeableMessage extends StatefulWidget {
  final Widget child;
  final VoidCallback? onSwipeLeft;
  final VoidCallback? onSwipeRight;

  const SwipeableMessage({
    super.key,
    required this.child,
    this.onSwipeLeft,
    this.onSwipeRight,
  });

  @override
  State<SwipeableMessage> createState() => _SwipeableMessageState();
}

class _SwipeableMessageState extends State<SwipeableMessage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _dragExtent = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragUpdate: (details) {
        setState(() {
          _dragExtent += details.delta.dx;
          _dragExtent = _dragExtent.clamp(-100.0, 100.0);
        });
      },
      onHorizontalDragEnd: (details) {
        if (_dragExtent < -50) {
          widget.onSwipeLeft?.call();
        } else if (_dragExtent > 50) {
          widget.onSwipeRight?.call();
        }

        setState(() => _dragExtent = 0);
      },
      child: Transform.translate(
        offset: Offset(_dragExtent * 0.3, 0),
        child: Stack(
          children: [
// Left action
            if (_dragExtent > 20)
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: Opacity(
                  opacity: (_dragExtent / 100).clamp(0.0, 1.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: const Icon(
                      Icons.reply,
                      color: Color(0xFF00BFA5),
                    ),
                  ),
                ),
              ),

// Right action
            if (_dragExtent < -20)
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                child: Opacity(
                  opacity: (-_dragExtent / 100).clamp(0.0, 1.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: const Icon(
                      Icons.favorite,
                      color: Color(0xFFFF4081),
                    ),
                  ),
                ),
              ),

// Message
            widget.child,
          ],
        ),
      ),
    );
  }
}