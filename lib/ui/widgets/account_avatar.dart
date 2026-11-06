import 'package:flutter/material.dart';
import '../../core/constants.dart';

/// Avatar hình chữ cái đầu của tài khoản (không tải ảnh từ mạng).
class AccountAvatar extends StatelessWidget {
  final String letter;
  final Color? color;
  final double size;

  const AccountAvatar({
    super.key,
    required this.letter,
    this.color,
    this.size = AppConstants.minTouchSize,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = color ?? Theme.of(context).colorScheme.primary.withOpacity(0.15);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(size / 2),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          width: 1,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        letter,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: size * 0.45,
          color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.9),
        ),
      ),
    );
  }
}
