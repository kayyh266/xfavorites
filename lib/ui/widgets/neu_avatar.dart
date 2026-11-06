import 'package:flutter/material.dart';
import '../../core/app_theme.dart';

/// Avatar tròn nổi kiểu neumorphic, chứa chữ cái đầu của username/folder.
///
/// Màu nền xen kẽ xanh ngọc / cam theo giá trị chuỗi (không tải ảnh từ mạng).
class NeuAvatar extends StatelessWidget {
  final String label;
  final double size;
  final bool outlined;

  const NeuAvatar({
    super.key,
    required this.label,
    this.size = 44,
    this.outlined = false,
  });

  /// Lấy chữ cái đầu tiên (bỏ ký tự @ và khoảng trắng).
  static String letterOf(String value) {
    final cleaned = value.trim().replaceFirst(RegExp(r'^@+'), '').trim();
    if (cleaned.isEmpty) return '?';
    return cleaned[0].toUpperCase();
  }

  /// Chọn màu xanh ngọc hoặc cam xen kẽ theo chuỗi.
  static Color colorFor(String value) {
    final normalized = value.trim().toLowerCase();
    var hash = 0;
    for (final code in normalized.codeUnits) {
      hash = (hash * 31 + code) & 0x7fffffff;
    }
    return hash.isEven ? AppColors.accent : AppColors.orange;
  }

  @override
  Widget build(BuildContext context) {
    final color = colorFor(label);
    final fontSize = size * 0.42;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(color, Colors.white, 0.16) ?? color,
            color,
            Color.lerp(color, Colors.black, 0.18) ?? color,
          ],
        ),
        border: outlined
            ? Border.all(color: AppColors.background, width: 3)
            : null,
        boxShadow: AppShadows.neuSoft,
      ),
      alignment: Alignment.center,
      child: Text(
        letterOf(label),
        maxLines: 1,
        style: TextStyle(
          fontSize: fontSize,
          height: 1,
          fontWeight: FontWeight.w800,
          color: AppColors.onBright,
        ),
      ),
    );
  }
}
