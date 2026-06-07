import 'package:flutter/material.dart';

import '../services/localization.dart';

class SearchAndFilters extends StatelessWidget {
  const SearchAndFilters({
    super.key,
    required this.searchController,
    required this.searchQuery,
    required this.deviceFilter,
    required this.timeFilter,
    required this.surfaceColor,
    required this.softFillColor,
    required this.borderColor,
    required this.primaryColor,
    required this.textColor,
    required this.mutedTextColor,
    required this.onSearchChanged,
    required this.onClearSearch,
    required this.onShowDeviceFilter,
    required this.onShowTimeFilter,
    required this.onClearFilters,
  });

  final TextEditingController searchController;
  final String searchQuery;
  final String deviceFilter;
  final String timeFilter;
  final Color surfaceColor;
  final Color softFillColor;
  final Color borderColor;
  final Color primaryColor;
  final Color textColor;
  final Color mutedTextColor;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearSearch;
  final VoidCallback onShowDeviceFilter;
  final VoidCallback onShowTimeFilter;
  final VoidCallback onClearFilters;

  @override
  Widget build(BuildContext context) {
    final hasActiveFilters =
        searchQuery.isNotEmpty || deviceFilter != 'all' || timeFilter != 'all';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          TextField(
            controller: searchController,
            onChanged: onSearchChanged,
            style: TextStyle(color: textColor),
            decoration: InputDecoration(
              prefixIcon: Icon(Icons.search, color: mutedTextColor),
              hintText: LocalizationService.get('search_clipboards'),
              hintStyle: TextStyle(color: textColor.withValues(alpha: 0.4)),
              filled: true,
              fillColor: softFillColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              suffixIcon: searchQuery.isEmpty
                  ? null
                  : IconButton(
                      icon: Icon(Icons.close, color: mutedTextColor),
                      onPressed: onClearSearch,
                    ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _FilterButton(
                  value: _deviceLabel(deviceFilter),
                  icon: Icons.devices,
                  onTap: onShowDeviceFilter,
                  softFillColor: softFillColor,
                  borderColor: borderColor,
                  primaryColor: primaryColor,
                  textColor: textColor,
                  mutedTextColor: mutedTextColor,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _FilterButton(
                  value: _timeLabel(timeFilter),
                  icon: Icons.schedule,
                  onTap: onShowTimeFilter,
                  softFillColor: softFillColor,
                  borderColor: borderColor,
                  primaryColor: primaryColor,
                  textColor: textColor,
                  mutedTextColor: mutedTextColor,
                ),
              ),
              if (hasActiveFilters) ...[
                const SizedBox(width: 8),
                IconButton(
                  tooltip: LocalizationService.get('clear_filters'),
                  icon: Icon(Icons.filter_alt_off, color: mutedTextColor),
                  onPressed: onClearFilters,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  String _deviceLabel(String value) {
    return value == 'all'
        ? LocalizationService.get('filter_all_devices')
        : value;
  }

  String _timeLabel(String value) {
    return switch (value) {
      'today' => LocalizationService.get('filter_today'),
      'week' => LocalizationService.get('filter_this_week'),
      _ => LocalizationService.get('filter_all_time'),
    };
  }
}

class _FilterButton extends StatelessWidget {
  const _FilterButton({
    required this.value,
    required this.icon,
    required this.onTap,
    required this.softFillColor,
    required this.borderColor,
    required this.primaryColor,
    required this.textColor,
    required this.mutedTextColor,
  });

  final String value;
  final IconData icon;
  final VoidCallback onTap;
  final Color softFillColor;
  final Color borderColor;
  final Color primaryColor;
  final Color textColor;
  final Color mutedTextColor;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: softFillColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            Icon(icon, color: primaryColor, size: 20),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: textColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Icon(Icons.keyboard_arrow_down_rounded, color: mutedTextColor),
          ],
        ),
      ),
    );
  }
}
