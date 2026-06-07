import 'package:flutter/material.dart';

import '../services/localization.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({
    super.key,
    required this.roomId,
    required this.isArchiveTab,
    required this.isSettingsTab,
    required this.primaryColor,
    required this.textColor,
    required this.mutedTextColor,
    required this.onConnectDevice,
    required this.onSelectClipboard,
    required this.onSelectArchive,
    required this.onSelectSettings,
  });

  final String roomId;
  final bool isArchiveTab;
  final bool isSettingsTab;
  final Color primaryColor;
  final Color textColor;
  final Color mutedTextColor;
  final VoidCallback onConnectDevice;
  final VoidCallback onSelectClipboard;
  final VoidCallback onSelectArchive;
  final VoidCallback onSelectSettings;

  @override
  Widget build(BuildContext context) {
    final isClipboardTab = !isArchiveTab && !isSettingsTab;
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          _Header(roomId: roomId, primaryColor: primaryColor),
          ListTile(
            leading: Icon(Icons.qr_code_rounded, color: primaryColor),
            title: Text(
              LocalizationService.get('connect_new_device'),
              style: TextStyle(color: textColor, fontWeight: FontWeight.w700),
            ),
            onTap: onConnectDevice,
          ),
          _navTile(
            icon: Icons.list,
            title: LocalizationService.get('clipboard'),
            selected: isClipboardTab,
            onTap: onSelectClipboard,
          ),
          _navTile(
            icon: Icons.archive,
            title: LocalizationService.get('archive'),
            selected: isArchiveTab,
            onTap: onSelectArchive,
          ),
          _navTile(
            icon: Icons.tune_rounded,
            title: LocalizationService.get('settings'),
            selected: isSettingsTab,
            onTap: onSelectSettings,
          ),
        ],
      ),
    );
  }

  Widget _navTile({
    required IconData icon,
    required String title,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: selected ? primaryColor : mutedTextColor),
      title: Text(
        title,
        style: TextStyle(color: selected ? primaryColor : textColor),
      ),
      selected: selected,
      onTap: onTap,
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.roomId, required this.primaryColor});

  final String roomId;
  final Color primaryColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 164,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [primaryColor, Theme.of(context).colorScheme.secondary],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      Theme.of(context).brightness == Brightness.dark
                          ? 'assets/logo_dark.png'
                          : 'assets/logo_light.png',
                      width: 42,
                      height: 42,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'BridgeClip',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 25,
                        height: 1.05,
                        fontWeight: FontWeight.w900,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Row(
                children: [
                  Expanded(
                    child: _HeaderChip(
                      icon: Icons.meeting_room_rounded,
                      text:
                          '${LocalizationService.get('room_short_label')} $roomId',
                    ),
                  ),
                  const SizedBox(width: 8),
                  _HeaderChip(
                    icon: Icons.check_circle_rounded,
                    text: LocalizationService.get('sync_ready'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderChip extends StatelessWidget {
  const _HeaderChip({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 210),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white.withValues(alpha: 0.88), size: 15),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.88),
                fontSize: 12,
                height: 1.1,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
