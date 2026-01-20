import 'package:flutter/material.dart';

class HomeTab extends StatelessWidget {
  final Map<String, dynamic> userData;

  const HomeTab({super.key, required this.userData});

  @override
  Widget build(BuildContext context) {
    final user = userData['user'] ?? {};
    final String name = user['name'] ?? 'User';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome back, $name!',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            const Text(
              'Your Activity',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(child: Text('No recent activity')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
