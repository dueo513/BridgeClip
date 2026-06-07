import 'dart:async';

import 'package:flutter/material.dart';

import '../models/clipboard_item.dart';
import '../services/localization.dart';
import 'clipboard_row.dart';
import 'header_action_button.dart';
import 'overview_header.dart';
import 'search_and_filters.dart';
import 'status_pill.dart';

class ClipboardBody extends StatelessWidget {
  const ClipboardBody({
    super.key,
    required this.roomId,
    required this.clipboardStream,
    required this.lang,
    required this.isArchiveTab,
    required this.notificationsEnabled,
    required this.autoDeleteMinutes,
    required this.searchController,
    required this.searchQuery,
    required this.deviceFilter,
    required this.timeFilter,
    required this.primaryColor,
    required this.surfaceColor,
    required this.softFillColor,
    required this.borderColor,
    required this.textColor,
    required this.mutedTextColor,
    required this.visibleItemsFor,
    required this.filteredItemsFor,
    required this.onSearchChanged,
    required this.onClearSearch,
    required this.onShowDeviceFilter,
    required this.onShowTimeFilter,
    required this.onClearFilters,
    required this.onConnectDevice,
    required this.onCopy,
    required this.onTogglePin,
    required this.onDelete,
  });

  final String roomId;
  final Stream<List<ClipboardItem>> clipboardStream;
  final AppLang lang;
  final bool isArchiveTab;
  final bool notificationsEnabled;
  final int autoDeleteMinutes;
  final TextEditingController searchController;
  final String searchQuery;
  final String deviceFilter;
  final String timeFilter;
  final Color primaryColor;
  final Color surfaceColor;
  final Color softFillColor;
  final Color borderColor;
  final Color textColor;
  final Color mutedTextColor;
  final List<ClipboardItem> Function(List<ClipboardItem> allItems)
  visibleItemsFor;
  final List<ClipboardItem> Function(List<ClipboardItem> visibleItems)
  filteredItemsFor;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearSearch;
  final FutureOr<void> Function(List<String> deviceOptions) onShowDeviceFilter;
  final FutureOr<void> Function() onShowTimeFilter;
  final VoidCallback onClearFilters;
  final VoidCallback onConnectDevice;
  final ValueChanged<ClipboardItem> onCopy;
  final ValueChanged<ClipboardItem> onTogglePin;
  final ValueChanged<ClipboardItem> onDelete;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ClipboardItem>>(
      stream: clipboardStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: primaryColor));
        }
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error: ${snapshot.error}',
              style: TextStyle(color: textColor),
            ),
          );
        }

        final visibleItems = visibleItemsFor(snapshot.data ?? []);
        final items = filteredItemsFor(visibleItems);
        final hasActiveFilters =
            searchQuery.isNotEmpty || deviceFilter != 'all' || timeFilter != 'all';

        return Column(
          children: [
            OverviewHeader(
              icon: isArchiveTab
                  ? Icons.archive_rounded
                  : Icons.content_paste_rounded,
              title: isArchiveTab
                  ? LocalizationService.get('archive')
                  : LocalizationService.get('clipboard'),
              subtitle:
                  '${LocalizationService.get('room_short_label')} ${_compactRoomId(roomId)}',
              pillsLabel: LocalizationService.get('status_summary'),
              pills: [
                StatusPill(
                  icon: Icons.layers_rounded,
                  label: LocalizationService.get('status_items'),
                  text: LocalizationService.getFormatted('items_count_short', [
                    '${items.length}',
                  ]),
                  primaryColor: primaryColor,
                  textColor: textColor,
                ),
                StatusPill(
                  icon: notificationsEnabled
                      ? Icons.notifications_active_rounded
                      : Icons.notifications_off_rounded,
                  label: LocalizationService.get('status_notifications'),
                  text: notificationsEnabled
                      ? LocalizationService.get('status_on')
                      : LocalizationService.get('status_off'),
                  primaryColor: primaryColor,
                  textColor: textColor,
                  color: notificationsEnabled ? Colors.green : Colors.orange,
                ),
                StatusPill(
                  icon: autoDeleteMinutes > 0
                      ? Icons.timer_rounded
                      : Icons.all_inclusive_rounded,
                  label: LocalizationService.get('status_auto_delete'),
                  text: _autoDeleteLabel(),
                  primaryColor: primaryColor,
                  textColor: textColor,
                  color: autoDeleteMinutes > 0 ? Colors.indigoAccent : null,
                ),
                if (hasActiveFilters)
                  StatusPill(
                    icon: Icons.filter_alt_rounded,
                    text: LocalizationService.get('filters_active'),
                    primaryColor: primaryColor,
                    textColor: textColor,
                    color: Colors.amber,
                  ),
              ],
              primaryColor: primaryColor,
              surfaceColor: surfaceColor,
              borderColor: borderColor,
              textColor: textColor,
              mutedTextColor: mutedTextColor,
              trailing: HeaderActionButton(
                icon: Icons.qr_code_rounded,
                label: LocalizationService.get('connect_new_device'),
                onPressed: onConnectDevice,
                primaryColor: primaryColor,
              ),
            ),
            _searchAndFilters(visibleItems),
            Expanded(child: _contentList(visibleItems, items)),
          ],
        );
      },
    );
  }

  Widget _searchAndFilters(List<ClipboardItem> visibleItems) {
    final deviceOptions = <String>[
      'all',
      ...visibleItems.map((item) => item.deviceName).toSet().toList()..sort(),
    ];
    if (deviceFilter != 'all' && !deviceOptions.contains(deviceFilter)) {
      deviceOptions.add(deviceFilter);
    }

    return SearchAndFilters(
      searchController: searchController,
      searchQuery: searchQuery,
      deviceFilter: deviceFilter,
      timeFilter: timeFilter,
      surfaceColor: surfaceColor,
      softFillColor: softFillColor,
      borderColor: borderColor,
      primaryColor: primaryColor,
      textColor: textColor,
      mutedTextColor: mutedTextColor,
      onSearchChanged: onSearchChanged,
      onClearSearch: onClearSearch,
      onShowDeviceFilter: () => onShowDeviceFilter(deviceOptions),
      onShowTimeFilter: onShowTimeFilter,
      onClearFilters: onClearFilters,
    );
  }

  Widget _contentList(
    List<ClipboardItem> visibleItems,
    List<ClipboardItem> items,
  ) {
    if (items.isEmpty) {
      return Center(
        child: Text(
          visibleItems.isEmpty
              ? (isArchiveTab
                    ? LocalizationService.get('empty_list_archive')
                    : LocalizationService.get('empty_list'))
              : LocalizationService.get('empty_filtered_list'),
          textAlign: TextAlign.center,
          style: TextStyle(color: mutedTextColor, fontSize: 16),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      itemCount: items.length,
      itemBuilder: (context, index) => _clipboardRow(items[index]),
    );
  }

  Widget _clipboardRow(ClipboardItem item) {
    return ClipboardRow(
      item: item,
      lang: lang,
      primaryColor: primaryColor,
      surfaceColor: surfaceColor,
      borderColor: borderColor,
      textColor: textColor,
      mutedTextColor: mutedTextColor,
      onCopy: () => onCopy(item),
      onTogglePin: () => onTogglePin(item),
      onDelete: () => onDelete(item),
    );
  }

  String _compactRoomId(String roomId) {
    if (roomId.length <= 18) return roomId;
    return '${roomId.substring(0, 11)}...${roomId.substring(roomId.length - 4)}';
  }

  String _autoDeleteLabel() {
    return switch (autoDeleteMinutes) {
      0 => LocalizationService.get('status_off'),
      1 => LocalizationService.get('timer_1m_short'),
      10 => LocalizationService.get('timer_10m_short'),
      60 => LocalizationService.get('timer_1h_short'),
      1440 => LocalizationService.get('timer_1d_short'),
      _ => LocalizationService.getFormatted('timer_minutes_short', [
        '$autoDeleteMinutes',
      ]),
    };
  }
}
