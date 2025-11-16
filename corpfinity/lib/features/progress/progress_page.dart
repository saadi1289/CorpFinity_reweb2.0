import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../auth/auth_service.dart';

class ProgressPage extends StatefulWidget {
  const ProgressPage({super.key});

  @override
  State<ProgressPage> createState() => _ProgressPageState();
}

class _ProgressPageState extends State<ProgressPage> {
  String selectedPeriod = 'Weekly';
  int _completed = 0;
  int _totalMinutes = 0;
  int _streakDays = 0;
  int _points = 0;
  List<Map<String, dynamic>> _recent = const [];
  List<Map<String, dynamic>> _breakdown = const [];
  List<Map<String, dynamic>> _calendarDays = const [];
  List<Map<String, dynamic>> _weeklyBars = const [];
  List<Map<String, dynamic>> _monthlyBars = const [];
  List<Map<String, dynamic>> _yearlyBars = const [];

  String _monthName(int m) {
    const names = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return names[(m - 1).clamp(0, 11)];
  }

  @override
  void initState() {
    super.initState();
    _fetchSummary();
    _fetchRecent();
    _fetchBreakdown();
    _fetchCalendar();
    _fetchWeekly();
  }

  Future<void> _fetchSummary() async {
    final token = await AuthService().getValidAccessToken();
    if (token == null) return;
    final res = await http.get(
      Uri.parse('${AuthService().baseUrl}/progress/summary'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (res.statusCode == 200) {
      final data = json.decode(res.body);
      setState(() {
        _completed = data['completed_count'] ?? 0;
        _totalMinutes = data['total_minutes'] ?? 0;
        _streakDays = data['streak_days'] ?? 0;
        _points = data['points'] ?? 0;
      });
    }
  }

  Future<void> _fetchRecent() async {
    final token = await AuthService().getValidAccessToken();
    if (token == null) return;
    final res = await http.get(
      Uri.parse('${AuthService().baseUrl}/activity/recent'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (res.statusCode == 200) {
      final data = json.decode(res.body);
      final items = List<Map<String, dynamic>>.from(data['items'] ?? []);
      setState(() {
        _recent = items;
      });
    }
  }

  Future<void> _fetchBreakdown() async {
    final token = await AuthService().getValidAccessToken();
    if (token == null) return;
    final res = await http.get(
      Uri.parse('${AuthService().baseUrl}/progress/breakdown'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (res.statusCode == 200) {
      final data = json.decode(res.body);
      final items = List<Map<String, dynamic>>.from(data['items'] ?? []);
      setState(() {
        _breakdown = items;
      });
    }
  }

  Future<void> _fetchCalendar() async {
    final token = await AuthService().getValidAccessToken();
    if (token == null) return;
    final now = DateTime.now();
    final monthStr = '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}';
    final res = await http.get(
      Uri.parse('${AuthService().baseUrl}/progress/calendar?month=$monthStr'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (res.statusCode == 200) {
      final data = json.decode(res.body);
      final items = List<Map<String, dynamic>>.from(data['items'] ?? []);
      final firstDay = DateTime(now.year, now.month, 1);
      final leading = firstDay.weekday % 7;
      final grid = <Map<String, dynamic>>[];
      for (int i = 0; i < leading; i++) {
        grid.add({'day': '', 'activity': 0});
      }
      for (final it in items) {
        final dateStr = it['date'] as String;
        final dt = DateTime.parse(dateStr);
        final activity = (it['activity'] as int);
        final mapped = activity == 2 ? 3 : activity;
        grid.add({'day': dt.day.toString(), 'activity': mapped});
      }
      setState(() {
        _calendarDays = grid;
      });
    }
  }

  Future<void> _fetchWeekly() async {
    final token = await AuthService().getValidAccessToken();
    if (token == null) return;
    final res = await http.get(
      Uri.parse('${AuthService().baseUrl}/progress/weekly'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (res.statusCode == 200) {
      final data = json.decode(res.body);
      final items = List<Map<String, dynamic>>.from(data['items'] ?? []);
      setState(() {
        _weeklyBars = items;
      });
    }
  }

  Future<void> _fetchMonthly() async {
    final token = await AuthService().getValidAccessToken();
    if (token == null) return;
    final res = await http.get(
      Uri.parse('${AuthService().baseUrl}/progress/monthly'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (res.statusCode == 200) {
      final data = json.decode(res.body);
      final items = List<Map<String, dynamic>>.from(data['items'] ?? []);
      setState(() {
        _monthlyBars = items;
      });
    }
  }

  Future<void> _fetchYearly() async {
    final token = await AuthService().getValidAccessToken();
    if (token == null) return;
    final res = await http.get(
      Uri.parse('${AuthService().baseUrl}/progress/yearly'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (res.statusCode == 200) {
      final data = json.decode(res.body);
      final items = List<Map<String, dynamic>>.from(data['items'] ?? []);
      setState(() {
        _yearlyBars = items;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFA),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(),
            
            // Scrollable content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 100),
                child: Column(
                  children: [
                    // Key Metrics
                    _buildKeyMetrics(),
                    const SizedBox(height: 24),
                    
                    // This Week's Activity
                    _buildThisWeeksActivity(),
                    const SizedBox(height: 24),
                    
                    // Calendar View
                    _buildCalendarView(),
                    const SizedBox(height: 24),
                    
                    // Activity Breakdown
                    _buildActivityBreakdown(),
                    const SizedBox(height: 24),
                    
                    // Recent Activity
                    _buildRecentActivity(),
                    const SizedBox(height: 24),
                    
                    // Export Button
                    _buildExportButton(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),

    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Progress',         
   style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildPeriodButton('Weekly', selectedPeriod == 'Weekly'),
              const SizedBox(width: 8),
              _buildPeriodButton('Monthly', selectedPeriod == 'Monthly'),
              const SizedBox(width: 8),
              _buildPeriodButton('Yearly', selectedPeriod == 'Yearly'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodButton(String text, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedPeriod = text;
        });
        if (text == 'Weekly') {
          _fetchWeekly();
        } else if (text == 'Monthly') {
          _fetchMonthly();
        } else if (text == 'Yearly') {
          _fetchYearly();
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Switched to $text view'),
            backgroundColor: const Color(0xFF5FCCC4),
            duration: const Duration(seconds: 1),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF5FCCC4) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF5FCCC4) : const Color(0xFFE5F2F1),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : const Color(0xFF6B8583),
          ),
        ),
      ),
    );
  }

  Widget _buildKeyMetrics() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Key Metrics',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 12),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.2,
            children: [
              _buildMetricCard(
                'Completed',
                '$_completed',
                '',
                '',
                Icons.check_circle,
                true,
              ),
              _buildMetricCard(
                'Total Minutes',
                '$_totalMinutes',
                '',
                '',
                Icons.access_time,
                true,
              ),
              _buildMetricCard(
                'Day Streak',
                '$_streakDays',
                '',
                '',
                Icons.local_fire_department,
                true,
              ),
              _buildMetricCard(
                'Points Earned',
                '$_points',
                '',
                '',
                Icons.star,
                true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(
    String title,
    String value,
    String change,
    String changeLabel,
    IconData icon,
    bool isPositive,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF6B8583),
                ),
              ),
              Icon(
                icon,
                size: 20,
                color: const Color(0xFF5FCCC4),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                size: 12,
                color: const Color(0xFF5FCCC4),
              ),
              const SizedBox(width: 4),
              Text(
                change,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF5FCCC4),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  changeLabel,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B8583),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildThisWeeksActivity() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            selectedPeriod == 'Weekly'
                ? 'This Week\'s Activity'
                : selectedPeriod == 'Monthly'
                    ? 'This Month\'s Activity'
                    : 'This Year\'s Activity',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                SizedBox(
                  height: 180,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: (() {
                      final bars = selectedPeriod == 'Weekly'
                          ? _weeklyBars
                          : selectedPeriod == 'Monthly'
                              ? _monthlyBars
                              : _yearlyBars;
                      final fallback = selectedPeriod == 'Weekly'
                          ? ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
                          : selectedPeriod == 'Monthly'
                              ? ['W1', 'W2', 'W3', 'W4', 'W5']
                              : ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
                      return (bars.isNotEmpty
                          ? bars
                              .map((e) => _buildWeeklyBarItem(
                                    e['day']?.toString() ?? '',
                                    (e['sessions'] ?? 0) as int,
                                    ((e['ratio'] ?? 0.0) as num).toDouble(),
                                  ))
                              .toList()
                          : fallback
                              .map((d) => _buildWeeklyBarItem(d, 0, 0.0))
                              .toList());
                    }()),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  selectedPeriod == 'Weekly'
                      ? 'Sessions completed per day'
                      : selectedPeriod == 'Monthly'
                          ? 'Sessions completed per week'
                          : 'Sessions completed per month',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF6B8583),
                  ),
                ),
                Text(
                  selectedPeriod == 'Weekly'
                      ? 'Goal: 3 sessions daily'
                      : selectedPeriod == 'Monthly'
                          ? 'Goal: 3 sessions weekly'
                          : 'Goal: 12 sessions monthly',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B8583),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyBarItem(String day, int sessions, double height) {
    Color barColor = const Color(0xFF5FCCC4);
    if (sessions == 0) {
      barColor = const Color(0xFFE5F2F1);
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: 28,
          height: 120 * height,
          decoration: BoxDecoration(
            color: barColor,
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          day,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF6B8583),
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          sessions.toString(),
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF1A1A1A),
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildCalendarView() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${_monthName(DateTime.now().month)} ${DateTime.now().year}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                // Calendar header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: ['S', 'M', 'T', 'W', 'T', 'F', 'S']
                      .map((day) => SizedBox(
                            width: 32,
                            child: Text(
                              day,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF6B8583),
                              ),
                            ),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 12),
                // Calendar grid
                _buildCalendarGrid(),
                const SizedBox(height: 16),
                // Legend
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildLegendItem('No activity', const Color(0xFFE5F2F1)),
                    _buildLegendItem('Some activity', const Color(0xFF9FE4DF)),
                    _buildLegendItem('Goal achieved', const Color(0xFF5FCCC4)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid() {
    final List<Map<String, dynamic>> calendarDays = _calendarDays.isNotEmpty ? _calendarDays : [];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 1,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      itemCount: calendarDays.length,
      itemBuilder: (context, index) {
        final dayData = calendarDays[index];
        return _buildCalendarDay(dayData['day'], dayData['activity']);
      },
    );
  }

  Widget _buildCalendarDay(String day, int activity) {
    Color backgroundColor;
    if (day.isEmpty) {
      backgroundColor = Colors.transparent;
    } else if (activity == 0) {
      backgroundColor = const Color(0xFFE5F2F1);
    } else if (activity >= 3) {
      backgroundColor = const Color(0xFF5FCCC4);
    } else {
      backgroundColor = const Color(0xFF9FE4DF);
    }

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Center(
        child: Text(
          day,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: day.isEmpty ? Colors.transparent : 
                   (activity >= 3 ? Colors.white : const Color(0xFF1A1A1A)),
          ),
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: Color(0xFF6B8583),
          ),
        ),
      ],
    );
  }

  Widget _buildActivityBreakdown() {
    final activities = _breakdown.map((b) {
      final title = (b['pillar'] ?? '').toString();
      IconData icon = Icons.self_improvement;
      if (title.contains('Energy')) {
        icon = Icons.bolt;
      } else if (title.contains('Focus')) {
        icon = Icons.center_focus_strong;
      } else if (title.contains('Movement')) {
        icon = Icons.directions_walk;
      }
      final sessions = b['sessions'] ?? 0;
      final minutes = b['minutes'] ?? 0;
      final percentage = b['percentage'] ?? 0;
      final progress = (percentage as num).toDouble() / 100.0;
      return {
        'title': title,
        'sessions': '$sessions sessions',
        'minutes': '$minutes min',
        'percentage': '$percentage%',
        'progress': progress,
        'icon': icon,
      };
    }).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Activity Breakdown',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 12),
          ...activities.map((activity) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0F9F8),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(
                          activity['icon'] as IconData,
                          size: 20,
                          color: const Color(0xFF5FCCC4),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              activity['title'] as String,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1A1A1A),
                              ),
                            ),
                            Text(
                              activity['sessions'] as String,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF6B8583),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            activity['minutes'] as String,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A1A1A),
                            ),
                          ),
                          Text(
                            activity['percentage'] as String,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF5FCCC4),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5F4),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: activity['progress'] as double,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF5FCCC4),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildRecentActivity() {
    final recentActivities = _recent.map((e) => {
      'title': e['title'] ?? 'Session',
      'time': e['started_at']?.toString() ?? '',
      'points': '+${e['points'] ?? 0} pts',
      'duration': '${e['duration_minutes'] ?? 0} min',
      'intensity': (e['intensity'] ?? '').toString(),
      'icon': Icons.self_improvement,
    }).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recent Activity',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 12),
          ...recentActivities.map((activity) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0F9F8),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(
                          activity['icon'] as IconData,
                          size: 20,
                          color: const Color(0xFF5FCCC4),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              activity['title'] as String,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1A1A1A),
                              ),
                            ),
                            Text(
                              activity['time'] as String,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF6B8583),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        activity['points'] as String,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF5FCCC4),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time,
                        size: 16,
                        color: Color(0xFF6B8583),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        activity['duration'] as String,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6B8583),
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Icon(
                        Icons.bolt,
                        size: 16,
                        color: Color(0xFF5FCCC4),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        activity['intensity'] as String,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6B8583),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildExportButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Exporting progress report...'),
                backgroundColor: Color(0xFF5FCCC4),
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF5FCCC4),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 2,
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.download, size: 20),
              SizedBox(width: 8),
              Text(
                'Export Progress Report',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}