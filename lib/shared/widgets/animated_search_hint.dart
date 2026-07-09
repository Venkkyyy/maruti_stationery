import 'dart:async';
import 'package:flutter/material.dart';

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

class _AnimatedSearchHintState extends State<AnimatedSearchHint>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.hints.length > 1) {
      _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
        if (mounted) {
          setState(() {
            _currentIndex = (_currentIndex + 1) % widget.hints.length;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.hints.isEmpty) {
      return Text('Search products...', style: widget.style);
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Static "Search" prefix — never animates
          Text(
            'Search ',
            style: widget.style,
          ),
          // Only the hint word animates
          ClipRect(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              transitionBuilder: (Widget child, Animation<double> animation) {
                final slideIn = Tween<Offset>(
                  begin: const Offset(0.0, 0.8),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOut,
                ));
                final slideOut = Tween<Offset>(
                  begin: const Offset(0.0, -0.8),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeIn,
                ));

                return SlideTransition(
                  position: child.key == ValueKey<int>(_currentIndex)
                      ? slideIn
                      : slideOut,
                  child: FadeTransition(
                    opacity: animation,
                    child: child,
                  ),
                );
              },
              child: Text(
                '"${widget.hints[_currentIndex]}"',
                key: ValueKey<int>(_currentIndex),
                style: widget.style.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
