import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
import '../../core/constants.dart';

/// Logo tròn + tên ứng dụng dùng ở sidebar và header điện thoại.
class AppLogo extends StatelessWidget {
  final double size;
  final bool showName;
  final bool compact;

  const AppLogo({
    super.key,
    this.size = 42,
    this.showName = true,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final mark = Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.accent, AppColors.accentDeep],
        ),
        boxShadow: AppShadows.neuSoft,
      ),
      alignment: Alignment.center,
      child: Text(
        'X',
        style: TextStyle(
          fontSize: size * 0.46,
          height: 1,
          fontWeight: FontWeight.w900,
          color: AppColors.onBright,
        ),
      ),
    );

    if (!showName) return mark;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        mark,
        SizedBox(width: compact ? 10 : 12),
        Flexible(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppConstants.appName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: compact ? 16 : 17,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: 0.2,
                ),
              ),
              if (!compact)
                const Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: Text(
                    'QUẢN LÝ TÀI KHOẢN X',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 9.5,
                      letterSpacing: 1.1,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
