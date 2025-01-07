import 'package:flutter/material.dart';

class AddOnSection extends StatefulWidget {
  final List<String> productTypes;
  final Function(List<String>) onAddOnsSelected;

  AddOnSection({required this.productTypes, required this.onAddOnsSelected});

  @override
  _AddOnSectionState createState() => _AddOnSectionState();
}

class _AddOnSectionState extends State<AddOnSection> {
  // Track selected add-ons separately for Takoyaki and Milk Tea
  final selectedTakoyakiAddOns = <String>{};
  final selectedMilkTeaAddOns = <String>{};

  @override
  Widget build(BuildContext context) {
    // Determine add-ons based on product types
    List<String> takoyakiAddOns = [];
    List<String> milkTeaAddOns = [];

    if (widget.productTypes.contains('Takoyaki')) {
      takoyakiAddOns.addAll(['Takoyaki Sauce', 'Bonito Flakes', 'Mayonnaise']);
    }
    if (widget.productTypes.contains('Milk Tea')) {
      milkTeaAddOns.addAll([
        'Black Pearls',
        'Cream Puff',
        'Nata',
        'Oreo Crushed',
        'Coffee Jelly',
      ]);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        const Text(
          'Add-ons',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),

        // Takoyaki Add-ons Card
        if (takoyakiAddOns.isNotEmpty)
          Card(
            elevation: 4,
            margin: const EdgeInsets.only(bottom: 16),
            child: ExpansionTile(
              title: const Text('Takoyaki Add-ons'),
              children: takoyakiAddOns.map((addOn) {
                return CheckboxListTile(
                  title: Text(addOn),
                  value: selectedTakoyakiAddOns.contains(addOn),
                  onChanged: (isSelected) {
                    setState(() {
                      if (isSelected == true) {
                        selectedTakoyakiAddOns.add(addOn);
                      } else {
                        selectedTakoyakiAddOns.remove(addOn);
                      }
                    });
                    widget.onAddOnsSelected(
                        [...selectedTakoyakiAddOns, ...selectedMilkTeaAddOns]);
                  },
                );
              }).toList(),
            ),
          ),

        // Milk Tea Add-ons Card
        if (milkTeaAddOns.isNotEmpty)
          Card(
            elevation: 4,
            margin: const EdgeInsets.only(bottom: 16),
            child: ExpansionTile(
              title: const Text('Milk Tea Add-ons'),
              children: milkTeaAddOns.map((addOn) {
                return CheckboxListTile(
                  title: Text(addOn),
                  value: selectedMilkTeaAddOns.contains(addOn),
                  onChanged: (isSelected) {
                    setState(() {
                      if (isSelected == true) {
                        selectedMilkTeaAddOns.add(addOn);
                      } else {
                        selectedMilkTeaAddOns.remove(addOn);
                      }
                    });
                    widget.onAddOnsSelected(
                        [...selectedTakoyakiAddOns, ...selectedMilkTeaAddOns]);
                  },
                );
              }).toList(),
            ),
          ),
      ],
    );
  }
}
