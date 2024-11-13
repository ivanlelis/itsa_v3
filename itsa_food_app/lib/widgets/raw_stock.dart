import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RawStock extends StatefulWidget {
  @override
  _RawStockState createState() => _RawStockState();
}

class _RawStockState extends State<RawStock> {
  final _nameController = TextEditingController();
  final _quantityController = TextEditingController();
  final _unitController = TextEditingController();
  final _lowStockAlertController = TextEditingController();

  String? _unitError;
  String? _lowStockAlertError;
  String? _nameError;
  String? _quantityError;

  final List<String> allowedUnits = [
    'kg',
    'ml',
    'pcs',
    'g',
    'grams',
    'l',
    'liters',
  ];

  String determineStockStatus(int quantity, double lowStockAlert) {
    if (quantity > lowStockAlert) return 'In Stock';
    if (quantity == lowStockAlert) return 'Low Stock';
    return 'Out of Stock';
  }

  bool validateInput() {
    setState(() {
      _unitError = null;
      _lowStockAlertError = null;
      _nameError = null;
      _quantityError = null;
    });

    String name = _nameController.text;
    String unit = _unitController.text;
    int quantity = int.tryParse(_quantityController.text) ?? 0;
    double lowStockAlert = double.tryParse(_lowStockAlertController.text) ?? 0;

    if (name.isEmpty) {
      _nameError = 'Required field';
    }
    if (quantity <= 0) {
      _quantityError = 'Required field';
    }
    if (unit.isEmpty || !allowedUnits.contains(unit)) {
      _unitError = 'Unit must be one of: kg, ml, pcs';
    }
    if (lowStockAlert <= 0) {
      _lowStockAlertError = 'Value must be greater than 0';
    }

    return _nameError == null &&
        _quantityError == null &&
        _unitError == null &&
        _lowStockAlertError == null;
  }

  Future<void> addRawMaterial() async {
    if (validateInput()) {
      String name = _nameController.text;
      int quantity = int.tryParse(_quantityController.text) ?? 0;
      String unit = _unitController.text;
      double lowStockAlert =
          double.tryParse(_lowStockAlertController.text) ?? 0;

      // Add to Firestore with document name as the material name
      await FirebaseFirestore.instance.collection('rawStock').doc(name).set({
        'matName': name,
        'quantity': quantity,
        'unit': unit,
        'stockAlert': lowStockAlert, // Store the decimal value
      });

      // Clear the input fields
      _nameController.clear();
      _quantityController.clear();
      _unitController.clear();
      _lowStockAlertController.clear();

      Navigator.pop(context); // Close the modal after adding
    }
  }

  void showViewItemModal(
      String name, int quantity, String unit, double lowStockAlert) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: 16),
              Text(
                'Raw Material Details',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              Divider(),
              ListTile(
                title: Text('Name: $name'),
              ),
              ListTile(
                title: Text('Quantity: $quantity'),
              ),
              ListTile(
                title: Text('Unit: $unit'),
              ),
              ListTile(
                title: Text('Low Stock Alert: $lowStockAlert'),
              ),
              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () async {
                      // Delete functionality: delete the material from Firestore using the document ID (name)
                      try {
                        await FirebaseFirestore.instance
                            .collection('rawStock')
                            .doc(
                                name) // Assuming 'name' is the identifier for the document
                            .delete();

                        // Show a confirmation message or perform any other actions as needed
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text('Material deleted successfully')),
                        );

                        Navigator.pop(
                            context); // Close the modal after deletion
                      } catch (e) {
                        // Handle any errors
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text('Error deleting material: $e')),
                        );
                      }
                    },
                    child: Text('Delete'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          Colors.red, // Set the button background color to red
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void showAddMaterialModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: 16),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Raw Material Name',
                  border: OutlineInputBorder(),
                  errorText: _nameError,
                ),
              ),
              SizedBox(height: 8),
              TextField(
                controller: _quantityController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Quantity',
                  border: OutlineInputBorder(),
                  errorText: _quantityError,
                ),
              ),
              SizedBox(height: 8),
              TextField(
                controller: _unitController,
                decoration: InputDecoration(
                  labelText: 'Unit (e.g., kg, pcs)',
                  border: OutlineInputBorder(),
                  errorText: _unitError,
                ),
              ),
              SizedBox(height: 8),
              TextField(
                controller: _lowStockAlertController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Low Stock Alert Threshold',
                  border: OutlineInputBorder(),
                  errorText: _lowStockAlertError,
                ),
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    validateInput();
                  });

                  if (_nameError == null &&
                      _quantityError == null &&
                      _unitError == null &&
                      _lowStockAlertError == null) {
                    addRawMaterial();
                  }
                },
                child: Text('Save'),
              ),
              SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Raw Materials Stock',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  Divider(),
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('rawStock')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return Center(child: CircularProgressIndicator());
                      }
                      final rawMaterials = snapshot.data!.docs;
                      if (rawMaterials.isEmpty) {
                        return Center(child: Text('No raw materials added.'));
                      }

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemCount: rawMaterials.length,
                        itemBuilder: (context, index) {
                          final rawMaterial = rawMaterials[index];
                          final name = rawMaterial['matName'];
                          final quantity = rawMaterial['quantity'];
                          final unit = rawMaterial['unit'];
                          final lowStockAlert =
                              (rawMaterial['stockAlert'] as num).toDouble();
                          final status =
                              determineStockStatus(quantity, lowStockAlert);

                          return Card(
                            elevation: 4,
                            margin: EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: ListTile(
                              title: Text(name),
                              subtitle: Text('Quantity: $quantity $unit'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    status,
                                    style: TextStyle(
                                      color: status == 'Out of Stock'
                                          ? Colors.red
                                          : (status == 'Low Stock'
                                              ? Colors.orange
                                              : Colors.green),
                                    ),
                                  ),
                                  SizedBox(
                                      width:
                                          8), // Space between the status and the button
                                  ElevatedButton(
                                    onPressed: () {
                                      // Open the modal when "View" button is pressed
                                      showViewItemModal(
                                        name,
                                        quantity,
                                        unit,
                                        lowStockAlert,
                                      );
                                    },
                                    child: Text('View'),
                                    style: ElevatedButton.styleFrom(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 6),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                  SizedBox(height: 16),
                  Center(
                    child: ElevatedButton.icon(
                      onPressed: showAddMaterialModal,
                      icon: Icon(Icons.add),
                      label: Text('Add Raw Material'),
                      style: ElevatedButton.styleFrom(
                        padding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _unitController.dispose();
    _lowStockAlertController.dispose();
    super.dispose();
  }
}
