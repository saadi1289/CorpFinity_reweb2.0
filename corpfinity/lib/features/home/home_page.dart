import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../auth/auth_service.dart';
import '../active_challenge/active_challenge_session_page.dart';
import '../challenge_creator/challenge_creator_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? _userName;
  Map<String, dynamic>? _featured;
  List<Map<String, dynamic>> _quick = const [];

  @override
  void initState() {
    super.initState();
    _fetchUser();
    _fetchFeatured();
  }

  Future<void> _fetchUser() async {
    final token = await AuthService().getValidAccessToken();
    if (token == null) return;
    final res = await http.get(
      Uri.parse('${AuthService().baseUrl}/auth/me'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (res.statusCode == 200) {
      final data = json.decode(res.body);
      setState(() {
        _userName = (data['username'] ?? '').toString();
      });
    }
  }

  Future<void> _fetchFeatured() async {
    try {
      final res = await http.get(Uri.parse('${AuthService().baseUrl}/challenges'));
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        final items = List<Map<String, dynamic>>.from(data['items'] ?? []);
        setState(() {
          _featured = items.isNotEmpty ? items.first : null;
          _quick = items.take(4).toList();
        });
      }
    } catch (_) {}
  }

  void _startChallengeItem(Map<String, dynamic> item) {
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
          challengeName: item['name']?.toString() ?? 'Challenge',
          activities: activities,
          totalDuration: total,
          challengeId: item['id'] as int?,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5FCFC),
      body: SafeArea(
        child: Column(
          children: [

            
            // Scrollable content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Greeting Card
                    _buildGreetingCard(),
                    const SizedBox(height: 24),
                    
                    // Wellness Goals Grid
                    _buildWellnessGoalsGrid(),
                    const SizedBox(height: 24),
                    
                    // Featured Challenge
                    _buildFeaturedChallenge(),
                    const SizedBox(height: 24),
                    
                    // Quick Challenges
                    _buildQuickChallenges(),
                    const SizedBox(height: 100), // Bottom padding for navigation
                  ],
                ),
              ),
            ),
          ],
        ),
      ),

    );
  }

  Widget _buildGreetingCard() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF7DD9D3),
            Color(0xFF5FCCC4),
            Color(0xFF3FB5AC),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _userName != null && _userName!.isNotEmpty ? 'Good Morning, ${_userName!}' : 'Good Morning',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Let\'s make today a balanced and mindful day.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                _buildBadge('Mindful Warrior'),
                const SizedBox(width: 12),
                _buildBadge('Active Streaker'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildWellnessGoalsGrid() {
    final goals = [
      {'title': 'Stress Reduction', 'svg': 'assets/illustrations/stress_reduction.svg'},
      {'title': 'Increased Energy', 'svg': 'assets/illustrations/increased_energy.svg'},
      {'title': 'Better Sleep', 'svg': 'assets/illustrations/better_sleep.svg'},
      {'title': 'Physical Fitness', 'svg': 'assets/illustrations/physical_fitness.svg'},
      {'title': 'Healthy Eating', 'svg': 'assets/illustrations/healthy_eating.svg'},
      {'title': 'Social Connection', 'svg': 'assets/illustrations/Social-connection.svg'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Select your Wellness goal',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A3A3A),
            ),
          ),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final crossAxisCount = width >= 900 ? 4 : width >= 600 ? 3 : 2;
            final scaler = MediaQuery.of(context).textScaler;
            final scale = scaler.scale(1.0);
            final mainExtent = 110.0 + (scale > 1.0 ? (scale - 1.0) * 24.0 : 0);
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  mainAxisExtent: mainExtent,
                ),
                itemCount: goals.length,
                itemBuilder: (context, index) {
                  final goal = goals[index];
                  return InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChallengeCreatorPage(initialPillar: goal['title'] as String),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFE8F7F6), width: 1),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  goal['title'] as String,
                                  maxLines: 2,
                                  softWrap: true,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF1A3A3A),
                                  ),
                                ),
                              ),
                              SvgPicture.asset(
                                goal['svg'] as String,
                                width: 24,
                                height: 24,
                                colorFilter: const ColorFilter.mode(
                                  Color(0xFF5FCCC4),
                                  BlendMode.srcIn,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Spacer(),
                          Container(
                            height: 6,
                            decoration: BoxDecoration(
                              color: const Color(0xFF5FCCC4),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildFeaturedChallenge() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Featured Challenge',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A3A3A),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFD4EEEC)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Background decoration
              Positioned(
                top: -32,
                right: -32,
                child: Container(
                  width: 128,
                  height: 128,
                  decoration: BoxDecoration(
                    color: const Color(0xFF5FCCC4).withValues(alpha: 0.05),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              
              // Content
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    (_featured != null ? (_featured!['name'] ?? 'Challenge') : 'Featured Challenge').toString(),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A3A3A),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time,
                        size: 16,
                        color: Color(0xFF5FCCC4),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${((_featured != null ? (_featured!['duration_minutes'] ?? 0) : 0) as int)} mins',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF5A7878),
                        ),
                      ),
                      const SizedBox(width: 24),
                      const Icon(
                        Icons.local_fire_department_outlined,
                        size: 16,
                        color: Color(0xFF5FCCC4),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        (_featured != null ? ((_featured!['energy_level'] ?? 'MEDIUM').toString()) : 'MEDIUM'),
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF5A7878),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Progress bar
                  Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F7F6),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: 0.33,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF5FCCC4),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_featured != null) {
                          _startChallengeItem(_featured!);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5FCCC4),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 2,
                      ),
                      child: const Text(
                        'Start Challenge',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickChallenges() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Challenges',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A3A3A),
          ),
        ),
        const SizedBox(height: 16),
        ...(_quick.isNotEmpty ? _quick : const <Map<String, dynamic>>[]).map((challenge) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFD4EEEC)),
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
                        (challenge['name'] ?? 'Challenge').toString(),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A3A3A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.access_time,
                            size: 16,
                            color: Color(0xFF5FCCC4),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${(challenge['duration_minutes'] ?? 0)} mins',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF5A7878),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () => _startChallengeItem(challenge),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5FCCC4),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
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
          ),
        )),
      ],
    );
  }


}