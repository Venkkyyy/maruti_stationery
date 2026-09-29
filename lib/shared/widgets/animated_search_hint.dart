import 'dart:async';
import 'package:flutter/material.dart';

/// Shows search hints as a typewriter animation:
///   "p" → "pe" → "pen" → "pens" → pause → erases → next hint
class AnimatedSearchHint extends StatefulWidget {
  final List<String> hints;
  final TextStyle style;

  const AnimatedSearchHint({
    super.key,
    required this.hints,
    required this.style,
  });

  @override
  State<AnimatedSearchHint> createState() => _AnimatedSearchHintState();
}

class _AnimatedSearchHintState extends State<AnimatedSearchHint> {
  // How many characters of the current hint to show
  int _charCount = 0;
  int _hintIndex = 0;
  bool _erasing = false;

  Timer? _timer;

  // Timings (tweak freely)
  static const Duration _typingSpeed  = Duration(milliseconds: 80);
  static const Duration _erasingSpeed = Duration(milliseconds: 50);
  static const Duration _pauseAfterType  = Duration(milliseconds: 1400);
  static const Duration _pauseAfterErase = Duration(milliseconds: 300);

  @override
  void initState() {
    super.initState();
    if (widget.hints.isNotEmpty) {
      _scheduleNextChar();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(AnimatedSearchHint oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.hints != oldWidget.hints) {
      if (widget.hints.isEmpty) {
        _timer?.cancel();
        _charCount = 0;
        _hintIndex = 0;
      } else {
        if (_hintIndex >= widget.hints.length) {
          _hintIndex = 0;
        }
        if (_charCount > _currentHint.length) {
          _charCount = _currentHint.length;
        }
      }
    }
  }

  String get _currentHint => widget.hints[_hintIndex];

  void _scheduleNextChar() {
    if (!mounted) return;

    if (!_erasing) {
      // ── Typing phase ──────────────────────────────────
      if (_charCount < _currentHint.length) {
        _timer = Timer(_typingSpeed, () {
          if (!mounted) return;
          setState(() => _charCount++);
          _scheduleNextChar();
        });
      } else {
        // Finished typing — pause then start erasing
        _timer = Timer(_pauseAfterType, () {
          if (!mounted) return;
          setState(() => _erasing = true);
          _scheduleNextChar();
        });
      }
    } else {
      // ── Erasing phase ─────────────────────────────────
      if (_charCount > 0) {
        _timer = Timer(_erasingSpeed, () {
          if (!mounted) return;
          setState(() => _charCount--);
          _scheduleNextChar();
        });
      } else {
        // Fully erased — pause then move to next hint
        _timer = Timer(_pauseAfterErase, () {
          if (!mounted) return;
          setState(() {
            _erasing = false;
            _hintIndex = (_hintIndex + 1) % widget.hints.length;
          });
          _scheduleNextChar();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.hints.isEmpty) {
      return Text('Search products...', style: widget.style);
    }

    final displayedText = _currentHint.substring(0, _charCount);

    return Align(
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Static "Search " prefix
          Text('Search ', style: widget.style),
          // Typed text
          Text(
            '"$displayedText',
            style: widget.style.copyWith(fontWeight: FontWeight.w600),
          ),
          // Blinking cursor
          _BlinkingCursor(style: widget.style),
          // Closing quote — only shown when fully typed
          if (_charCount == _currentHint.length && !_erasing)
            Text('"', style: widget.style.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ── Blinking cursor ──────────────────────────────────────────────────────

class _BlinkingCursor extends StatefulWidget {
  final TextStyle style;
  const _BlinkingCursor({required this.style});

  @override
  State<_BlinkingCursor> createState() => _BlinkingCursorState();
}

class _BlinkingCursorState extends State<_BlinkingCursor>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: Text('|', style: widget.style.copyWith(fontWeight: FontWeight.w300)),
    );
  }
}
