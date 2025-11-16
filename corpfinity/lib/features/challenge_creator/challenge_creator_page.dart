import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../auth/auth_service.dart';
import '../active_challenge/active_challenge_session_page.dart';

class ChallengeCreatorPage extends StatefulWidget {
  final String? initialPillar;
  const ChallengeCreatorPage({super.key, this.initialPillar});

  @override
  State<ChallengeCreatorPage> createState() => _ChallengeCreatorPageState();
}

class _ChallengeCreatorPageState extends State<ChallengeCreatorPage> {
  int currentStep = 1;
  String selectedEnergy = '';
  String selectedTime = '';
  Map<String, dynamic>? _apiChallenge;
  List<Map<String, dynamic>> _apiActivities = const [];
  int? _apiChallengeId;

  void _handleEnergySelect(String energy) {
    setState(() {
      selectedEnergy = energy;
      selectedTime = selectedTime.isNotEmpty ? selectedTime : '5';
    });
    
    // Auto-advance to next step after selection
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          currentStep = 2;
        });
        _fetchNextChallenge();
      }
    });
  }

  // Time selection removed from flow

  void _handleBack() {
    if (currentStep > 1) {
      setState(() {
        currentStep = currentStep - 1;
      });
    }
  }

  void _handleClose() {
    Navigator.pop(context);
  }

  Future<void> _fetchNextChallenge() async {
    final token = await AuthService().getValidAccessToken();
    if (token == null || widget.initialPillar == null || selectedEnergy.isEmpty) return;
    final url = Uri.parse('${AuthService().baseUrl}/challenges/next').replace(queryParameters: {
      'pillar': widget.initialPillar!,
      'energy_level': selectedEnergy.toUpperCase(),
    });
    final res = await http.get(url, headers: { 'Authorization': 'Bearer $token' });
    if (res.statusCode == 200) {
      final data = json.decode(res.body);
      final item = data['item'];
      if (item != null) {
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
        setState(() {
          _apiChallenge = item;
          _apiActivities = activities;
          _apiChallengeId = item['id'] as int?;
        });
      }
    }
  }

  void _startChallenge() {
    final challenge = _generateChallenge();
    final activities = _apiActivities.isNotEmpty
        ? _apiActivities
        : _convertActivitiesToProperFormat(List<String>.from(challenge['activities'] ?? []));
    final totalDuration = activities.fold<int>(0, (sum, a) => sum + (a['duration'] as int? ?? 0));
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => ActiveChallengeSessionPage(
          challengeName: challenge['name'] ?? 'Custom Wellness Session',
          activities: activities,
          totalDuration: totalDuration > 0 ? totalDuration : _calculateTotalDuration(activities),
          challengeId: _apiChallengeId,
        ),
      ),
    );
  }

  int _calculateTotalDuration(List<dynamic>? activities) {
    if (activities == null) return 300; // Default 5 minutes
    
    int total = 0;
    for (var activity in activities) {
      if (activity is Map<String, dynamic>) {
        total += (activity['duration'] as int? ?? 60);
      }
    }
    
    return total > 0 ? total : (int.tryParse(selectedTime) ?? 5) * 60;
  }

  List<Map<String, dynamic>> _convertActivitiesToProperFormat(List<String> activityStrings) {
    List<Map<String, dynamic>> activities = [];
    
    for (String activityStr in activityStrings) {
      // Extract title and duration from string like "Deep breathing (2 min)"
      String title = activityStr;
      int duration = 60; // Default 1 minute
      
      if (activityStr.contains('(') && activityStr.contains('min)')) {
        title = activityStr.split('(')[0].trim();
        String durationStr = activityStr.split('(')[1].split(' min)')[0];
        duration = (int.tryParse(durationStr) ?? 1) * 60; // Convert to seconds
      }
      
      activities.add({
        'title': title,
        'duration': duration,
        'instructions': _getInstructionsForActivity(title),
      });
    }
    
    return activities;
  }

  String _getInstructionsForActivity(String title) {
    final instructions = {
      'Deep breathing': 'Breathe in for 4 seconds, hold for 4, exhale for 4',
      'Deep breathing exercises': 'Focus on slow, deep breaths to calm your mind',
      'Guided breathing': 'Follow the guided breathing pattern for relaxation',
      'Progressive muscle relaxation': 'Tense and release each muscle group systematically',
      'Gentle neck stretches': 'Slowly move your neck in gentle circles and stretches',
      'Shoulder and neck stretches': 'Release tension in your shoulders and neck',
      'Gentle body stretches': 'Stretch your major muscle groups gently',
      'Gentle yoga stretches': 'Perform gentle yoga poses for flexibility',
      'Mindful gratitude': 'Reflect on three things you are grateful for',
      'Mindful moment reflection': 'Take a moment to be present and aware',
      'Gratitude meditation': 'Focus on feelings of gratitude and appreciation',
      'Mindfulness meditation': 'Focus on your breath and let thoughts pass by',
    };
    
    return instructions[title] ?? 'Focus on this activity mindfully and breathe deeply';
  }

  List<String> _deriveBenefits(Map<String, dynamic>? item) {
    if (item == null) {
      return const ['Stress relief', 'Mental clarity', 'Relaxation'];
    }
    final pillar = (item['pillar'] as String?)?.toLowerCase() ?? '';
    if (pillar.contains('stress')) {
      return const ['Stress relief', 'Calm nervous system', 'Relaxation'];
    }
    if (pillar.contains('sleep')) {
      return const ['Better sleep', 'Wind-down', 'Relaxation'];
    }
    if (pillar.contains('energy')) {
      return const ['Energy boost', 'Activation', 'Alertness'];
    }
    if (pillar.contains('fitness') || pillar.contains('physical')) {
      return const ['Mobility', 'Flexibility', 'Body alignment'];
    }
    if (pillar.contains('focus')) {
      return const ['Focus', 'Clarity', 'Calm'];
    }
    if (pillar.contains('social')) {
      return const ['Connection', 'Wellbeing', 'Positivity'];
    }
    return const ['Wellbeing', 'Mind-body balance', 'Calm'];
  }

  void _regenerateChallenge() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Generating new challenge... ✨'),
        backgroundColor: Color(0xFF5FCCC4),
        duration: Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
    _fetchNextChallenge();
  }

  Map<String, dynamic> _generateChallenge() {
    // Challenge generation logic based on energy and time
    final challenges = {
      'low': {
        '3': {
          'name': 'Quick Calm Moment',
          'activities': [
            'Deep breathing (1 min)',
            'Gentle neck stretches (1 min)',
            'Mindful gratitude (1 min)'
          ],
          'benefits': ['Instant relaxation', 'Reduced tension', 'Mental clarity'],
          'illustration': 'stress_reduction.svg'
        },
        '5': {
          'name': 'Gentle Energy Restore',
          'activities': [
            'Deep breathing exercises (2 min)',
            'Shoulder and neck stretches (2 min)',
            'Mindful moment reflection (1 min)'
          ],
          'benefits': ['Gentle energy boost', 'Muscle relaxation', 'Stress relief'],
          'illustration': 'stress_reduction.svg'
        },
        '7': {
          'name': 'Peaceful Reset',
          'activities': [
            'Guided breathing (3 min)',
            'Gentle body stretches (3 min)',
            'Gratitude meditation (1 min)'
          ],
          'benefits': ['Deep relaxation', 'Body awareness', 'Emotional balance'],
          'illustration': 'better sleep.svg'
        },
        '10': {
          'name': 'Complete Relaxation',
          'activities': [
            'Progressive muscle relaxation (4 min)',
            'Gentle yoga stretches (4 min)',
            'Mindfulness meditation (2 min)'
          ],
          'benefits': ['Full body relaxation', 'Stress release', 'Mental peace'],
          'illustration': 'better sleep.svg'
        }
      },
      'medium': {
        '3': {
          'name': 'Quick Focus Boost',
          'activities': [
            'Energizing breathing (1 min)',
            'Desk stretches (1 min)',
            'Focus intention (1 min)'
          ],
          'benefits': ['Mental clarity', 'Physical relief', 'Energy boost'],
          'illustration': 'increased_energy.svg'
        },
        '5': {
          'name': 'Balanced Wellness',
          'activities': [
            'Breathing exercises (2 min)',
            'Desk yoga sequence (2 min)',
            'Mindful focus (1 min)'
          ],
          'benefits': ['Improved focus', 'Body alignment', 'Stress reduction'],
          'illustration': 'physical_fitness.svg'
        },
        '7': {
          'name': 'Mindful Movement',
          'activities': [
            'Dynamic breathing (2 min)',
            'Seated yoga flow (3 min)',
            'Concentration practice (2 min)'
          ],
          'benefits': ['Enhanced focus', 'Flexibility', 'Mind-body connection'],
          'illustration': 'physical_fitness.svg'
        },
        '10': {
          'name': 'Focused Wellness Session',
          'activities': [
            'Energizing breath work (3 min)',
            'Full desk yoga routine (5 min)',
            'Meditation for clarity (2 min)'
          ],
          'benefits': ['Deep focus', 'Physical wellness', 'Mental balance'],
          'illustration': 'Social-connection.svg'
        }
      },
      'high': {
        '3': {
          'name': 'Power Energy Burst',
          'activities': [
            'Energizing breath (1 min)',
            'Dynamic stretches (1 min)',
            'Motivation boost (1 min)'
          ],
          'benefits': ['Instant energy', 'Physical activation', 'Mental sharpness'],
          'illustration': 'increased_energy.svg'
        },
        '5': {
          'name': 'Active Wellness',
          'activities': [
            'Power breathing (2 min)',
            'Active stretching (2 min)',
            'Energy meditation (1 min)'
          ],
          'benefits': ['High energy', 'Physical strength', 'Mental alertness'],
          'illustration': 'physical_fitness.svg'
        },
        '7': {
          'name': 'Dynamic Flow',
          'activities': [
            'Energizing breathwork (2 min)',
            'Active movement flow (3 min)',
            'Power meditation (2 min)'
          ],
          'benefits': ['Peak energy', 'Full body activation', 'Mental clarity'],
          'illustration': 'physical_fitness.svg'
        },
        '10': {
          'name': 'Complete Energy Session',
          'activities': [
            'Advanced breathing (3 min)',
            'Full body movement (5 min)',
            'Active meditation (2 min)'
          ],
          'benefits': ['Maximum energy', 'Full body wellness', 'Peak performance'],
          'illustration': 'increased_energy.svg'
        }
      }
    };

    if (_apiChallenge != null) return _apiChallenge!;
    return challenges[selectedEnergy]?[selectedTime] ?? challenges['medium']?['5'] ?? {};
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: currentStep == 1 ? null : _handleBack,
                    icon: const Icon(Icons.arrow_back_ios),
                    color: currentStep == 1 ? Colors.grey : Colors.grey[600],
                  ),
                  const Text(
                    'Create Challenge',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  IconButton(
                    onPressed: _handleClose,
                    icon: const Icon(Icons.close),
                    color: Colors.grey[600],
                  ),
                ],
              ),
            ),

            // Progress Indicator
            _buildProgressIndicator(),

            // Step Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: _buildStepContent(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(2, (index) {
            final stepNumber = index + 1;
            final isActive = stepNumber == currentStep;
            final isCompleted = stepNumber < currentStep;

              return Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isActive || isCompleted
                          ? const Color(0xFF5FCCC4)
                          : Colors.grey[300],
                    ),
                    child: Center(
                      child: isCompleted
                          ? const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 20,
                            )
                          : Text(
                              stepNumber.toString(),
                              style: TextStyle(
                                color: isActive || isCompleted
                                    ? Colors.white
                                    : Colors.grey[600],
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                    ),
                  ),
                  if (stepNumber < 2)
                    Container(
                      width: 48,
                      height: 2,
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      color: isCompleted
                          ? const Color(0xFF5FCCC4)
                          : Colors.grey[300],
                    ),
                ],
              );
            }),
          ),
          const SizedBox(height: 12),
          Text(
            'Step $currentStep of 2',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepContent() {
    switch (currentStep) {
      case 1:
        return _buildEnergySelection();
      case 2:
        return _buildChallengePreview();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildEnergySelection() {
    final energyLevels = [
      {
        'id': 'low',
        'title': 'Low Energy',
        'description': 'Feeling tired, need gentle activities',
        'icon': '🔋',
        'activities': ['Deep breathing', 'Gentle stretches', 'Mindful moments'],
      },
      {
        'id': 'medium',
        'title': 'Medium Energy',
        'description': 'Feeling okay, ready for moderate activities',
        'icon': '⚡',
        'activities': ['Desk yoga', 'Walking meditation', 'Breathing exercises'],
      },
      {
        'id': 'high',
        'title': 'High Energy',
        'description': 'Feeling great, ready for active challenges',
        'icon': '🚀',
        'activities': ['Full body stretches', 'Active meditation', 'Energy flows'],
      },
    ];

    return SingleChildScrollView(
      child: Column(
        children: [
          // Title and Illustration
          Column(
            children: [
              const SizedBox(height: 24),
              SvgPicture.asset(
                'assets/illustrations/battery_illustration.svg',
                width: 128,
                height: 128,
              ),
              const SizedBox(height: 24),
              const Text(
                'How are you feeling right now?',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Choose your current energy level to get personalized activities',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),

          const SizedBox(height: 32),

          // Energy Level Options
          ...energyLevels.map((level) => _buildEnergyOption(level)),

          const SizedBox(height: 32),

          // Helper Text
          Text(
            'Don\'t worry, you can always adjust this later',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildEnergyOption(Map<String, dynamic> level) {
    final isSelected = selectedEnergy == level['id'];
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => _handleEnergySelect(level['id']),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF5FCCC4).withValues(alpha: 0.1) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? const Color(0xFF5FCCC4) : Colors.grey[300]!,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _energyIcon(level['id'] as String),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          level['title'],
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      level['description'],
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _energyIcon(String id) {
    switch (id) {
      case 'low':
        return const Icon(Icons.battery_alert, color: Colors.red, size: 28);
      case 'medium':
        return const Icon(Icons.battery_charging_full, color: Colors.amber, size: 28);
      case 'high':
        return const Icon(Icons.battery_full, color: Colors.green, size: 28);
      default:
        return const Icon(Icons.battery_unknown, color: Colors.grey, size: 28);
    }
  }



  Widget _buildChallengePreview() {
    final challenge = _generateChallenge();
    final duration = selectedTime == '10' ? '10+' : selectedTime;
    final activitiesStrs = _apiActivities.isNotEmpty
        ? _apiActivities
            .map((a) => (a['instructions'] as String?) ?? '')
            .where((s) => s.isNotEmpty)
            .toList()
        : List<String>.from((challenge['activities'] as List<String>?) ?? []);
    final benefitsList = (challenge['benefits'] as List<String>?) ?? _deriveBenefits(_apiChallenge);
    
    return SingleChildScrollView(
      child: Column(
        children: [
          // Title and Illustration
          Column(
            children: [
              const SizedBox(height: 24),
              SvgPicture.asset(
                'assets/illustrations/${challenge['illustration'] ?? 'increased_energy.svg'}',
                width: 128,
                height: 128,
              ),
              const SizedBox(height: 24),
              const Text(
                'Your Personalized Challenge',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Perfect for your current energy and available time',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),

          const SizedBox(height: 32),

          // Challenge Card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF5FCCC4),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF5FCCC4).withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Challenge Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF5FCCC4),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '$duration min session',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.auto_awesome,
                      color: const Color(0xFF5FCCC4),
                      size: 20,
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Challenge Name
                Text(
                  challenge['name'] ?? 'Wellness Session',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Activities Section
                const Text(
                  'What you\'ll do:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 12),
                
                ...activitiesStrs.asMap().entries.map((entry) {
                  final index = entry.key;
                  final activity = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          margin: const EdgeInsets.only(right: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF5FCCC4).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFF5FCCC4),
                              width: 1,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              '${index + 1}',
                              style: const TextStyle(
                                color: Color(0xFF5FCCC4),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            activity,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                
                const SizedBox(height: 20),
                
                // Benefits Section
                const Text(
                  'Expected benefits:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 12),
                
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: benefitsList
                      .map((benefit) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF5FCCC4).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(0xFF5FCCC4).withValues(alpha: 0.3),
                              ),
                            ),
                            child: Text(
                              benefit,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF5FCCC4),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ))
                      .toList(),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Action Buttons
          Column(
            children: [
              // Start Challenge Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _startChallenge,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5FCCC4),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
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
              
              const SizedBox(height: 12),
              
              // Regenerate Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _regenerateChallenge,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF5FCCC4),
                    side: const BorderSide(color: Color(0xFF5FCCC4)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.refresh, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Regenerate',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Helper Text
          Text(
            'This challenge is personalized based on your selections',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}