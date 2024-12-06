import 'package:flutter/material.dart';

class DeliveryTypeSection extends StatelessWidget {
  final String deliveryType;
  final ValueChanged<String> onDeliveryTypeChange;

  const DeliveryTypeSection({
    super.key,
    required this.deliveryType,
    required this.onDeliveryTypeChange,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity, // Makes the card stretch to full available width
      margin: const EdgeInsets.symmetric(horizontal: 0.5, vertical: 4.0),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Delivery Type',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(
                  height: 8), // Spacing between the label and options
              InkWell(
                onTap: () => onDeliveryTypeChange('Standard'),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Standard (PHP 20.00)'),
                    Radio<String>(
                      value: 'Standard',
                      groupValue: deliveryType,
                      onChanged: (value) {
                        if (value != null) {
                          onDeliveryTypeChange(value);
                        }
                      },
                    ),
                  ],
                ),
              ),
              const Divider(), // Divider between Standard and Fast
              InkWell(
                onTap: () => onDeliveryTypeChange('Fast'),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Fast (PHP 20.00)'),
                    Radio<String>(
                      value: 'Fast',
                      groupValue: deliveryType,
                      onChanged: (value) {
                        if (value != null) {
                          onDeliveryTypeChange(value);
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
