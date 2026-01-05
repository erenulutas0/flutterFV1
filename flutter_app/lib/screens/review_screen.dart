import 'package:flutter/material.dart';
import '../models/word.dart';
import '../services/srs_service.dart';
import '../services/unsplash_service.dart';

class ReviewScreen extends StatefulWidget {
  const ReviewScreen({Key? key}) : super(key: key);

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  List<Word> reviewWords = [];
  int currentIndex = 0;
  bool isLoading = true;
  bool showAnswer = false;
  bool isSubmitting = false;
  String? currentImageUrl;

  Future<void> _loadCurrentWordImage() async {
    if (reviewWords.isEmpty || currentIndex >= reviewWords.length) return;

    // Loading durumu için resmi sıfırla
    setState(() {
      currentImageUrl = null;
    });

    final word = reviewWords[currentIndex];
    // İngilizce kelimeyi sorgu olarak kullan
    final url = await UnsplashService.getImageUrl(word.englishWord);

    if (mounted && url != null) {
      setState(() {
        currentImageUrl = url;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _loadReviewWords();
  }

  Future<void> _loadReviewWords() async {
    setState(() => isLoading = true);
    
    final words = await SRSService.getReviewWords();
    
    setState(() {
      reviewWords = words;
      isLoading = false;
    });
    
    // İlk kelime için resim yükle
    _loadCurrentWordImage();
  }

  void _flipCard() {
    setState(() {
      showAnswer = !showAnswer;
    });
  }

  Future<void> _submitQuality(int quality) async {
    if (isSubmitting || currentIndex >= reviewWords.length) return;

    setState(() => isSubmitting = true);

    final currentWord = reviewWords[currentIndex];
    await SRSService.submitReview(currentWord.id!, quality);

    setState(() {
      isSubmitting = false;
      showAnswer = false;
      
      if (currentIndex < reviewWords.length - 1) {
        currentIndex++;
        // Yeni kelime için resim yükle
        _loadCurrentWordImage();
      } else {
        // Review tamamlandı
        _showCompletionDialog();
      }
    });
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.celebration, color: Colors.amber, size: 32),
            SizedBox(width: 12),
            Text('Tebrikler!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Bugünün tekrarlarını tamamladınız! 🎉',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            Text(
              '${reviewWords.length} kelime tekrar edildi',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Dialog'u kapat
              Navigator.of(context).pop(); // Review screen'i kapat
            },
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Kelime Tekrarı'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (reviewWords.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Kelime Tekrarı'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.check_circle_outline,
                size: 80,
                color: Colors.green,
              ),
              const SizedBox(height: 24),
              const Text(
                'Bugün tekrar edilecek kelime yok!',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Harika iş çıkarıyorsunuz! 🎉',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Ana Sayfaya Dön'),
              ),
            ],
          ),
        ),
      );
    }

    final currentWord = reviewWords[currentIndex];
    final progress = (currentIndex + 1) / reviewWords.length;

    return Scaffold(
      appBar: AppBar(
        title: Text('Tekrar (${currentIndex + 1}/${reviewWords.length})'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey[300],
          ),
        ),
      ),
      body: Column(
        children: [
          _buildFlashcard(),
          if (showAnswer) _buildQualityButtons(),
        ],
      ),
    );
  }

  Widget _buildFlashcard() {
    final currentWord = reviewWords[currentIndex];

    // Try to get an example sentence
    String? exampleSentence;
    if (currentWord.sentences.isNotEmpty) {
      exampleSentence = currentWord.sentences.first.sentence;
    }

    return Expanded(
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          elevation: 0,
          borderRadius: BorderRadius.circular(24),
          clipBehavior: Clip.antiAlias,
          child: Container(
             decoration: BoxDecoration(
                color: const Color(0xFF1E1E2C),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white12, width: 1.5),
             ),
             child: Stack(
              children: [
                // Arkaplan Resmi (Varsa)
                if (currentImageUrl != null)
                  Positioned.fill(
                    child: Opacity(
                      opacity: 0.15,
                      child: Image.network(
                        currentImageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const SizedBox(),
                      ),
                    ),
                  ),
                
                // Audio Button (Top Right)
                Positioned(
                  top: 16,
                  right: 16,
                  child: IconButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Seslendirme yakında...'), duration: Duration(seconds: 1)),
                      );
                    },
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.volume_up_rounded, color: Colors.white70),
                    ),
                  ),
                ),

                // İçerik
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Part of Speech Placeholder
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.blueAccent.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.blueAccent.withOpacity(0.3)),
                        ),
                        child: Text(
                          'Vocabulary',
                          style: TextStyle(
                            color: Colors.blueAccent[100],
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const Spacer(),
                      
                      // Main Word
                      Text(
                        showAnswer
                            ? currentWord.turkishMeaning
                            : currentWord.englishWord,
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w800,
                          color: showAnswer ? const Color(0xFF4CAF50) : Colors.white,
                          shadows: [
                             Shadow(
                               color: Colors.black.withOpacity(0.3),
                               offset: const Offset(0, 2),
                               blurRadius: 4,
                             )
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Label
                      Text(
                        showAnswer ? 'Türkçe Anlamı' : 'İngilizce Kelime',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[400],
                          letterSpacing: 1.0,
                        ),
                      ),

                      // Example Sentence
                      if (!showAnswer && exampleSentence != null) ...[
                        const SizedBox(height: 32),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '"$exampleSentence"',
                            style: const TextStyle(
                              fontSize: 16,
                              fontStyle: FontStyle.italic,
                              color: Colors.white70,
                              height: 1.4,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],

                      const Spacer(),

                      if (!showAnswer)
                        const Text(
                          'Cevabı görmek için dokunun',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white30,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                    ],
                  ),
                ),
                
                // Tap Handler
                Positioned.fill(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          showAnswer = !showAnswer;
                        });
                      },
                      splashColor: Colors.white.withOpacity(0.05),
                      highlightColor: Colors.white.withOpacity(0.02),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQualityButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900], // Dark background
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Ne kadar iyi hatırladınız?',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white70, // White text
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _QualityButton(
                  label: 'Hiç\nBilmedim',
                  quality: 0,
                  color: Colors.red,
                  onPressed: () => _submitQuality(0),
                  isSubmitting: isSubmitting,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _QualityButton(
                  label: 'Zor',
                  quality: 2,
                  color: Colors.orange,
                  onPressed: () => _submitQuality(2),
                  isSubmitting: isSubmitting,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _QualityButton(
                  label: 'İyi',
                  quality: 4,
                  color: Colors.lightGreen,
                  onPressed: () => _submitQuality(4),
                  isSubmitting: isSubmitting,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _QualityButton(
                  label: 'Kolay',
                  quality: 5,
                  color: Colors.green,
                  onPressed: () => _submitQuality(5),
                  isSubmitting: isSubmitting,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QualityButton extends StatelessWidget {
  final String label;
  final int quality;
  final Color color;
  final VoidCallback onPressed;
  final bool isSubmitting;

  const _QualityButton({
    required this.label,
    required this.quality,
    required this.color,
    required this.onPressed,
    required this.isSubmitting,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: isSubmitting ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
