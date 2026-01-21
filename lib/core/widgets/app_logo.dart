import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  const AppLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Logo Shape
        Container(
          width: 32,
          height: 32,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: 16,
                child: Container(color: Colors.orange),
              ),
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                width: 16,
                child: Container(color: Colors.black),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        // Text
        RichText(
          text: const TextSpan(
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: Colors.black,
              fontFamily: 'Inter', // Ensuring font consistency
              letterSpacing: 0.5,
            ),
            children: [
              TextSpan(text: 'OUTLAWED'),
              TextSpan(
                text: '.',
                style: TextStyle(
                  color: Colors.orange,
                  fontSize: 24,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
