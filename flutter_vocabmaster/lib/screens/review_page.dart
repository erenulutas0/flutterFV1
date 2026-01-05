import 'package:flutter/material.dart';
import '../widgets/animated_background.dart';
import '../widgets/bottom_nav.dart';
import '../services/global_state.dart';

class ReviewPage extends StatefulWidget {
  const ReviewPage({Key? key}) : super(key: key);

  @override
  State<ReviewPage> createState() => _ReviewPageState();
}

class _ReviewPageState extends State<ReviewPage> {
  int _currentIndex = 0;
  final int _totalCards = 359;
  
  final List<Map<String, String>> _flashcards = [
    {
      'word': 'flip in',
      'meaning': 'İngilizce Kelime',
      'example': '"Can you just flip the application in the mail slot on your way out?"',
      'translation': 'Çeviri görmek için dokunun',
      'category': 'Vocabulary',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: GlobalState.isMatching,
      builder: (context, isMatching, _) {
        // Dynamic sizing to fit content when matching overlay is active
        final double cardPadding = isMatching ? 12.0 : 20.0;
        final double spacerHeight = isMatching ? 10.0 : 20.0;
        final double smallSpacerHeight = isMatching ? 4.0 : 8.0;
        final double wordFontSize = isMatching ? 32.0 : 42.0;
        final double meaningFontSize = isMatching ? 14.0 : 16.0;
        final double sentencePadding = isMatching ? 10.0 : 16.0;
        final double sentenceFontSize = isMatching ? 13.0 : 14.0;
        final double sectionGap = isMatching ? 16.0 : 32.0; // Reduced from original
        
        return Scaffold(
          body: Stack(
            children: [
              const AnimatedBackground(isDark: true),
              SafeArea(
                child: Column(
                  children: [
                    // Header
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back, color: Colors.white),
                            onPressed: () => Navigator.pop(context),
                          ),
                          Text(
                            'Tekrar (${_currentIndex + 1}/$_totalCards)',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.refresh, color: Colors.white),
                            onPressed: () {
                              setState(() => _currentIndex = 0);
                            },
                          ),
                        ],
                      ),
                    ),
                    
                    // Progress Bar
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: (_currentIndex + 1) / _totalCards,
                          backgroundColor: Colors.white.withOpacity(0.2),
                          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF06b6d4)),
                          minHeight: 8,
                        ),
                      ),
                    ),
                    
                    SizedBox(height: spacerHeight), // Top gap
                    
                    // Flashcard
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1e3a8a).withOpacity(0.5),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: Colors.white.withOpacity(0.2), width: 2),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                return SingleChildScrollView(
                                  padding: EdgeInsets.all(cardPadding),
                                  child: ConstrainedBox(
                                    constraints: BoxConstraints(
                                      minHeight: constraints.maxHeight - (cardPadding * 2),
                                    ),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        // Top Row: Badge & Speaker
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF06b6d4),
                                                borderRadius: BorderRadius.circular(20),
                                              ),
                                              child: const Text(
                                                'Vocabulary',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.volume_up, color: Colors.white70),
                                              onPressed: () {},
                                              padding: EdgeInsets.zero,
                                              constraints: const BoxConstraints(),
                                            ),
                                          ],
                                        ),
                                        
                                        SizedBox(height: spacerHeight),
                                        
                                        // Word & Meaning
                                        Column(
                                          children: [
                                            Text(
                                              'flip in',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: wordFontSize,
                                                fontWeight: FontWeight.bold,
                                                height: 1.1,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                            SizedBox(height: smallSpacerHeight),
                                            Text(
                                              'İngilizce Kelime',
                                              style: TextStyle(
                                                color: Colors.white.withOpacity(0.7),
                                                fontSize: meaningFontSize,
                                              ),
                                            ),
                                          ],
                                        ),
                                        
                                        SizedBox(height: spacerHeight),
                                        
                                        // Bottom Section
                                        Column(
                                          children: [
                                            // Sentence Box
                                            Container(
                                              width: double.infinity,
                                              padding: EdgeInsets.all(sentencePadding),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF0ea5e9).withOpacity(0.2),
                                                borderRadius: BorderRadius.circular(16),
                                                border: Border.all(
                                                  color: const Color(0xFF0ea5e9).withOpacity(0.3),
                                                ),
                                              ),
                                              child: Column(
                                                children: [
                                                  Text(
                                                    '"Can you just flip the application in the mail slot on your way out?"',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: sentenceFontSize,
                                                      fontStyle: FontStyle.italic,
                                                      height: 1.4,
                                                    ),
                                                    textAlign: TextAlign.center,
                                                  ),
                                                  SizedBox(height: smallSpacerHeight + 4),
                                                  Text(
                                                    'Çeviri görmek için dokunun',
                                                    style: TextStyle(
                                                      color: const Color(0xFF06b6d4),
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            
                                            SizedBox(height: spacerHeight),
                                            
                                            // Action Buttons
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: _buildActionButton(
                                                    icon: Icons.favorite_border,
                                                    label: 'Favorilere Ekle',
                                                    onTap: () {},
                                                    isCompact: isMatching,
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child: _buildActionButton(
                                                    icon: Icons.star_border,
                                                    label: 'Öğrendim',
                                                    onTap: () {},
                                                    isCompact: isMatching,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                    
                    SizedBox(height: spacerHeight),
                    
                    // Navigation Buttons (Outside Card)
                    Padding(
                      padding: EdgeInsets.fromLTRB(20, 0, 20, isMatching ? 10 : 20),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _currentIndex > 0
                                  ? () {
                                      setState(() => _currentIndex--);
                                    }
                                  : null,
                              icon: const Icon(Icons.chevron_left),
                              label: const Text('Önceki'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: BorderSide(color: Colors.white.withOpacity(0.3)),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                backgroundColor: const Color(0xFF1e3a8a).withOpacity(0.3),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _currentIndex < _totalCards - 1
                                  ? () {
                                      setState(() => _currentIndex++);
                                    }
                                  : null,
                              icon: const Icon(Icons.chevron_right),
                              label: const Text('Sonraki'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF06b6d4),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 4,
                                shadowColor: const Color(0xFF06b6d4).withOpacity(0.5),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          bottomNavigationBar: BottomNav(
            currentIndex: 2,
            onTap: (index) {
              if (index != 2) {
                Navigator.pop(context);
              }
            },
          ),
        );
      },
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isCompact = false,
  }) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(isCompact ? 8 : 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: isCompact ? 20 : 24),
          ),
          SizedBox(height: isCompact ? 4 : 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
