import 'package:flutter/material.dart';
import 'package:jamhorse/app/theme.dart';

/// The hover highlight, press compression, and tap/right-click plumbing
/// shared by Spotify-style cards and rows.
class Hoverable extends StatefulWidget {
  const Hoverable({
    required this.builder,
    super.key,
    this.onTap,
    this.onLongPress,
    this.onSecondaryTapUp,
    this.borderRadius = 8,
    this.hoverScale = 1,
    this.pressedScale = 0.985,
    this.semanticLabel,
    this.selected = false,
  });

  final Widget Function(BuildContext context, bool hovered) builder;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final GestureTapUpCallback? onSecondaryTapUp;
  final double borderRadius;
  final double hoverScale;
  final double pressedScale;
  final String? semanticLabel;
  final bool selected;

  @override
  State<Hoverable> createState() => _HoverableState();
}

class _HoverableState extends State<Hoverable> {
  var _hovered = false;
  var _pressed = false;

  void _setPressed(bool pressed) {
    if (_pressed != pressed) setState(() => _pressed = pressed);
  }

  @override
  Widget build(BuildContext context) {
    final Widget result = MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() {
        _hovered = false;
        _pressed = false;
      }),
      child: AnimatedScale(
        scale: _pressed
            ? widget.pressedScale
            : _hovered
            ? widget.hoverScale
            : 1,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutCubic,
        child: InkWell(
          onTap: widget.onTap,
          onLongPress: widget.onLongPress,
          onSecondaryTapUp: widget.onSecondaryTapUp,
          onTapDown: (_) => _setPressed(true),
          onTapUp: (_) => _setPressed(false),
          onTapCancel: () => _setPressed(false),
          borderRadius: BorderRadius.circular(widget.borderRadius),
          hoverColor: Colors.transparent,
          mouseCursor: SystemMouseCursors.click,
          child: widget.builder(context, _hovered),
        ),
      ),
    );
    if (widget.semanticLabel == null) return result;
    return Semantics(
      button: true,
      selected: widget.selected,
      label: widget.semanticLabel,
      child: result,
    );
  }
}

/// The green play button that rises into view on a hovered card.
class PlayOverlayButton extends StatelessWidget {
  const PlayOverlayButton({
    required this.visible,
    required this.onPressed,
    super.key,
    this.size = 48,
  });

  final bool visible;
  final VoidCallback onPressed;
  final double size;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: !visible,
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        offset: visible ? Offset.zero : const Offset(0, 0.3),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 140),
          opacity: visible ? 1 : 0,
          child: Material(
            color: JamColors.accent,
            elevation: 8,
            shadowColor: Colors.black87,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onPressed,
              child: Tooltip(
                message: 'Play',
                child: SizedBox.square(
                  dimension: size,
                  child: Icon(
                    Icons.play_arrow_rounded,
                    color: Colors.black,
                    size: size * 0.62,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Text that underlines on hover and navigates on click, like Spotify's
/// track and artist names.
class LinkText extends StatefulWidget {
  const LinkText(
    this.text, {
    super.key,
    this.onTap,
    this.style,
    this.maxLines = 1,
  });

  final String text;
  final VoidCallback? onTap;
  final TextStyle? style;
  final int maxLines;

  @override
  State<LinkText> createState() => _LinkTextState();
}

class _LinkTextState extends State<LinkText> {
  var _hovered = false;

  @override
  Widget build(BuildContext context) {
    final text = Text(
      widget.text,
      maxLines: widget.maxLines,
      overflow: TextOverflow.ellipsis,
      style: (widget.style ?? DefaultTextStyle.of(context).style).copyWith(
        decoration: _hovered ? TextDecoration.underline : null,
      ),
    );
    if (widget.onTap == null) return text;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(onTap: widget.onTap, child: text),
    );
  }
}
