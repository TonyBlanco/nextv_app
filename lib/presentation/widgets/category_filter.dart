import 'package:flutter/material.dart';
import '../../core/constants/nextv_colors.dart';
import '../../core/models/xtream_models.dart';

/// Category filter dialog for filtering channels by category
class CategoryFilterDialog extends StatelessWidget {
  final List<LiveCategory> categories;
  final String? selectedCategory;
  final Function(String?) onCategorySelected;

  const CategoryFilterDialog({
    super.key,
    required this.categories,
    this.selectedCategory,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: NextvColors.surface,
      title: const Text(
        'Filtrar por categoría',
        style: TextStyle(color: Colors.white),
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView(
          shrinkWrap: true,
          children: [
            ListTile(
              title: const Text(
                'Todas las categorías',
                style: TextStyle(color: Colors.white),
              ),
              leading: Radio<String?>(
                value: null,
                groupValue: selectedCategory,
                onChanged: (value) {
                  onCategorySelected(value);
                  Navigator.pop(context);
                },
                activeColor: NextvColors.accent,
              ),
            ),
            ...categories.map((category) {
              return ListTile(
                title: Text(
                  category.categoryName,
                  style: const TextStyle(color: Colors.white),
                ),
                leading: Radio<String?>(
                  value: category.categoryName,
                  groupValue: selectedCategory,
                  onChanged: (value) {
                    onCategorySelected(value);
                    Navigator.pop(context);
                  },
                  activeColor: NextvColors.accent,
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
