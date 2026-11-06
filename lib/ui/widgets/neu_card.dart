import 'package:flutter/material.dart';
import '../../core/app_theme.dart';

/// Bề mặt neumorphic dùng lại cho toàn bộ giao diện.
///
/// - Hai lớp bóng: tối phía dưới-phải và sáng phía trên-trái.
/// - Hover: nổi nhẹ; nhấn: lún xuống bằng [AnimatedContainer].
/// - [compactShadow] dùng bóng nhẹ hơn cho danh sách dài để cuộn mượt.
class NeuCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool selected;
  final bool compactShadow;
  final Color? color;
  final Color? borderColor;
  final double borderWidth;

  const NeuCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = 20,
    this.onTap,
    this.onLongPress,
    this.selected = false,
    this.compactShadow = false,
    this.color,
    this.borderColor,
    this.borderWidth = 1.2,
  });

  @override
  State<NeuCard> createState() => _NeuCardState();
}

class _NeuCardState extends State<NeuCard> {
  bool _hovered = false;
  bool _pressed = false;

  bool get _interactive => widget.onTap != null || widget.onLongPress != null;

  void _setPressed(bool value) {
    if (!_interactive || _pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final Color border = widget.selected
        ? AppColors.accent
        : (widget.borderColor ??
            (_hovered ? AppColors.outline : Colors.transparent));

    return MouseRegion(
      cursor: _interactive ? SystemMouseCursors.click : MouseCursor.defer,
      onEnter: (_) {
        if (_interactive) setState(() => _hovered = true);
      },
      onExit: (_) {
        if (_interactive) {
          setState(() {
            _hovered = false;
            _pressed = false;
          });
        }
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        onTapDown: _interactive ? (_) => _setPressed(true) : null,
        onTapUp: _interactive ? (_) => _setPressed(false) : null,
        onTapCancel: _interactive ? () => _setPressed(false) : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOut,
          padding: widget.padding,
          transform: Matrix4.translationValues(0, _pressed ? 1.5 : 0, 0),
          decoration: BoxDecoration(
            color: widget.color ?? AppColors.surface,
            borderRadius: BorderRadius.circular(widget.radius),
            border: Border.all(
              color: border,
              width: widget.selected ||
                      widget.borderColor != null ||
                      _hovered
                  ? widget.borderWidth
                  : 0,
            ),
            boxShadow: _pressed
                ? AppShadows.neuPressed
                : (widget.compactShadow ? AppShadows.neuSoft : AppShadows.neu),
          ),
          child: widget.child,
        ),
      ),
    );
  }
}
