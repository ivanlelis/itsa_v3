import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ProductFilterModal extends StatefulWidget {
  final List<String> selectedTags; // Pass selected tags from the parent
  final Function(List<String>) onApplyFilters;
  final Function onResetFilters;

  const ProductFilterModal({super.key, 
    required this.selectedTags, // Receive selected tags as a parameter
    required this.onApplyFilters,
    required this.onResetFilters,
  });

  @override
  _ProductFilterModalState createState() => _ProductFilterModalState();
}

class _ProductFilterModalState extends State<ProductFilterModal> {
  List<String> uniqueTags = [];
  late Map<String, bool> selectedTagsMap;

  @override
  void initState() {
    super.initState();
    selectedTagsMap = {}; // Initialize the selected tags map
    fetchUniqueTags();
  }

  Future<void> fetchUniqueTags() async {
    final querySnapshot =
        await FirebaseFirestore.instance.collection('products').get();
    final tagsSet = <String>{};

    for (var doc in querySnapshot.docs) {
      if (doc['tags'] != null) {
        List<dynamic> tags = doc['tags'];
        tagsSet.addAll(tags.cast<String>());
      }
    }

    setState(() {
      uniqueTags = tagsSet.toList();
      // Initialize the selected tags map based on the tags passed from the parent
      for (var tag in uniqueTags) {
        selectedTagsMap[tag] = widget.selectedTags.contains(tag);
      }
    });
  }

  void applyFilters() {
    final selectedFilters = selectedTagsMap.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList();
    widget.onApplyFilters(selectedFilters); // Notify parent with selected tags
    Navigator.pop(context); // Close the modal
  }

  void resetFilters() {
    setState(() {
      for (var tag in uniqueTags) {
        selectedTagsMap[tag] = false; // Deselect all tags
      }
    });
    widget.onResetFilters(); // Notify parent about the reset
    Navigator.pop(context); // Close the modal
  }

  @override
  Widget build(BuildContext context) {
    return uniqueTags.isEmpty
        ? const Center(child: CircularProgressIndicator())
        : Container(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Choose tags",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView(
                    shrinkWrap: true,
                    children: uniqueTags.map((tag) {
                      return CheckboxListTile(
                        title: Text(tag),
                        value: selectedTagsMap[tag],
                        onChanged: (bool? value) {
                          setState(() {
                            selectedTagsMap[tag] = value ?? false;
                          });
                        },
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton(
                      onPressed: resetFilters, // Reset all tag selections
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        "Reset tags",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: applyFilters, // Apply selected tags
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        "Apply tags",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
  }
}
