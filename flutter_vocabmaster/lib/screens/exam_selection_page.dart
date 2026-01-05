import 'package:flutter/material.dart';
import '../widgets/animated_background.dart';
import 'exam_chat_page.dart';

class ExamSelectionPage extends StatelessWidget {
  const ExamSelectionPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const AnimatedBackground(isDark: true),
          SafeArea(
            child: Column(
              children: [
                // Custom App Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                      ),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Sınav Hazırlığı',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Hangi sınava hazırlanıyorsun?',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        const SizedBox(height: 20),
                        // Big Generic Icon
                        const Icon(
                          Icons.menu_book_rounded,
                          size: 64,
                          color: Color(0xFF0ea5e9),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Sınavını Seç',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Yapay zeka ile pratik yaparak hazırlan',
                          style: TextStyle(
                            color: Color(0xFF0ea5e9),
                            fontSize: 16,
                          ),
                        ),
                        
                        const SizedBox(height: 48),
                        
                        // IELTS Card
                        _buildExamCard(
                          context,
                          title: 'IELTS',
                          subtitle: 'International English Language\nTesting System',
                          features: [
                            'Speaking Part 1-3',
                            'Band Score Feedback',
                            'Real Exam Questions',
                          ],
                          color: const Color(0xFF0ea5e9), // Cyan
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ExamChatPage(examType: 'IELTS'),
                              ),
                            );
                          },
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // TOEFL Card
                        _buildExamCard(
                          context,
                          title: 'TOEFL',
                          subtitle: 'Test of English as a Foreign Language',
                          features: [
                            'Speaking Task 1-4',
                            'Score Evaluation',
                            'Academic Topics',
                          ],
                          color: const Color(0xFF3b82f6), // Blue
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ExamChatPage(examType: 'TOEFL'),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExamCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required List<String> features,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF1e3a8a).withOpacity(0.3),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.4),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.verified_outlined, color: Colors.white, size: 32),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            ...features.map((feature) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle_outline, color: color, size: 20),
                      const SizedBox(width: 12),
                      Text(
                        feature,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                )),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'AI-powered practice',
                  style: TextStyle(
                    color: color, // Matching the brand color
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Icon(Icons.arrow_forward, color: color, size: 20),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
