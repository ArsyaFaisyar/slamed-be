import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Muncul dengan fade + geser halus; `index` memberi jeda bertahap pada daftar.
class FadeSlideIn extends StatefulWidget {
  const FadeSlideIn({super.key, required this.child, this.index = 0});
  final Widget child;
  final int index;

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn> {
  bool _show = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(milliseconds: 45 * math.min(widget.index, 8)), () {
      if (mounted) setState(() => _show = true);
    });
  }

  @override
  Widget build(BuildContext context) => AnimatedSlide(
        offset: _show ? Offset.zero : const Offset(0, 0.06),
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeOutCubic,
        child: AnimatedOpacity(
          opacity: _show ? 1 : 0,
          duration: const Duration(milliseconds: 380),
          child: widget.child,
        ),
      );
}