import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChangeBackgroundScreen extends StatefulWidget {
  const ChangeBackgroundScreen({super.key});

  @override
  State<ChangeBackgroundScreen> createState() => _ChangeBackgroundScreenState();
}

class _ChangeBackgroundScreenState extends State<ChangeBackgroundScreen> {
  final List<String> _backgrounds = [
    'assets/images/profile_bg.png', // Default
    'assets/images/backgrounds/bg_study_desk.png',
    'assets/images/backgrounds/bg_justice_scales.png',
    'assets/images/backgrounds/bg_cozy_library.png',
    'assets/images/backgrounds/bg_zen_garden.png',
    'assets/images/backgrounds/bg_neon_sunset.png',
    'assets/images/backgrounds/bg_cherry_blossom.png',
    'assets/images/backgrounds/bg_ninja_moon.png',
    'assets/images/backgrounds/bg_cyberpunk_city.png',
    'assets/images/backgrounds/bg_energy_aura.png',
    'assets/images/backgrounds/bg_abstract_waves.png',
    'assets/images/backgrounds/bg_minimalist_geometry.png',
    'assets/images/backgrounds/bg_dark_texture.png',
  ];

  String? _selectedBackground;

  @override
  void initState() {
    super.initState();
    _loadSelectedBackground();
  }

  Future<void> _loadSelectedBackground() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedBackground = prefs.getString('selected_profile_bg') ?? 'assets/images/profile_bg.png';
    });
  }

  Future<void> _saveSelectedBackground(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_profile_bg', path);
    setState(() {
      _selectedBackground = path;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile background updated!'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
      Navigator.pop(context, path);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Change Background'),
        centerTitle: true,
      ),
      body: _selectedBackground == null
          ? const Center(child: CircularProgressIndicator())
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.5,
              ),
              itemCount: _backgrounds.length,
              itemBuilder: (context, index) {
                final bgPath = _backgrounds[index];
                final isSelected = _selectedBackground == bgPath;

                return GestureDetector(
                  onTap: () => _saveSelectedBackground(bgPath),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? Colors.blueAccent : Colors.transparent,
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.asset(
                          bgPath,
                          fit: BoxFit.cover,
                        ),
                        if (isSelected)
                          Container(
                            color: Colors.black.withOpacity(0.3),
                            child: const Center(
                              child: Icon(
                                Icons.check_circle,
                                color: Colors.white,
                                size: 36,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
