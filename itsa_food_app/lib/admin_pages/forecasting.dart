import 'package:flutter/material.dart';
import 'package:itsa_food_app/admin_pages/sales_tab.dart';
import 'package:itsa_food_app/admin_pages/netprofit_tab.dart';

class ForecastingPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Forecasting'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Sales'),
              Tab(text: 'Net Profit'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            SalesTab(),
            NetProfitTab(),
          ],
        ),
      ),
    );
  }
}
