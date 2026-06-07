import 'package:flutter/material.dart';

import '../services/localization.dart';

class SearchAndFilters extends StatelessWidget {
  const SearchAndFilters({
    super.key,
    required this.searchController,
    required this.searchFocusNode,
    required this.searchQuery,
    required this.surfaceColor,
    required this.softFillColor,
    required this.borderColor,
    required this.primaryColor,
    required this.textColor,
    required this.mutedTextColor,
    required this.onSearchChanged,
    required this.onClearSearch,
  });

  final TextEditingController searchController;
  final FocusNode searchFocusNode;
  final String searchQuery;
  final Color surfaceColor;
  final Color softFillColor;
  final Color borderColor;
  final Color primaryColor;
  final Color textColor;
  final Color mutedTextColor;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearSearch;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: searchFocusNode.requestFocus,
        child: TextField(
          controller: searchController,
          focusNode: searchFocusNode,
          onTap: searchFocusNode.requestFocus,
          onChanged: onSearchChanged,
          keyboardType: TextInputType.text,
          textInputAction: TextInputAction.search,
          enableSuggestions: false,
          autocorrect: false,
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
      ),
    );
  }
}
