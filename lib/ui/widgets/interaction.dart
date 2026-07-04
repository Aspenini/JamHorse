import 'package:flutter/material.dart';

/// A restrained Spotify-style hover lift with tactile pointer compression.
///
/// This observes pointer events without participating in hit testing, so the
/// wrapped control keeps its own semantics, focus handling, and callbacks.
class HoverScale extends StatefulWidget {
  const HoverScale({
    required this.child,
    super.key,
    this.enabled = true,
    this.hoverScale = 1.045,
    this.pressedScale = 0.965,
    this.duration = const Duration(milliseconds: 150),
  });

  final Widget child;
  final bool enabled;
  final double hoverScale;
  final double pressedScale;
  final Duration duration;

  @override
  State<HoverScale> createState() => _HoverScaleState();
}

class _HoverScaleState extends State<HoverScale> {
  var _hovered = false;
  var _pressed = false;

  @override
  Widget build(BuildContext context) {
    final scale = !widget.enabled
        ? 1.0
        : _pressed
        ? widget.pressedScale
        : _hovered
        ? widget.hoverScale
        : 1.0;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() {
        _hovered = false;
        _pressed = false;
      }),
      child: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: widget.enabled
            ? (_) => setState(() => _pressed = true)
            : null,
        onPointerUp: widget.enabled
            ? (_) => setState(() => _pressed = false)
            : null,
        onPointerCancel: widget.enabled
            ? (_) => setState(() => _pressed = false)
            : null,
        child: AnimatedScale(
          scale: scale,
          duration: widget.duration,
          curve: _pressed ? Curves.easeOutCubic : Curves.easeOutBack,
          child: widget.child,
        ),
      ),
    );
  }
}

/// Replays a short entrance whenever [watchKey] changes without retaining the
/// outgoing child. This is useful for media/route changes where duplicate Hero
/// tags would make a two-child [AnimatedSwitcher] unsafe.
class EntranceMotion extends StatefulWidget {
  const EntranceMotion({
    required this.watchKey,
    required this.child,
    super.key,
    this.duration = const Duration(milliseconds: 240),
  });

  final Object watchKey;
  final Widget child;
  final Duration duration;

  @override
  State<EntranceMotion> createState() => _EntranceMotionState();
}

class _EntranceMotionState extends State<EntranceMotion>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _position;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);
    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    _position = Tween<Offset>(
      begin: const Offset(0, 0.012),
      end: Offset.zero,
    ).animate(_opacity);
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant EntranceMotion oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.watchKey != widget.watchKey) {
      _controller
        ..value = 0
        ..forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(position: _position, child: widget.child),
    );
  }
}
