import 'package:flutter/material.dart';

class ShinyCoin extends StatefulWidget {
  const ShinyCoin({super.key});

  @override
  State<ShinyCoin> createState() => _ShinyCoinState();
}

class _ShinyCoinState extends State<ShinyCoin> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: false);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        // Rich Gold Gradient
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFFE082), // Light Gold
            Color(0xFFFFD54F), // Gold
            Color(0xFFFFCA28), // Darker Gold
            Color(0xFFFFB300), // Orange Gold
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.4),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
        border: Border.all(color: Colors.white.withOpacity(0.5), width: 1),
      ),
      child: Stack(
        children: [
          // Coin Symbol
          const Center(
            child: Text(
              '\$', // Using generic currency symbol
              style: TextStyle(
                color: Color(0xFFE65100), // Dark Orange Text
                fontWeight: FontWeight.w900,
                fontSize: 14,
                fontFamily: 'Roboto',
              ),
            ),
          ),

          // Shine Effect (Simple white bar moving across)
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Positioned(
                top: -10,
                bottom: -10,
                left: -20 + (_controller.value * 60), // Move from left to right
                width: 10,
                child: Transform.rotate(
                  angle: 0.5,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withOpacity(0.0),
                          Colors.white.withOpacity(0.8),
                          Colors.white.withOpacity(0.0),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
