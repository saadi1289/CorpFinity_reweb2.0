import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'features/auth/auth_service.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'features/home/home_page.dart';
import 'features/progress/progress_page.dart';
import 'features/challenge_creator/challenge_creator_page.dart';
import 'features/profile/profile_page.dart';
import 'features/active_challenge/active_challenge_session_page.dart';


class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const HomePage(),
    const ChallengesPageWidget(),
    const ChallengeCreatorPage(),
    const ProgressPage(),
    const ProfilePage(),
  ];

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF5FCFC),
        border: Border(
          top: BorderSide(
            color: const Color(0xFFD4EEEC),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.home, 'Home', 0),
              _buildNavItem(Icons.assignment_outlined, 'Challenges', 1),
              _buildCenterNavButton(),
              _buildNavItem(Icons.bar_chart, 'Progress', 3),
              _buildNavItem(Icons.person_outline, 'Profile', 4),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isActive = _currentIndex == index;
    return GestureDetector(
      onTap: () => _onTabTapped(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 24,
            color: isActive ? const Color(0xFF5FCCC4) : const Color(0xFF5A7878),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isActive ? const Color(0xFF5FCCC4) : const Color(0xFF5A7878),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCenterNavButton() {
    return GestureDetector(
      onTap: () => _onTabTapped(2),
      child: Container(
        width: 56,
        height: 56,
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF5FCCC4),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF5FCCC4).withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(
          Icons.add_circle_outline,
          size: 28,
          color: Colors.white,
        ),
      ),
    );
  }
}

// Placeholder pages - CreatePage removed, now using ChallengeCreatorPage

class ChallengesPageWidget extends StatefulWidget {
  const ChallengesPageWidget({super.key});

  @override
  State<ChallengesPageWidget> createState() => _ChallengesPageWidgetState();
}

class _ChallengesPageWidgetState extends State<ChallengesPageWidget> {
  List<Map<String, dynamic>> _popular = const [];
  List<Map<String, dynamic>> _recent = const [];

  @override
  void initState() {
    super.initState();
    _fetchPopular();
    _fetchRecent();
  }


  void _openWizard() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ChallengeCreatorPage()),
    );
  }

  void _joinChallengeItem(Map<String, dynamic> item) {
    final steps = List<String>.from(item['steps'] ?? []);
    final total = (item['duration_minutes'] ?? 5) * 60;
    final count = steps.isEmpty ? 1 : steps.length;
    final base = count > 0 ? total ~/ count : total;
    final rem = count > 0 ? total - (base * (count - 1)) : 0;
    final activities = <Map<String, dynamic>>[];
    for (var i = 0; i < count; i++) {
      activities.add({
        'title': 'Step ${i + 1}',
        'duration': i == count - 1 ? rem : base,
        'instructions': steps.isNotEmpty ? steps[i] : 'Follow the guided step',
      });
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ActiveChallengeSessionPage(
          challengeName: item['name'] ?? 'Challenge',
          activities: activities,
          totalDuration: total,
          challengeId: item['id'] as int?,
        ),
      ),
    );
  }

  Future<void> _fetchPopular() async {
    try {
      final res = await http.get(Uri.parse('${AuthService().baseUrl}/challenges'));
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        final items = List<Map<String, dynamic>>.from(data['items'] ?? []);
        setState(() {
          _popular = items.take(8).toList();
        });
      }
    } catch (_) {}
  }

  Future<void> _fetchRecent() async {
    try {
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
    } catch (_) {}
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFA),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Challenges',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: _openWizard,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5FCCC4),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        '+ New',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 8),
              
              // Ongoing Progress Section
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'Ongoing Progress',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              
              // Ongoing Progress Cards
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    // Active challenge with teal border
                    _buildOngoingCard(
                      '5-Minute Energy Boost',
                      'Session 2 of 3 • Breathing & stretching',
                      '67%',
                      '1 session left',
                      'Target: Complete 3 energizing sessions ✓ On track',
                      0.67,
                      const Color(0xFF5FCCC4),
                      isActive: true,
                    ),
                    const SizedBox(height: 12),
                    _buildOngoingCard(
                      '10-Minute Calm Focus',
                      'Session 1 of 2 • Meditation & mindfulness',
                      '50%',
                      '1 session left',
                      'Target: Complete 2 focus sessions • Next session ready',
                      0.50,
                      const Color(0xFFD8B4FE),
                    ),
                    const SizedBox(height: 12),
                    _buildOngoingCard(
                      '30-Minute Wellness Break',
                      'Session 3 of 5 • Full body & mind reset',
                      '60%',
                      '2 sessions left',
                      'Target: Complete 5 wellness sessions • Great progress',
                      0.60,
                      const Color(0xFF86EFAC),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Recently Completed Section
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'Recently Completed',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: _recent.map((r) {
                    final title = (r['title'] ?? 'Session').toString();
                    final started = (r['started_at'] ?? '').toString();
                    final pillarAsset = 'assets/illustrations/increased_energy.svg';
                    return Column(children: [
                      _buildCompletedCard(title, started, pillarAsset),
                      const SizedBox(height: 12),
                    ]);
                  }).toList(),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Popular Challenges Section
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'Popular Challenges',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: _popular.map((c) {
                    final name = (c['name'] ?? 'Challenge').toString();
                    final desc = (c['description'] ?? '').toString();
                    final mins = ((c['duration_minutes'] ?? 5) as int).toString();
                    final color = const Color(0xFF5FCCC4);
                    final bg = const Color(0xFFF0F9F8);
                    return Column(children: [
                      _buildPopularCard(
                        name,
                        desc,
                        '$mins mins',
                        color,
                        bg,
                        '4.8',
                        '1.2k',
                        c,
                      ),
                      const SizedBox(height: 12),
                      const SizedBox.shrink(),
                    ]);
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }







  Widget _buildOngoingCard(String title, String subtitle, String progress, String daysLeft, String target, double progressValue, Color progressColor, {bool isActive = false}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive ? const Color(0xFF5FCCC4) : const Color(0xFFE5F2F1),
          width: isActive ? 2 : 1,
        ),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 14,
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
                    progress,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isActive ? const Color(0xFF5FCCC4) : const Color(0xFF6B8583),
                    ),
                  ),
                  Text(
                    daysLeft,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B8583),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Left-aligned progress bar
          Container(
            width: double.infinity,
            height: 8,
            decoration: BoxDecoration(
              color: const Color(0xFFE5F2F1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progressValue,
              child: Container(
                decoration: BoxDecoration(
                  color: progressColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            target,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF6B8583),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletedCard(String title, String subtitle, String svgPath) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5F2F1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B8583),
                  ),
                ),
              ],
            ),
          ),
          SvgPicture.asset(
            svgPath,
            width: 32,
            height: 32,
          ),
        ],
      ),
    );
  }

  Widget _buildPopularCard(String title, String description, String duration, Color durationColor, Color durationBgColor, String rating, String joined, Map<String, dynamic> item) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5F2F1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B8583),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: durationBgColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        duration,
                        style: TextStyle(
                          fontSize: 12,
                          color: durationColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      '⭐ $rating rating',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B8583),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      '$joined joined',
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
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => _joinChallengeItem(item),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5FCCC4),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Start',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ProfilePage moved to separate file