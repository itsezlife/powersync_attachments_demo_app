import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:powersync_attachments_example/src/app/bloc/app_bloc.dart';
import 'package:powersync_attachments_example/src/common/constant/app_spacing.dart';
import 'package:powersync_attachments_example/src/common/extensions/build_context_extension.dart';
import 'package:powersync_attachments_example/src/common/extensions/show_dialog_extension.dart';
import 'package:powersync_attachments_example/src/l10n/l10n.dart';
import 'package:powersync_attachments_example/src/menu/widgets/setting_tile.dart';

class LogOutTile extends StatelessWidget {
  const LogOutTile({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = context.theme;

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm, bottom: AppSpacing.sm),
      child: SettingTile.destructive(
        icon: Icons.logout_outlined,
        title: l10n.logOutLabel,
        tileColor: theme.colorScheme.surface,
        onTap: () {
          context.confirmAction(
            onConfirmed: () {
              context.read<AppBloc>().add(const AppLogoutRequested());
            },
            title: l10n.logOutLabel,
            content: l10n.logOutConfirmationLabel,
            configs: {
              DialogButtonType.confirm: DialogButtonConfig.confirm(
                text: l10n.logOutLabel,
              ),
            },
          );
        },
      ),
    );
  }
}
