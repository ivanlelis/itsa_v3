import 'package:flutter/material.dart';
import 'package:itsa_food_app/customer_pages/cart.dart';

class ProductView extends StatefulWidget {
  final String productName;
  final String imageUrl;
  final String? takoyakiPrices;
  final String? takoyakiPrices8;
  final String? takoyakiPrices12;
  final String? milkTeaSmall;
  final String? milkTeaMedium;
  final String? milkTeaLarge;
  final String? mealsPrice;
  final String? userName; // Nullable
  final String? email; // Nullable
  final String productType; // Non-nullable

  const ProductView({
    Key? key,
    required this.productName,
    required this.imageUrl,
    this.takoyakiPrices,
    this.takoyakiPrices8,
    this.takoyakiPrices12,
    this.milkTeaSmall,
    this.milkTeaMedium,
    this.milkTeaLarge,
    this.mealsPrice,
    this.userName, // Make this nullable
    this.email, // Make this nullable
    required this.productType,
  }) : super(key: key);

  @override
  _ProductViewState createState() => _ProductViewState();
}

class _ProductViewState extends State<ProductView> {
  int _selectedQuantityIndex = 0;
  int _quantity = 1;
  double _totalPrice = 0.0;
  bool _takoyakiSauce = false;
  bool _bonitoFlakes = false;
  bool _mayonnaise = false;

  List<String> quantityOptions = [];
  List<String> prices = [];

  @override
  void initState() {
    super.initState();
    if (widget.takoyakiPrices != null) {
      quantityOptions = ['4 pcs', '8 pcs', '12 pcs'];
      prices = [
        widget.takoyakiPrices ?? '0',
        widget.takoyakiPrices8 ?? '0',
        widget.takoyakiPrices12 ?? '0',
      ];
    } else if (widget.mealsPrice != null) {
      quantityOptions = ['Price'];
      prices = [widget.mealsPrice ?? '0'];
    } else if (widget.milkTeaSmall != null) {
      quantityOptions = ['Small', 'Medium', 'Large'];
      prices = [
        widget.milkTeaSmall ?? '0',
        widget.milkTeaMedium ?? '0',
        widget.milkTeaLarge ?? '0',
      ];
    }
    assert(quantityOptions.length == prices.length);
    _totalPrice = double.parse(prices[_selectedQuantityIndex]);
  }

  void _updateTotalPrice() {
    double basePrice = double.parse(prices[_selectedQuantityIndex]);
    double addOnsPrice = (_takoyakiSauce ? 15 : 0) +
        (_bonitoFlakes ? 15 : 0) +
        (_mayonnaise ? 15 : 0);
    setState(() {
      _totalPrice = (basePrice + addOnsPrice) * _quantity;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.network(
              widget.imageUrl,
              height: 250,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
            // Display the current username and email
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.productName,
                    style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8.0),
                  Text(
                    '₱${prices[_selectedQuantityIndex]}',
                    style: const TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 16.0),

                  Text('Choose Quantity/Size:',
                      style: const TextStyle(fontSize: 16)),
                  ...List.generate(quantityOptions.length, (index) {
                    return RadioListTile<int>(
                      value: index,
                      groupValue: _selectedQuantityIndex,
                      title:
                          Text('${quantityOptions[index]} - ₱${prices[index]}'),
                      onChanged: (value) {
                        setState(() {
                          _selectedQuantityIndex = value!;
                          _updateTotalPrice();
                        });
                      },
                    );
                  }),

                  // Add-ons (only if it's Takoyaki)
                  if (widget.takoyakiPrices != null) ...[
                    const SizedBox(height: 16.0),
                    Text('Add-ons:', style: const TextStyle(fontSize: 16)),
                    CheckboxListTile(
                      title:
                          const Text('Takoyaki Sauce (Original/Spicy) - ₱15'),
                      value: _takoyakiSauce,
                      onChanged: (value) {
                        setState(() {
                          _takoyakiSauce = value!;
                          _updateTotalPrice();
                        });
                      },
                    ),
                    CheckboxListTile(
                      title: const Text('Bonito Flakes - ₱15'),
                      value: _bonitoFlakes,
                      onChanged: (value) {
                        setState(() {
                          _bonitoFlakes = value!;
                          _updateTotalPrice();
                        });
                      },
                    ),
                    CheckboxListTile(
                      title: const Text('Mayonnaise - ₱15'),
                      value: _mayonnaise,
                      onChanged: (value) {
                        setState(() {
                          _mayonnaise = value!;
                          _updateTotalPrice();
                        });
                      },
                    ),
                  ],

                  const SizedBox(height: 16.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '₱${_totalPrice.toStringAsFixed(2)}',
                        style: const TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove),
                            onPressed: _quantity > 1
                                ? () {
                                    setState(() {
                                      _quantity--;
                                      _updateTotalPrice();
                                    });
                                  }
                                : null,
                          ),
                          Text(
                            '$_quantity',
                            style: const TextStyle(fontSize: 20),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add),
                            onPressed: () {
                              setState(() {
                                _quantity++;
                                _updateTotalPrice();
                              });
                            },
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 16.0),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.brown,
                      ),
                      onPressed: () {
                        final String productType = widget.takoyakiPrices != null
                            ? 'takoyaki'
                            : (widget.milkTeaSmall != null
                                ? 'milktea'
                                : 'meal');
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CartPage(
                              userName: widget.userName!,
                              email: widget.email!,
                              productName: widget.productName,
                              quantity: _quantity,
                              size: quantityOptions[_selectedQuantityIndex],
                              price: _totalPrice,
                              takoyakiSauce: _takoyakiSauce,
                              bonitoFlakes: _bonitoFlakes,
                              mayonnaise: _mayonnaise,
                              productType: productType,
                            ),
                          ),
                        );
                      },
                      child: const Text(
                        'Add to Cart',
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
