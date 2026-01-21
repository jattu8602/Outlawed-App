import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../core/services/auth_service.dart';
import '../auth/login_page.dart';
import './services/test_service.dart';
import './models/test_models.dart';

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
  final AuthService authService;
  const TestsScreen({super.key, required this.authService});

  @override
  State<TestsScreen> createState() => _TestsScreenState();
}

class _TestsScreenState extends State<TestsScreen> {
  late final TestService _testService;

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

  List<TestModel> _tests = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _selectedExam = _exams[0];
    _testService = TestService(widget.authService);
    _fetchTests();
  }

  Future<void> _fetchTests() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final List<TestModel> fetchedTests;
      if (_selectedTab == 'Free') {
        fetchedTests = await _testService.getFreeTests();
      } else {
        fetchedTests = await _testService.getPremiumTests();
      }

      setState(() {
        _tests = fetchedTests;
        _isLoading = false;
      });
    } on DioException catch (e) {
      setState(() {
        if (e.response?.statusCode == 401) {
          _error = 'Unauthorized: Please login to see tests.';
        } else {
          _error = 'Failed to load tests. Please try again.';
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'An unexpected error occurred.';
        _isLoading = false;
      });
    }
  }

  List<TestModel> get _filteredTests {
    return _tests.where((test) {
      final name = _selectedExam.name.toUpperCase();
      final title = test.title.toUpperCase();

      // Strict filter for other exams, lenient for CLAT
      bool matchesExam = title.contains(name);
      if (name == 'CLAT') {
        // For CLAT, show if title has CLAT OR if it doesn't mention other known exams
        final mentionsOther = _exams.any((e) => e.name != 'CLAT' && title.contains(e.name.toUpperCase()));
        matchesExam = title.contains('CLAT') || !mentionsOther;
      }

      bool matchesFilter = true;
      if (_selectedFilter == 'Attempted') {
        matchesFilter = test.isAttempted;
      } else if (_selectedFilter == 'Non-attempted') {
        matchesFilter = !test.isAttempted;
      }

      return matchesExam && matchesFilter;
    }).toList();
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
                    if (_selectedExam.name != exam.name) {
                      setState(() {
                        _selectedExam = exam;
                      });
                      _fetchTests();
                    }
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
                Expanded(
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Stack(
                      children: [
                        AnimatedPositioned(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          left: _selectedTab == 'Free' ? 4 : (MediaQuery.of(context).size.width - 40 - 12 - 50) / 2 + 2,
                          top: 4,
                          bottom: 4,
                          width: (MediaQuery.of(context).size.width - 40 - 12 - 50) / 2 - 6,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black,
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                        Row(
                          children: ['Free', 'Paid'].map((tab) {
                            final isSelected = _selectedTab == tab;
                            return Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  if (_selectedTab != tab) {
                                    setState(() => _selectedTab = tab);
                                    _fetchTests();
                                  }
                                },
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
                const SizedBox(width: 12),
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
          // Test List Section
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Colors.black))
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 40),
                              child: Text(
                                _error!,
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.red.shade700, fontSize: 16),
                              ),
                            ),
                            const SizedBox(height: 24),
                            if (_error!.contains('Unauthorized'))
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => const LoginPage()),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.black,
                                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                child: const Text('Go to Login', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              )
                            else
                              ElevatedButton(
                                onPressed: _fetchTests,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.black,
                                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                child: const Text('Retry', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              ),
                          ],
                        ),
                      )
                    : _filteredTests.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.description_outlined, size: 64, color: Colors.grey.shade300),
                                const SizedBox(height: 16),
                                Text(
                                  'No ${_selectedTab.toLowerCase()} tests found for ${_selectedExam.name}',
                                  style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _fetchTests,
                            color: Colors.black,
                            child: ListView.separated(
                              padding: EdgeInsets.zero,
                              itemCount: _filteredTests.length,
                              separatorBuilder: (context, index) => Divider(
                                height: 1,
                                thickness: 1,
                                color: Colors.grey.shade100,
                                indent: 20,
                                endIndent: 20,
                              ),
                              itemBuilder: (context, index) {
                                return _buildTestStrip(_filteredTests[index]);
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildTestStrip(TestModel test) {
    const bool isUserPaid = false;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  test.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    if (_selectedExam.name != 'CLAT') ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          test.difficulty,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      '${test.numberOfQuestions} Questions',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '•',
                      style: TextStyle(color: Colors.grey.shade300),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${test.durationMinutes} Mins',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          if (test.isPaid && !isUserPaid)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.lock_rounded, size: 18, color: Colors.grey),
            )
          else if (test.isAttempted)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'REATTEMPT',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueAccent,
                        letterSpacing: 0.5,
                      ),
                    ),
                    if (test.lastScore != null)
                      Text(
                        'Score: ${test.lastScore}',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade500,
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 16),
                GestureDetector(
                  onTap: () {}, // Navigate to analysis
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blueAccent.withOpacity(0.08),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.bar_chart_rounded, size: 22, color: Colors.blueAccent),
                  ),
                ),
              ],
            )
          else
            GestureDetector(
              onTap: () {}, // Navigate to test
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Colors.black,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.play_arrow_rounded, size: 24, color: Colors.white),
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
                          setState(() {});
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
