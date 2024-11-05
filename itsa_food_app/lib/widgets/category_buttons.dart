// category_buttons_row.dart
import 'package:flutter/material.dart';
import 'package:itsa_food_app/customer_pages/menu.dart';

class CategoryButtonsRow extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onCategorySelected;

  const CategoryButtonsRow({
    super.key,
    required this.selectedIndex,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          CategoryButton(
            icon: Icons.fastfood, // Add appropriate icon for Takoyaki
            index: 0,
            selectedIndex: selectedIndex,
            onPressed: () => onCategorySelected(0),
          ),
          CategoryButton(
            icon: Icons.local_drink, // Add appropriate icon for Milk Tea
            index: 1,
            selectedIndex: selectedIndex,
            onPressed: () => onCategorySelected(1),
          ),
          CategoryButton(
            icon: Icons.restaurant, // Add appropriate icon for Meals
            index: 2,
            selectedIndex: selectedIndex,
            onPressed: () => onCategorySelected(2),
          ),
          // Add more CategoryButton instances as needed
        ],
      ),
    );
  }
}
