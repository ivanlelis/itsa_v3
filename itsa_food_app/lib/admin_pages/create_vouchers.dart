// ignore_for_file: library_private_types_in_public_api, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class Vouchers extends StatefulWidget {
  const Vouchers({super.key});

  @override
  _VouchersState createState() => _VouchersState();
}

class _VouchersState extends State<Vouchers> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _voucherCodeController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _discountAmountController =
      TextEditingController();
  final TextEditingController _minimumSpendController = TextEditingController();
  final TextEditingController _maxDiscountController = TextEditingController();
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _expirationDateController =
      TextEditingController();
  final TextEditingController _usageLimitController = TextEditingController();
  final TextEditingController _overallLimitController = TextEditingController();

  String _discountType = 'Fixed Amount';

  Future<void> _createVoucher() async {
    if (_formKey.currentState!.validate()) {
      String voucherCode = _voucherCodeController.text;
      String description = _descriptionController.text;
      double discountAmount =
          double.tryParse(_discountAmountController.text) ?? 0;
      double minimumSpend = double.tryParse(_minimumSpendController.text) ?? 0;
      double maxDiscountCap = double.tryParse(_maxDiscountController.text) ?? 0;
      int usageLimit = int.tryParse(_usageLimitController.text) ?? 0;
      int overallLimit = int.tryParse(_overallLimitController.text) ?? 0;

      // Read dates from the uneditable fields
      DateTime startDate = _parseDate(_startDateController.text);
      DateTime expirationDate = _parseDate(_expirationDateController.text);

      CollectionReference vouchers = FirebaseFirestore.instance
          .collection('voucher'); // Updated to 'voucher'

      await vouchers.doc(voucherCode).set({
        // Use set() to create a document with the voucherCode
        'voucherCode': voucherCode,
        'description': description,
        'discountType': _discountType,
        'discountAmt': discountAmount,
        'minSpend': minimumSpend,
        'maxCap': maxDiscountCap,
        'startDate': startDate,
        'expDate': expirationDate,
        'userLimit': usageLimit,
        'usageLimit': overallLimit,
      });

      // Clear controllers
      _voucherCodeController.clear();
      _descriptionController.clear();
      _discountAmountController.clear();
      _minimumSpendController.clear();
      _maxDiscountController.clear();
      _startDateController.clear();
      _expirationDateController.clear();
      _usageLimitController.clear();
      _overallLimitController.clear();

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Voucher created successfully!')),
      );
    }
  }

  DateTime _parseDate(String date) {
    // Convert date from mm-dd-yyyy to DateTime
    final parts = date.split('-');
    if (parts.length == 3) {
      return DateTime(
          int.parse(parts[2]), int.parse(parts[0]), int.parse(parts[1]));
    }
    throw FormatException('Invalid date format');
  }

  void _showAddVoucherModal() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          content: Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Add New Voucher',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(height: 20),
                    _buildTextField(_voucherCodeController, 'Voucher Code',
                        'Please enter a voucher code'),
                    Text('Enter a unique code for the voucher.',
                        style: TextStyle(fontSize: 12, color: Colors.grey)),
                    SizedBox(height: 20),
                    _buildTextField(
                        _descriptionController, 'Description', null),
                    Text('Provide a brief description of the voucher.',
                        style: TextStyle(fontSize: 12, color: Colors.grey)),
                    SizedBox(height: 20),
                    _buildDropdownField(
                        'Discount Type',
                        ['Fixed Amount', 'Percentage'],
                        _discountType, (newValue) {
                      setState(() {
                        _discountType = newValue!;
                      });
                    }),
                    Text(
                        'Select whether the discount is a fixed amount or a percentage.',
                        style: TextStyle(fontSize: 12, color: Colors.grey)),
                    SizedBox(height: 20),
                    _buildTextField(
                        _discountAmountController,
                        'Discount Amount',
                        'Please enter a discount amount',
                        true),
                    Text('Enter the amount of discount to be applied.',
                        style: TextStyle(fontSize: 12, color: Colors.grey)),
                    SizedBox(height: 20),
                    _buildTextField(
                        _minimumSpendController, 'Minimum Spend', null, true),
                    Text('Set a minimum purchase amount to use this voucher.',
                        style: TextStyle(fontSize: 12, color: Colors.grey)),
                    SizedBox(height: 20),
                    _buildTextField(_maxDiscountController,
                        'Maximum Discount Cap', null, true),
                    Text(
                        'Enter the maximum discount amount this voucher can provide.',
                        style: TextStyle(fontSize: 12, color: Colors.grey)),
                    SizedBox(height: 20),
                    // Start Date Button
                    SizedBox(
                      width: double
                          .infinity, // Set to match the width of text fields
                      child: ElevatedButton(
                        onPressed: () => _selectStartDate(context),
                        child: Text(
                          _startDateController.text.isEmpty
                              ? 'Select Start Date'
                              : 'Change Start Date', // Change button text after selection
                        ),
                      ),
                    ),
                    Text('Specify when the voucher becomes valid.',
                        style: TextStyle(fontSize: 12, color: Colors.grey)),
                    SizedBox(height: 10),
                    // Uneditable Start Date Field
                    _buildTextField(_startDateController, 'Selected Start Date',
                        null, false), // Uneditable text field
                    SizedBox(height: 20),
                    // Expiration Date Button
                    SizedBox(
                      width: double
                          .infinity, // Set to match the width of text fields
                      child: ElevatedButton(
                        onPressed: () => _selectExpirationDate(context),
                        child: Text(
                          _expirationDateController.text.isEmpty
                              ? 'Select Expiration Date'
                              : 'Change Expiration Date', // Change button text after selection
                        ),
                      ),
                    ),
                    Text('Specify when the voucher will no longer be valid.',
                        style: TextStyle(fontSize: 12, color: Colors.grey)),
                    SizedBox(height: 10),
                    // Uneditable Expiration Date Field
                    _buildTextField(
                        _expirationDateController,
                        'Selected Expiration Date',
                        null,
                        false), // Uneditable text field
                    SizedBox(height: 20),
                    _buildTextField(_usageLimitController,
                        'Usage Limit Per User', null, true),
                    Text('Set how many times each user can use this voucher.',
                        style: TextStyle(fontSize: 12, color: Colors.grey)),
                    SizedBox(height: 20),
                    _buildTextField(_overallLimitController,
                        'Overall Usage Limit', null, true),
                    Text(
                        'Set the total number of times this voucher can be used.',
                        style: TextStyle(fontSize: 12, color: Colors.grey)),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _createVoucher,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.brown,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(
                        'Create Voucher',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _selectStartDate(BuildContext context) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    // Check if pickedDate is not null
    if (pickedDate != null) {
      setState(() {
        _startDateController.text = DateFormat('MM-dd-yyyy').format(pickedDate);
      });
    }
  }

  Future<void> _selectExpirationDate(BuildContext context) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );

    // Check if pickedDate is not null
    if (pickedDate != null) {
      setState(() {
        _expirationDateController.text =
            DateFormat('MM-dd-yyyy').format(pickedDate);
      });
    }
  }

  Widget _buildTextField(
      TextEditingController controller, String label, String? validatorMessage,
      [bool isNumeric = false, bool isRequired = true]) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
      inputFormatters: isNumeric
          ? [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))]
          : null,
      validator: (value) {
        if (isRequired && (value == null || value.isEmpty)) {
          return validatorMessage ?? 'This field is required';
        }
        if (isNumeric && value != null && double.tryParse(value) == null) {
          return 'Please enter a valid number';
        }
        return null;
      },
    );
  }

  Widget _buildDropdownField(String label, List<String> items,
      String currentValue, ValueChanged<String?> onChanged) {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      value: currentValue,
      items: items
          .map((item) => DropdownMenuItem(value: item, child: Text(item)))
          .toList(),
      onChanged: onChanged,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Vouchers'),
        backgroundColor: Color(0xFF2E0B0D),
        elevation: 0,
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('voucher')
            .snapshots(), // Updated to 'voucher'
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No vouchers available.'));
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final voucher = snapshot.data!.docs[index];
              return ListTile(
                title: Text(voucher['voucherCode']),
                subtitle: Text(voucher['description']),
                trailing: IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: () {
                    // Delete voucher logic
                    FirebaseFirestore.instance
                        .collection('voucher')
                        .doc(voucher.id)
                        .delete();
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddVoucherModal,
        child: Icon(Icons.add),
      ),
    );
  }
}
