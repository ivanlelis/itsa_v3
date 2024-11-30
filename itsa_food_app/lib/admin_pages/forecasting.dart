import 'package:flutter/material.dart';
import 'package:itsa_food_app/admin_pages/sales_tab.dart';

class ForecastingPage extends StatelessWidget {
  const ForecastingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Forecasting'),
      ),
      body: SalesTab(),
    );
  }
}
