import 'package:flutter/material.dart';

class StreakHistoryScreen extends StatefulWidget {
  const StreakHistoryScreen({super.key});

  @override
  State<StreakHistoryScreen> createState() => _StreakHistoryScreenState();
}

class _StreakHistoryScreenState extends State<StreakHistoryScreen> {
  late int _selectedYear;
  final List<int> _years = [2024, 2025, 2026];

  @override
  void initState() {
    super.initState();
    _selectedYear = DateTime.now().year;
    // Ensure current year is in the list
    if (!_years.contains(_selectedYear)) {
      _years.add(_selectedYear);
      _years.sort();
    }
  }

  final List<String> _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A), // Completely dark background
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1B2A),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Streak History',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: DropdownButton<int>(
              value: _selectedYear,
              dropdownColor: const Color(0xFF1B263B), // Dark dropdown menu
              underline: const SizedBox(),
              icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF39D353)),
              style: const TextStyle(
                color: Color(0xFF39D353),
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
              onChanged: (int? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedYear = newValue;
                  });
                }
              },
              items: _years.map<DropdownMenuItem<int>>((int value) {
                return DropdownMenuItem<int>(
                  value: value,
                  child: Text(value.toString()),
                );
              }).toList(),
            ),
          ),
        ],
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, // Two months side-by-side
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.85,
        ),
        itemCount: _months.length,
        itemBuilder: (context, index) {
          return _buildMonthGrid(_months[index], index + 1);
        },
      ),
    );
  }

  Widget _buildMonthGrid(String monthName, int monthIndex) {
    // Basic logic to get days in month
    int daysInMonth = 30;
    if ([1, 3, 5, 7, 8, 10, 12].contains(monthIndex)) daysInMonth = 31;
    if (monthIndex == 2) daysInMonth = 28;

    final DateTime now = DateTime.now();

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF1B263B), // Darker card background
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.05)), // Subtle border
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 10.0),
            child: Text(
              monthName,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          Expanded(
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7, // 7 days a week
                mainAxisSpacing: 4,
                crossAxisSpacing: 4,
              ),
              itemCount: daysInMonth,
              itemBuilder: (context, dayIndex) {
                final DateTime dayDate = DateTime(_selectedYear, monthIndex, dayIndex + 1);

                // Determine Day State
                bool isFuture = dayDate.isAfter(DateTime(now.year, now.month, now.day));
                bool isToday = dayDate.year == now.year && dayDate.month == now.month && dayDate.day == now.day;
                bool isPast = dayDate.isBefore(DateTime(now.year, now.month, now.day));

                // Dummy logic for streak (only for past and today)
                bool isStreak = (dayIndex + monthIndex) % 4 != 0;

                Color boxColor;
                if (isFuture) {
                  // Incoming days: Ghost/Neutral color
                  boxColor = Colors.white.withOpacity(0.03);
                } else if (isToday) {
                  // Today: Highlight (maybe orange or just current status)
                  boxColor = isStreak ? const Color(0xFF39D353) : Colors.orange.withOpacity(0.4);
                } else {
                  // Past days
                  if (isStreak) {
                    boxColor = const Color(0xFF39D353); // Success Green
                  } else {
                    boxColor = Colors.redAccent.withOpacity(0.1); // Missed/Gap Red
                  }
                }

                return Container(
                  decoration: BoxDecoration(
                    color: boxColor,
                    borderRadius: BorderRadius.circular(2),
                    border: isToday ? Border.all(color: Colors.white.withOpacity(0.5), width: 0.5) : null,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
