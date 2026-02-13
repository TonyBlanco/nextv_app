import 'package:flutter/material.dart';
import '../../core/constants/nextv_colors.dart';
import '../../core/models/catchup_filter.dart';

/// Filters bar for catch-up TV with category, date range, and search
class CatchupFiltersBar extends StatefulWidget {
  final CatchupFilter currentFilter;
  final List<String> categories;
  final Function(CatchupFilter) onFilterChanged;

  const CatchupFiltersBar({
    super.key,
    required this.currentFilter,
    required this.categories,
    required this.onFilterChanged,
  });

  @override
  State<CatchupFiltersBar> createState() => _CatchupFiltersBarState();
}

class _CatchupFiltersBarState extends State<CatchupFiltersBar> {
  final TextEditingController _searchController = TextEditingController();
  String? _selectedCategory;
  DateTimeRange? _selectedDateRange;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.currentFilter.category;
    _selectedDateRange = widget.currentFilter.dateRange;
    _searchController.text = widget.currentFilter.searchQuery ?? '';
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: NextvColors.surface,
        border: Border(
          bottom: BorderSide(color: NextvColors.background, width: 1),
        ),
      ),
      child: Row(
        children: [
          // Category filter
          _buildCategoryFilter(),
          const SizedBox(width: 12),
          // Date range filter
          _buildDateRangeFilter(),
          const SizedBox(width: 12),
          // Search
          Expanded(
            child: _buildSearchField(),
          ),
          const SizedBox(width: 12),
          // Clear filters button
          if (widget.currentFilter.hasActiveFilters)
            _buildClearButton(),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: NextvColors.background,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: _selectedCategory != null 
              ? NextvColors.accent 
              : Colors.white24,
          width: 1,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: _selectedCategory,
          hint: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.category_outlined, size: 16, color: Colors.white60),
              SizedBox(width: 6),
              Text(
                'Categoría',
                style: TextStyle(color: Colors.white60, fontSize: 13),
              ),
            ],
          ),
          icon: const Icon(Icons.arrow_drop_down, color: Colors.white60, size: 20),
          dropdownColor: NextvColors.surface,
          style: const TextStyle(color: Colors.white, fontSize: 13),
          items: [
            const DropdownMenuItem<String?>(
              value: null,
              child: Text('Todas las categorías'),
            ),
            ...widget.categories.map((category) {
              return DropdownMenuItem<String?>(
                value: category,
                child: Text(category),
              );
            }),
          ],
          onChanged: (value) {
            setState(() {
              _selectedCategory = value;
            });
            _applyFilters();
          },
        ),
      ),
    );
  }

  Widget _buildDateRangeFilter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: NextvColors.background,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: _selectedDateRange != null 
              ? NextvColors.accent 
              : Colors.white24,
          width: 1,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _getDateRangeKey(),
          hint: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.calendar_today, size: 16, color: Colors.white60),
              SizedBox(width: 6),
              Text(
                'Fecha',
                style: TextStyle(color: Colors.white60, fontSize: 13),
              ),
            ],
          ),
          icon: const Icon(Icons.arrow_drop_down, color: Colors.white60, size: 20),
          dropdownColor: NextvColors.surface,
          style: const TextStyle(color: Colors.white, fontSize: 13),
          items: const [
            DropdownMenuItem(value: 'all', child: Text('Todos los días')),
            DropdownMenuItem(value: 'today', child: Text('Hoy')),
            DropdownMenuItem(value: 'yesterday', child: Text('Ayer')),
            DropdownMenuItem(value: 'last3', child: Text('Últimos 3 días')),
            DropdownMenuItem(value: 'last7', child: Text('Últimos 7 días')),
          ],
          onChanged: (value) {
            setState(() {
              final now = DateTime.now();
              final today = DateTime(now.year, now.month, now.day);
              
              switch (value) {
                case 'all':
                  _selectedDateRange = null;
                  break;
                case 'today':
                  _selectedDateRange = DateTimeRange(
                    start: today,
                    end: today.add(const Duration(days: 1)),
                  );
                  break;
                case 'yesterday':
                  final yesterday = today.subtract(const Duration(days: 1));
                  _selectedDateRange = DateTimeRange(
                    start: yesterday,
                    end: today,
                  );
                  break;
                case 'last3':
                  _selectedDateRange = DateTimeRange(
                    start: today.subtract(const Duration(days: 3)),
                    end: today.add(const Duration(days: 1)),
                  );
                  break;
                case 'last7':
                  _selectedDateRange = DateTimeRange(
                    start: today.subtract(const Duration(days: 7)),
                    end: today.add(const Duration(days: 1)),
                  );
                  break;
              }
            });
            _applyFilters();
          },
        ),
      ),
    );
  }

  String _getDateRangeKey() {
    if (_selectedDateRange == null) return 'all';
    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    
    if (_selectedDateRange!.start.isAtSameMomentAs(today)) {
      return 'today';
    } else if (_selectedDateRange!.start.isAtSameMomentAs(yesterday)) {
      return 'yesterday';
    } else if (_selectedDateRange!.duration.inDays == 3) {
      return 'last3';
    } else if (_selectedDateRange!.duration.inDays == 7) {
      return 'last7';
    }
    
    return 'all';
  }

  Widget _buildSearchField() {
    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: NextvColors.background,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: _searchController.text.isNotEmpty 
              ? NextvColors.accent 
              : Colors.white24,
          width: 1,
        ),
      ),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(color: Colors.white, fontSize: 13),
        decoration: InputDecoration(
          hintText: 'Buscar programas...',
          hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
          prefixIcon: const Icon(Icons.search, color: Colors.white60, size: 18),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.white60, size: 18),
                  onPressed: () {
                    _searchController.clear();
                    _applyFilters();
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
        onChanged: (value) {
          // Debounce search
          Future.delayed(const Duration(milliseconds: 500), () {
            if (_searchController.text == value) {
              _applyFilters();
            }
          });
        },
      ),
    );
  }

  Widget _buildClearButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _clearFilters,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white24, width: 1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.clear_all, size: 16, color: Colors.white60),
              SizedBox(width: 4),
              Text(
                'Limpiar',
                style: TextStyle(color: Colors.white60, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _applyFilters() {
    final newFilter = CatchupFilter(
      category: _selectedCategory,
      dateRange: _selectedDateRange,
      searchQuery: _searchController.text.isEmpty ? null : _searchController.text,
      sortOrder: widget.currentFilter.sortOrder,
    );
    
    widget.onFilterChanged(newFilter);
  }

  void _clearFilters() {
    setState(() {
      _selectedCategory = null;
      _selectedDateRange = null;
      _searchController.clear();
    });
    
    widget.onFilterChanged(CatchupFilter.empty());
  }
}
