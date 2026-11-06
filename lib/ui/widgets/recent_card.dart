import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
import '../../core/constants.dart';
import '../../models/x_account.dart';
import 'neu_avatar.dart';
import 'neu_card.dart';

/// Thẻ tài khoản "mở gần đây" với số lần mở và thanh tiến trình.
class RecentCard extends StatelessWidget {
  final XAccount account;
  final double progress;
  final VoidCallback onTap;

  const RecentCard({
    super.key,
    required this.account,
    required this.onTap,
    this.progress = 0,
  });

  @override
  Widget build(BuildContext context) {
    final folderName = (account.folder == null || account.folder!.isEmpty)
        ? AppConstants.folderUncategorized
        : account.folder!;
    final value = progress.clamp(0.0, 1.0);

    return LayoutBuilder(
      builder: (context, constraints) {
        final tight = constraints.maxWidth < 190;
        final avatarSize = tight ? 35.0 : 44.0;
        final padding = tight ? 10.0 : 14.0;

        return NeuCard(
          onTap: onTap,
          radius: 18,
          padding: EdgeInsets.all(padding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  NeuAvatar(label: account.username, size: avatarSize),
                  SizedBox(width: tight ? 7 : 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          account.displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: tight ? 12.5 : 14,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          folderName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: tight ? 10.5 : 11.5,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${account.openCount}',
                        style: TextStyle(
                          fontSize: tight ? 15 : 18,
                          height: 1,
                          fontWeight: FontWeight.w800,
                          color: AppColors.accent,
                        ),
                      ),
                      if (tight)
                        const Text(
                          'lần',
                          style: TextStyle(
                            fontSize: 8.5,
                            height: 1.2,
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      if (!tight) ...[
                        const SizedBox(height: 2),
                        const Text(
                          'lần mở',
                          style: TextStyle(
                            fontSize: 9.5,
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
              const Spacer(),
              Row(
                children: [
                  if (!tight) ...[
                    const Icon(
                      Icons.history_rounded,
                      size: 13,
                      color: AppColors.textMuted,
                    ),
                    const SizedBox(width: 5),
                    const Text(
                      'Gần đây',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: value,
                        minHeight: 4,
                        backgroundColor: AppColors.surfaceSunken,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.accent,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
