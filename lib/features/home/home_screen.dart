import 'package:flutter/material.dart';
import '../../core/services/auth_service.dart';
import '../auth/login_page.dart';

class HomeScreen extends StatelessWidget {
  final Map<String, dynamic> userData;
  final AuthService authService;

  const HomeScreen({super.key, required this.userData, required this.authService});

  @override
  Widget build(BuildContext context) {
    final user = userData['user'] ?? {};
    final String name = user['name'] ?? 'User';
    final String email = user['email'] ?? '';
    final String role = user['role'] ?? 'Unknown';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authService.signOut();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                  (route) => false,
                );
              }
            },
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.indigo.shade100,
                  child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?'),
                ),
                title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('$email • $role'),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Available Tests',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Center(child: Text('Fetch your tests here using AuthService.client')),
          ],
        ),
      ),
    );
  }
}
