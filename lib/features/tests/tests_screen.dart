import 'package:flutter/material.dart';

class ExamOption {
  final String name;
  final String logoPath;
  final Color themeColor;

  ExamOption({
    required this.name,
    required this.logoPath,
    required this.themeColor,
  });
}

class TestsScreen extends StatefulWidget {
  const TestsScreen({super.key});

  @override
  State<TestsScreen> createState() => _TestsScreenState();
}

class _TestsScreenState extends State<TestsScreen> {
  final List<ExamOption> _exams = [
    ExamOption(
      name: 'CLAT',
      logoPath: 'assets/images/clat_logo.png',
      themeColor: const Color(0xFF003366),
    ),
    ExamOption(
      name: 'AILET',
      logoPath: 'assets/images/ailet_logo.png',
      themeColor: const Color(0xFF4B0082),
    ),
    ExamOption(
      name: 'SLAT',
      logoPath: 'assets/images/slat_logo.png',
      themeColor: const Color(0xFFFF8C00),
    ),
    ExamOption(
      name: 'MH CET Law',
      logoPath: 'assets/images/mhcet_logo.png',
      themeColor: const Color(0xFF008080),
    ),
  ];

  late ExamOption _selectedExam;
  String _selectedTab = 'Free';
  String _selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    _selectedExam = _exams[0]; // CLAT by default
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        toolbarHeight: 80,
        title: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: _exams.map((exam) {
              final isSelected = _selectedExam.name == exam.name;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedExam = exam;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    padding: EdgeInsets.symmetric(
                      horizontal: isSelected ? 12 : 4,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.black : Colors.transparent,
                      borderRadius: BorderRadius.circular(40),
                      border: Border.all(
                        color: isSelected ? Colors.black : Colors.grey.shade200,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              exam.logoPath,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        if (isSelected) ...[
                          const SizedBox(width: 8),
                          Text(
                            exam.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 4),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
      body: Column(
        children: [
          // Tabs and Filter Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                // Custom Tab Switcher (Expanded to full width, Slight roundness, Capsule animation)
                Expanded(
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12), // Slight roundness
                    ),
                    child: Stack(
                      children: [
                        // Sliding Background Indicator (Capsule-style)
                        AnimatedPositioned(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          left: _selectedTab == 'Free' ? 4 : (MediaQuery.of(context).size.width - 40 - 12 - 48) / 2 + 2,
                          top: 4,
                          bottom: 4,
                          width: (MediaQuery.of(context).size.width - 40 - 12 - 48) / 2 - 6,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black,
                              borderRadius: BorderRadius.circular(10), // Capsule look
                            ),
                          ),
                        ),
                        // Tab Text Buttons
                        Row(
                          children: ['Free', 'Paid'].map((tab) {
                            final isSelected = _selectedTab == tab;
                            return Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => _selectedTab = tab),
                                child: Container(
                                  color: Colors.transparent,
                                  alignment: Alignment.center,
                                  child: AnimatedDefaultTextStyle(
                                    duration: const Duration(milliseconds: 300),
                                    style: TextStyle(
                                      color: isSelected ? Colors.white : Colors.grey,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                      fontSize: 14,
                                    ),
                                    child: Text(tab),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Filter Button (Icon-only, Opens Dialog)
                GestureDetector(
                  onTap: () => _showFilterDialog(context),
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.filter_list_rounded,
                      size: 20,
                      color: Colors.black,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Selected Exam Logo and Title
                  AnimatedScale(
                    duration: const Duration(milliseconds: 300),
                    scale: 1.0,
                    child: Container(
                      width: 180,
                      height: 180,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.grey.shade100, width: 4),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 25,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          _selectedExam.logoPath,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    _selectedExam.name,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: _selectedExam.themeColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(40),
                    ),
                    child: Text(
                      'Ready for Preparation',
                      style: TextStyle(
                        color: _selectedExam.themeColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  if (_selectedFilter != 'All') ...[
                    const SizedBox(height: 12),
                    Text(
                      'Showing: $_selectedFilter',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Filter By',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...['All', 'Subject-wise', 'Attempted', 'Non-attempted'].map((filter) {
                      final isSelected = _selectedFilter == filter;
                      return GestureDetector(
                        onTap: () {
                          setDialogState(() => _selectedFilter = filter);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: filter == 'Non-attempted'
                                    ? Colors.transparent
                                    : Colors.grey.shade100,
                              ),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                filter,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: isSelected ? Colors.black : Colors.grey.shade600,
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                ),
                              ),
                              if (isSelected)
                                const Icon(Icons.check_circle_rounded, color: Colors.black, size: 20),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {}); // Update the main screen
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Apply Filter',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
