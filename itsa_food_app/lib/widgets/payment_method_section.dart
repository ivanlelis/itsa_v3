import 'package:flutter/material.dart';

class PaymentMethodSection extends StatefulWidget {
  final String paymentMethod;
  final Function(String) onPaymentMethodChange;
  final VoidCallback onGcashSelected;

  const PaymentMethodSection({
    super.key,
    required this.paymentMethod,
    required this.onPaymentMethodChange,
    required this.onGcashSelected,
  });

  @override
  _PaymentMethodSectionState createState() => _PaymentMethodSectionState();
}

class _PaymentMethodSectionState extends State<PaymentMethodSection> {
  void _handlePaymentMethodChange(String method) {
    widget.onPaymentMethodChange(method);

    if (method == 'GCash') {
      widget.onGcashSelected();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Payment Method',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
          ListTile(
            title: const Text('Cash'),
            trailing: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    widget.paymentMethod == 'Cash' ? Colors.green : Colors.grey,
              ),
              onPressed: () => _handlePaymentMethodChange('Cash'),
              child: Text(
                widget.paymentMethod == 'Cash' ? 'Selected' : 'Select',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
          const Divider(),
          ListTile(
            title: const Text('GCash'),
            trailing: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.paymentMethod == 'GCash'
                    ? Colors.green
                    : Colors.grey,
              ),
              onPressed: () => _handlePaymentMethodChange('GCash'),
              child: Text(
                widget.paymentMethod == 'GCash' ? 'Selected' : 'Select',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
          const Divider(),
          ListTile(
            title: const Text('PayPal'), // Added PayPal option
            trailing: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.paymentMethod == 'PayPal'
                    ? Colors.green
                    : Colors.grey,
              ),
              onPressed: () => _handlePaymentMethodChange('PayPal'),
              child: Text(
                widget.paymentMethod == 'PayPal' ? 'Selected' : 'Select',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
