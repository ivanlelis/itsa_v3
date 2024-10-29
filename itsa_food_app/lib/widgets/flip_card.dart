import 'package:flutter/material.dart';
import 'dart:math';

class FlipCardWidget extends StatefulWidget {
  final String cardContent;
  final bool isFlipped;
  final VoidCallback onTap;

  FlipCardWidget({
    required this.cardContent,
    required this.isFlipped,
    required this.onTap,
  });

  @override
  _FlipCardWidgetState createState() => _FlipCardWidgetState();
}

class _FlipCardWidgetState extends State<FlipCardWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    // Listen to the flipped state
    if (widget.isFlipped) {
      _controller.value = 1.0; // Set to flipped position if already flipped
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleFlip() {
    if (widget.isFlipped) {
      _controller.reverse();
    } else {
      _controller.forward();
    }
    widget.onTap(); // Notify parent to flip card state
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggleFlip,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final angle =
              _controller.value * pi; // Rotate based on animation value
          return Transform(
            transform: Matrix4.rotationY(angle),
            alignment: Alignment.center,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16.0),
                color: widget.isFlipped ? Colors.white : Colors.transparent,
                image: !widget.isFlipped
                    ? DecorationImage(
                        image: AssetImage(
                            'assets/images/ITSA_BG.jpg'), // Your image path
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: Center(
                child: Text(
                  widget.isFlipped ? widget.cardContent : '',
                  style: TextStyle(
                    fontSize: 24,
                    color: widget.isFlipped ? Colors.black : Colors.transparent,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
