import 'dart:async';

import 'package:flutter/material.dart';

import '../models/clipboard_item.dart';
import '../services/localization.dart';
import 'clipboard_row.dart';
import 'search_and_filters.dart';

class ClipboardBody extends StatelessWidget {
  const ClipboardBody({
    super.key,
    required this.roomId,
    required this.clipboardStream,
    required this.lang,
    required this.isArchiveTab,
    required this.searchController,
    required this.searchQuery,
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
    required this.onCopy,
    required this.onTogglePin,
    required this.onDelete,
  });

  final String roomId;
  final Stream<List<ClipboardItem>> clipboardStream;
  final AppLang lang;
  final bool isArchiveTab;
  final TextEditingController searchController;
  final String searchQuery;
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

        return Column(
          children: [
            _pageTitle(items.length),
            _searchAndFilters(visibleItems),
            Expanded(child: _contentList(visibleItems, items)),
          ],
        );
      },
    );
  }

  Widget _pageTitle(int itemCount) {
    final title = isArchiveTab
        ? LocalizationService.get('archive')
        : LocalizationService.get('clipboard');

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 10, 24, 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${LocalizationService.get('room_short_label')} ${_compactRoomId(roomId)}',
                  style: TextStyle(
                    color: mutedTextColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: primaryColor.withValues(alpha: 0.24)),
            ),
            child: Text(
              LocalizationService.getFormatted('items_count_short', [
                '$itemCount',
              ]),
              style: TextStyle(
                color: primaryColor,
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _searchAndFilters(List<ClipboardItem> visibleItems) {
    return SearchAndFilters(
      searchController: searchController,
      searchQuery: searchQuery,
      surfaceColor: surfaceColor,
      softFillColor: softFillColor,
      borderColor: borderColor,
      primaryColor: primaryColor,
      textColor: textColor,
      mutedTextColor: mutedTextColor,
      onSearchChanged: onSearchChanged,
      onClearSearch: onClearSearch,
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
}
