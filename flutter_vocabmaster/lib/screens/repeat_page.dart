import 'package:flutter/material.dart';
import '../widgets/animated_background.dart';
import '../models/word.dart';
import '../services/api_service.dart';

class RepeatPage extends StatefulWidget {
  const RepeatPage({Key? key}) : super(key: key);

  @override
  State<RepeatPage> createState() => _RepeatPageState();
}

class _RepeatPageState extends State<RepeatPage> {
  int currentIndex = 0;
  bool showTranslation = false;
  bool isFlipped = false;
  bool isLoading = true;
  List<Word> words = [];
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _loadWords();
  }

  Future<void> _loadWords() async {
    try {
      final loadedWords = await _apiService.getAllWords();
      setState(() {
        words = loadedWords;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e')),
      );
    }
  }

  void handleNext() {
    if (words.isEmpty) return;
    setState(() {
      currentIndex = (currentIndex + 1) % words.length;
      showTranslation = false;
      isFlipped = false;
    });
  }

  void handlePrevious() {
    if (words.isEmpty) return;
    setState(() {
      currentIndex = (currentIndex - 1 + words.length) % words.length;
      showTranslation = false;
      isFlipped = false;
    });
  }

  void handleFlip() {
    setState(() {
      isFlipped = !isFlipped;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        body: Stack(
          children: [
            const AnimatedBackground(isDark: true),
            const Center(child: CircularProgressIndicator(color: Colors.cyan)),
          ],
        ),
      );
    }

    if (words.isEmpty) {
      return Scaffold(
        body: Stack(
          children: [
            const AnimatedBackground(isDark: true),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Henüz hiç kelime yok.\nSözlükten kelime ekleyin!',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Geri Dön'),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final currentCard = words[currentIndex % words.length];

    return Scaffold(
      body: Stack(
        children: [
          const AnimatedBackground(isDark: true),
          SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.arrow_back, color: Colors.white),
                          ),
                          Text(
                            'Tekrar (${currentIndex + 1}/${words.length})',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            onPressed: _loadWords,
                            icon: const Icon(Icons.refresh, color: Colors.white),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: (currentIndex + 1) / words.length,
                          backgroundColor: Colors.white.withOpacity(0.2),
                          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF06b6d4)),
                          minHeight: 8,
                        ),
                      ),
                    ],
                  ),
                ),
                // Flashcard
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                    child: GestureDetector(
                      onTap: handleFlip,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 500),
                        child: isFlipped
                            ? _buildBackCard(currentCard)
                            : _buildFrontCard(currentCard),
                      ),
                    ),
                  ),
                ),
                // Navigation Buttons
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: handlePrevious,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white.withOpacity(0.1),
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: Colors.white.withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.chevron_left, color: Colors.white),
                              SizedBox(width: 8),
                              Text(
                                'Önceki',
                                style: TextStyle(color: Colors.white, fontSize: 16),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF06b6d4), Color(0xFF3b82f6)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ElevatedButton(
                            onPressed: handleNext,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Sonraki',
                                  style: TextStyle(color: Colors.white, fontSize: 16),
                                ),
                                SizedBox(width: 8),
                                Icon(Icons.chevron_right, color: Colors.white),
                              ],
                            ),
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
    );
  }

  Widget _buildFrontCard(Word card) {
    // Get first sentence if available
    final example = card.sentences.isNotEmpty ? card.sentences.first.sentence : 'No example';
    final exampleTr = card.sentences.isNotEmpty ? card.sentences.first.translation : 'Örnek cümle yok';

    return Container(
      key: const ValueKey('front'),
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category Badge and Audio Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF06b6d4), Color(0xFF3b82f6)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  card.difficulty.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
              ),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.volume_up, color: Colors.white),
              ),
            ],
          ),
          // Word Display
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    card.englishWord,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  // Translation is HIDDEN on front card usually, but original code showed it small.
                  // Original code: showed translation small.
                  const SizedBox(height: 16),
                  Text(
                    '?', // Hide translation on front or show hinted? Original 'translation' field was showed.
                    // Actually standard flashcard habits: Front = Word, Back = Meaning.
                    // But original code showed 'translation' (which was 'İngilizce Kelime'?? No wait).
                    // Original code: word: 'flip in', translation: 'İngilizce Kelime'. 
                    // Wait, original code data was weird: 'translation': 'İngilizce Kelime'.
                    // I will show "Tap to flip" or just nothing.
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Example Sentence
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0x1A06b6d4),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0x4D22d3ee),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                Text(
                  '"$example"',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                if (showTranslation) ...[
                  const SizedBox(height: 12),
                  Text(
                    exampleTr,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 13,
                    ),
                  ),
                ] else ...[
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        showTranslation = true;
                      });
                    },
                    child: const Text(
                      'Çeviri görmek için dokunun',
                      style: TextStyle(color: Color(0xFF22d3ee)),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.favorite_border, color: Colors.white),
                  label: const Text(
                    'Favorilere Ekle',
                    style: TextStyle(color: Colors.white),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(
                      color: const Color(0x4D22d3ee),
                      width: 1,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.star_border, color: Colors.white),
                  label: const Text(
                    'Öğrendim',
                    style: TextStyle(color: Colors.white),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(
                      color: const Color(0x4D22d3ee),
                      width: 1,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBackCard(Word card) {
    return Container(
      key: const ValueKey('back'),
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0x3306b6d4), Color(0x333b82f6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0x4D22d3ee),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              card.turkishMeaning,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 36,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              card.englishWord,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

