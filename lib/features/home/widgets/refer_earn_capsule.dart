import 'dart:async';
import 'package:flutter/material.dart';
import 'shiny_coin.dart';

class ReferEarnCapsule extends StatefulWidget {
  const ReferEarnCapsule({super.key});

  @override
  State<ReferEarnCapsule> createState() => _ReferEarnCapsuleState();
}

class _ReferEarnCapsuleState extends State<ReferEarnCapsule> {
  final List<String> _texts = ['Refer', 'Earn'];
  int _currentIndex = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (mounted) {
        setState(() {
          _currentIndex = (_currentIndex + 1) % _texts.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      padding: const EdgeInsets.only(left: 4, right: 12, top: 4, bottom: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const ShinyCoin(),
          const SizedBox(width: 8),
          SizedBox(
            width: 40,
            height: 20,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (Widget child, Animation<double> animation) {
                final inAnimation = Tween<Offset>(
                  begin: const Offset(0.0, 1.0),
                  end: Offset.zero,
                ).animate(animation);

                final outAnimation = Tween<Offset>(
                  begin: const Offset(0.0, -1.0),
                  end: Offset.zero,
                ).animate(animation);

                if (child.key == ValueKey(_texts[_currentIndex])) {
                   return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: inAnimation,
                      child: child,
                    ),
                  );
                } else {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: outAnimation,
                      child: child,
                    ),
                  );
                }
              },
              child: Text(
                _texts[_currentIndex],
                key: ValueKey<String>(_texts[_currentIndex]),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                  height: 1.0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
