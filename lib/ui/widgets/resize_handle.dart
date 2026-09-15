import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// The gap between two desktop panels, draggable to resize them. Like
/// Spotify's, it shows a thin line while hovered or dragged.
class ResizeHandle extends StatefulWidget {
  const ResizeHandle({
    required this.onDragUpdate,
    super.key,
    this.onDragStart,
    this.onDragEnd,
    this.onDoubleTap,
    this.width = 8,
  });

  /// Horizontal distance from where the drag began, in logical pixels.
  /// Measured from the pointer-down position, so the drag slop is included
  /// and the edge stays under the cursor.
  final ValueChanged<double> onDragUpdate;
  final VoidCallback? onDragStart;
  final VoidCallback? onDragEnd;

  /// Usually restores the default width.
  final VoidCallback? onDoubleTap;
  final double width;

  @override
  State<ResizeHandle> createState() => _ResizeHandleState();
}

class _ResizeHandleState extends State<ResizeHandle> {
  var _hovered = false;
  var _dragging = false;
  double? _startX;

  void _endDrag() {
    if (!_dragging) return;
    setState(() => _dragging = false);
    widget.onDragEnd?.call();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.resizeColumn,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        // Report the start at pointer-down rather than after the drag slop,
        // so distance is measured from where the user grabbed the edge.
        dragStartBehavior: DragStartBehavior.down,
        onHorizontalDragStart: (details) {
          _startX = details.globalPosition.dx;
          setState(() => _dragging = true);
          widget.onDragStart?.call();
        },
        onHorizontalDragUpdate: (details) => widget.onDragUpdate(
          details.globalPosition.dx - (_startX ?? details.globalPosition.dx),
        ),
        onHorizontalDragEnd: (_) => _endDrag(),
        onHorizontalDragCancel: _endDrag,
        onDoubleTap: widget.onDoubleTap,
        child: SizedBox(
          width: widget.width,
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              width: _dragging ? 2 : 1,
              color: _dragging
                  ? Colors.white70
                  : _hovered
                  ? Colors.white38
                  : Colors.transparent,
            ),
          ),
        ),
      ),
    );
  }
}
