import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show DateTimeRange;

/// Sort order options for catch-up programs
enum CatchupSortOrder {
  newestFirst,
  oldestFirst,
  channelName,
  programName,
}

/// Filter criteria for browsing catch-up programs
/// 
/// Used to filter and sort catch-up content in the dedicated section.
@immutable
class CatchupFilter {
  final String? category;
  final int? channelId;
  final DateTimeRange? dateRange;
  final String? searchQuery;
  final CatchupSortOrder sortOrder;

  const CatchupFilter({
    this.category,
    this.channelId,
    this.dateRange,
    this.searchQuery,
    this.sortOrder = CatchupSortOrder.newestFirst,
  });

  /// Check if any filter is active
  bool get hasActiveFilters {
    return category != null ||
        channelId != null ||
        dateRange != null ||
        (searchQuery != null && searchQuery!.isNotEmpty);
  }

  /// Create empty filter (no filters applied)
  factory CatchupFilter.empty() {
    return const CatchupFilter();
  }

  /// Create filter for specific channel
  factory CatchupFilter.forChannel(int channelId) {
    return CatchupFilter(channelId: channelId);
  }

  /// Create filter for specific category
  factory CatchupFilter.forCategory(String category) {
    return CatchupFilter(category: category);
  }

  /// Create filter for date range
  factory CatchupFilter.forDateRange(DateTimeRange dateRange) {
    return CatchupFilter(dateRange: dateRange);
  }

  /// Create a copy with updated fields
  CatchupFilter copyWith({
    String? category,
    int? channelId,
    DateTimeRange? dateRange,
    String? searchQuery,
    CatchupSortOrder? sortOrder,
    bool clearCategory = false,
    bool clearChannelId = false,
    bool clearDateRange = false,
    bool clearSearchQuery = false,
  }) {
    return CatchupFilter(
      category: clearCategory ? null : (category ?? this.category),
      channelId: clearChannelId ? null : (channelId ?? this.channelId),
      dateRange: clearDateRange ? null : (dateRange ?? this.dateRange),
      searchQuery: clearSearchQuery ? null : (searchQuery ?? this.searchQuery),
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  /// Clear all filters
  CatchupFilter clearAll() {
    return const CatchupFilter();
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CatchupFilter &&
        other.category == category &&
        other.channelId == channelId &&
        other.dateRange == dateRange &&
        other.searchQuery == searchQuery &&
        other.sortOrder == sortOrder;
  }

  @override
  int get hashCode {
    return Object.hash(
      category,
      channelId,
      dateRange,
      searchQuery,
      sortOrder,
    );
  }

  @override
  String toString() {
    final filters = <String>[];
    if (category != null) filters.add('category: $category');
    if (channelId != null) filters.add('channelId: $channelId');
    if (dateRange != null) {
      filters.add('dateRange: ${dateRange!.start} - ${dateRange!.end}');
    }
    if (searchQuery != null && searchQuery!.isNotEmpty) {
      filters.add('search: "$searchQuery"');
    }
    filters.add('sort: ${sortOrder.name}');
    
    return 'CatchupFilter(${filters.join(', ')})';
  }
}
