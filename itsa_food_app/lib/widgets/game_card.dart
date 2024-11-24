import 'package:flutter/material.dart';
import 'package:itsa_food_app/admin_pages/scratch&win.dart';

class GameCard extends StatefulWidget {
  const GameCard({super.key});

  @override
  _GameCardState createState() => _GameCardState();
}

class _GameCardState extends State<GameCard>
    with SingleTickerProviderStateMixin {
  bool _isTapped = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Promotional Text above the card
        Padding(
          padding: const EdgeInsets.only(bottom: 10.0),
          child: Text(
            "Scratch the cards to get amazing discounts and vouchers!",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ScratchCardGrid()),
            );
          },
          onTapDown: (_) => setState(() => _isTapped = true),
          onTapUp: (_) => setState(() => _isTapped = false),
          onTapCancel: () => setState(() => _isTapped = false),
          child: AnimatedScale(
            scale: _isTapped ? 0.97 : 1.0,
            duration: Duration(milliseconds: 200),
            child: Card(
              elevation: 10,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              margin: EdgeInsets.all(0),
              child: Stack(
                children: [
                  // Background with gradient and image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      height: 220,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.orange.withOpacity(0.9),
                            Colors.deepOrange.withOpacity(0.8)
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.deepOrange.withOpacity(0.5),
                            blurRadius: 20,
                            spreadRadius: -8,
                            offset: Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Opacity(
                        opacity: 0.85,
                        child: Image.asset(
                          'assets/images/sw_img.png',
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                  // Text Overlay with Frosted Glass Effect
                  Positioned(
                    bottom: 15,
                    left: 15,
                    right: 15,
                    child: Container(
                      padding:
                          EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 10,
                            offset: Offset(0, 5),
                          ),
                        ],
                        border:
                            Border.all(color: Colors.white.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.card_giftcard,
                              color: Colors.amberAccent, size: 30),
                          SizedBox(width: 10),
                          Text(
                            'Scratch & Win!',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 1.4,
                              shadows: [
                                Shadow(
                                  blurRadius: 8,
                                  color: Colors.black45,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
