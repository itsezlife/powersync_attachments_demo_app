import 'package:flutter/material.dart';
import 'package:powersync_attachments_example/src/common/extensions/build_context_extension.dart';

enum SettingTileType {
  destructive,
  normal,
  primary;

  bool get isDestructive => this == SettingTileType.destructive;
  bool get isPrimary => this == SettingTileType.primary;
}

class SettingTile extends StatelessWidget {
  const SettingTile({
    required this.title,
    required this.icon,
    this.onTap,
    this.subtitle,
    super.key,
    this.tileColor,
    this.trailing,
    this.iconColor,
    this.textColor,
  }) : _type = SettingTileType.normal;

  const SettingTile.destructive({
    required this.title,
    required this.icon,
    required this.onTap,
    this.subtitle,
    super.key,
    this.tileColor,
    this.trailing,
    this.iconColor,
    this.textColor,
  }) : _type = SettingTileType.destructive;

  const SettingTile.primary({
    required this.title,
    required this.icon,
    required this.onTap,
    this.subtitle,
    super.key,
    this.tileColor,
    this.trailing,
    this.iconColor,
    this.textColor,
  }) : _type = SettingTileType.primary;

  final String title;
  final String? subtitle;
  final IconData icon;
  final Color? iconColor;
  final Color? textColor;
  final Widget? trailing;
  final VoidCallback? onTap;
  final SettingTileType _type;
  final Color? tileColor;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final textTheme = theme.textTheme;

    final colorScheme = theme.colorScheme;

    final textColor =
        this.textColor ??
        (_type.isPrimary
            ? colorScheme.primary
            : (_type.isDestructive ? colorScheme.error : null));

    final iconColor =
        this.iconColor ??
        (_type.isPrimary
            ? colorScheme.primary
            : (_type.isDestructive ? colorScheme.error : null));

    // final splashColor = _type.isDestructive
    //     ? context.theme.colorScheme.error.withValues(alpha: 0.4)
    //     : null;

    return ListTile(
      onTap: onTap,
      textColor: textColor,
      iconColor: iconColor,
      leading: Icon(icon),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle!) : null,
      titleTextStyle: textTheme.titleMedium!.copyWith(
        color: textColor,
        fontWeight: _type.isPrimary ? FontWeight.bold : null,
      ),
      titleAlignment: ListTileTitleAlignment.titleHeight,
      // splashColor: splashColor,
      tileColor: tileColor ?? context.theme.colorScheme.surfaceContainer,
      trailing: trailing,
      leadingAndTrailingTextStyle: textTheme.titleMedium!.copyWith(
        color: colorScheme.primary,
      ),
    );
  }
}
