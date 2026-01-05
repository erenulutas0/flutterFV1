import 'package:flutter/material.dart';
import '../services/groq_service.dart';
import '../theme/app_theme.dart';
import '../services/offline_storage_service.dart';

class ReadingScreen extends StatefulWidget {
  const ReadingScreen({super.key});

  @override
  State<ReadingScreen> createState() => _ReadingScreenState();
}



class _ReadingScreenState extends State<ReadingScreen> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  String _selectedLevel = 'B1';
  bool _isLoading = true; // Start true to check cache first
  Map<String, dynamic>? _content;
  
  // Interactive Word State
  bool _isWordModeEnabled = false;
  int? _selectedWordIndex; 
  String? _currentWordDefinition;
  
  // Highlighting State
  String? _highlightedQuote;
  
  // Quiz State
  Map<int, String?> _userAnswers = {};
  bool _showResults = false;
  int _score = 0;

  final List<String> _levels = ['A1', 'A2', 'B1', 'B2', 'C1', 'C2'];

  @override
  void initState() {
    super.initState();
    _loadSavedPassage();
  }

  Future<void> _loadSavedPassage() async {
    try {
      final savedData = await OfflineStorageService.getReadingPassage();
      if (savedData != null) {
        // Restore answers map
        final Map<int, String?> answers = {};
        if (savedData['userAnswers'] != null) {
          (savedData['userAnswers'] as Map).forEach((k, v) {
            answers[int.parse(k.toString())] = v as String?;
          });
        }

        if (mounted) {
          setState(() {
            _content = Map<String, dynamic>.from(savedData['content']);
            _selectedLevel = savedData['level'];
            _userAnswers = answers;
            _showResults = savedData['showResults'];
            _score = savedData['score'];
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      print('Error loading saved passage: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveCurrentState() async {
    if (_content != null) {
      await OfflineStorageService.saveReadingPassage(
        content: _content!,
        level: _selectedLevel,
        userAnswers: _userAnswers,
        showResults: _showResults,
        score: _score,
      );
    }
  }

  Future<void> _generatePassage() async {
    setState(() {
      _isLoading = true;
      _content = null;
      _userAnswers.clear();
      _showResults = false;
      _score = 0;
      _selectedWordIndex = null;
      _currentWordDefinition = null;
    });

    try {
      final result = await GroqService.generateReadingPassage(_selectedLevel);
      
      if (mounted) {
        setState(() {
          _content = result;
          _isLoading = false;
        });
        // Save new passage immediately
        await _saveCurrentState();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e')));
      }
    }
  }
  
  Future<void> _explainWord(String word, int index, String fullSentence) async {
    if (!_isWordModeEnabled) return;

    setState(() {
      _selectedWordIndex = index;
      _currentWordDefinition = "Yükleniyor...";
    });

    try {
      final definition = await GroqService.explainWordInSentence(
          word: word, 
          sentence: _content?['text'] ?? ""
      );

      if (mounted && _selectedWordIndex == index) {
        setState(() {
          _currentWordDefinition = definition;
        });
      }
    } catch (e) {
      if (mounted && _selectedWordIndex == index) {
        setState(() {
          _currentWordDefinition = "Hata oluştu.";
        });
      }
    }
  }

  void _checkAnswers() {
    int correct = 0;
    final questions = _content!['questions'] as List;
    for (int i = 0; i < questions.length; i++) {
        final q = questions[i];
        if (_userAnswers[i] == q['correctAnswer']) {
            correct++;
        }
    }
    setState(() {
        _score = correct;
        _showResults = true;
    });
    _saveCurrentState(); // Save results
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Valid for AutomaticKeepAliveClientMixin
    return Scaffold(
      appBar: AppBar(
        title: const Text('Okuma & Anlama'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: AppTheme.darkGradient,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header Controls
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                color: Colors.black.withOpacity(0.2),
                child: Row(
                  children: [
                    // Level Selector
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedLevel,
                          dropdownColor: AppTheme.darkSurfaceVariant,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          items: _levels.map((l) => DropdownMenuItem(value: l, child: Text(l))).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedLevel = val);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _generatePassage,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryPurple,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: _isLoading 
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Metin Oluştur', style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ),

              if (_content != null) ...[
                  // Interactive Mode Toggle
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                                _isWordModeEnabled ? Icons.touch_app : Icons.touch_app_outlined, 
                                color: _isWordModeEnabled ? AppTheme.accentGreen : Colors.grey
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _isWordModeEnabled ? 'Kelime Modu AÇIK' : 'Kelime Modu KAPALI',
                              style: TextStyle(
                                color: _isWordModeEnabled ? AppTheme.accentGreen : Colors.grey, 
                                fontWeight: FontWeight.bold
                              ),
                            ),
                          ],
                        ),
                        Switch(
                          value: _isWordModeEnabled,
                          activeColor: AppTheme.accentGreen,
                          onChanged: (val) => setState(() {
                             _isWordModeEnabled = val;
                             if (!val) {
                               // Clear selection when turned off
                               _selectedWordIndex = null;
                               _currentWordDefinition = null;
                             }
                          }),
                        ),
                      ],
                    ),
                  ),
              ],

              // Content Area
              Expanded(
                child: _isLoading 
                    ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryPurple))
                    : _content == null 
                        ? Center(
                            child: Text(
                              'Seviye seçip metin oluşturun.',
                              style: TextStyle(color: Colors.white.withOpacity(0.5)),
                            ),
                          )
                        : SingleChildScrollView(
                            controller: _scrollController,
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Title
                                Text(
                                  _content!['title'] ?? '',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                
                                // Interactive Text Paragraph
                                _buildInteractiveParagraph(_content!['text']),
                                
                                const SizedBox(height: 32),
                                const Divider(color: Colors.white24),
                                const SizedBox(height: 16),
                                
                                // Questions
                                const Text(
                                  'Sorular',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.accentOrange,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                ..._buildQuestions(),
                                
                                const SizedBox(height: 24),
                                if (!_showResults)
                                    ElevatedButton(
                                        onPressed: _userAnswers.length == (_content!['questions'] as List).length 
                                            ? _checkAnswers 
                                            : null,
                                        style: ElevatedButton.styleFrom(
                                            backgroundColor: AppTheme.accentGreen,
                                            padding: const EdgeInsets.symmetric(vertical: 16),
                                        ),
                                        child: const Text('Cevapları Kontrol Et', style: TextStyle(color: Colors.white, fontSize: 16)),
                                    ),
                                if (_showResults)
                                    Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                            color: _score == (_content!['questions'] as List).length 
                                                ? AppTheme.accentGreen.withOpacity(0.2)
                                                : Colors.orange.withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(
                                                color: _score == (_content!['questions'] as List).length 
                                                    ? AppTheme.accentGreen 
                                                    : Colors.orange
                                            )
                                        ),
                                        child: Column(
                                            children: [
                                                Text(
                                                    'Sonuç: $_score / ${(_content!['questions'] as List).length}',
                                                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                                                ),
                                                const SizedBox(height: 8),
                                                Text(
                                                    _score == (_content!['questions'] as List).length 
                                                        ? 'Mükemmel! Hepsini bildin.' 
                                                        : 'Tekrar dene veya yeni metin oluştur.',
                                                    style: TextStyle(color: Colors.white.withOpacity(0.8)),
                                                ),
                                            ],
                                        ),
                                    ),
                                const SizedBox(height: 40),
                              ],
                            ),
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInteractiveParagraph(String text) {
      final words = text.split(' ');
      
      // Determine indices to highlight if quote is present
      int startHighlight = -1;
      int endHighlight = -1;
      
      if (_highlightedQuote != null && _highlightedQuote!.isNotEmpty) {
          final normalizedText = text.toLowerCase().replaceAll(RegExp(r'[^\w\s]'), '');
          final normalizedQuote = _highlightedQuote!.toLowerCase().replaceAll(RegExp(r'[^\w\s]'), '');
          
          final startIndex = normalizedText.indexOf(normalizedQuote);
          if (startIndex != -1) {
             // Mapping char index to word index is tricky because we split by space.
             // Simple approximation: match words sequence.
             final quoteWords = _highlightedQuote!.split(' ');
             // Try to find the sequence of words in the main list
             for (int i = 0; i <= words.length - quoteWords.length; i++) {
                 bool match = true;
                 for (int j = 0; j < quoteWords.length; j++) {
                     final w1 = words[i+j].toLowerCase().replaceAll(RegExp(r'[^\w\s]'), '');
                     final w2 = quoteWords[j].toLowerCase().replaceAll(RegExp(r'[^\w\s]'), '');
                     if (w1 != w2 && !w1.contains(w2) && !w2.contains(w1)) { // Fuzzy match
                         match = false;
                         break;
                     }
                 }
                 if (match) {
                     startHighlight = i;
                     endHighlight = i + quoteWords.length - 1;
                     break;
                 }
             }
          }
      }
      
      return Wrap(
          spacing: 4,
          runSpacing: 8,
          children: List.generate(words.length, (index) {
              final word = words[index];
              final cleanWord = word.replaceAll(RegExp(r'[^\w]'), '');
              final isSelected = _selectedWordIndex == index;
              final isHighlighted = index >= startHighlight && index <= endHighlight;

              return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                      // Bubble if selected
                      if (isSelected && _isWordModeEnabled)
                          Container(
                              margin: const EdgeInsets.only(bottom: 4),
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
                              ),
                              child: Text(
                                  _currentWordDefinition ?? '...',
                                  style: const TextStyle(color: Colors.black87, fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                          ),
                      
                      GestureDetector(
                          onTap: () {
                              if (_isWordModeEnabled) {
                                  if (_selectedWordIndex == index) {
                                      // Toggle off if same word tapped
                                      setState(() {
                                          _selectedWordIndex = null;
                                          _currentWordDefinition = null;
                                      });
                                  } else {
                                      _explainWord(cleanWord, index, text);
                                  }
                              }
                          },
                          child: Container(
                              decoration: BoxDecoration(
                                  color: isHighlighted 
                                      ? Colors.yellow.withOpacity(0.5) 
                                      : (isSelected ? AppTheme.primaryPurple.withOpacity(0.3) : Colors.transparent),
                                  borderRadius: BorderRadius.circular(4),
                                  border: isSelected ? Border.all(color: AppTheme.primaryPurple.withOpacity(0.5)) : null,
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
                              child: Text(
                                  word,
                                  style: TextStyle(
                                      color: isHighlighted ? Colors.black : Colors.white.withOpacity(0.9),
                                      fontSize: 17,
                                      height: 1.5,
                                      fontWeight: (_isWordModeEnabled && isSelected) || isHighlighted ? FontWeight.bold : FontWeight.normal,
                                  ),
                              ),
                          ),
                      ),
                  ],
              );
          }),
      );
  }

  final ScrollController _scrollController = ScrollController();

  void _showExplanation(int questionIndex) {
    if (_content == null) return;
    final questions = _content!['questions'] as List;
    final q = questions[questionIndex];
    
    setState(() {
      _highlightedQuote = q['correctAnswerQuote'];
    });
    
    // Scroll to top to see highlighting
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOut,
    );

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.darkSurfaceVariant,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Açıklama',
              style: TextStyle(
                color: AppTheme.accentGreen,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              q['explanation'] ?? 'Açıklama bulunamadı.',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
            if (q['correctAnswerQuote'] != null) ...[
                const SizedBox(height: 16),
                const Text(
                'Metindeki Yeri:',
                style: TextStyle(
                    color: Colors.yellow,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                ),
                ),
                const SizedBox(height: 8),
                Text(
                '"${q['correctAnswerQuote']}"',
                style: const TextStyle(
                    color: Colors.white70,
                    fontStyle: FontStyle.italic,
                ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  List<Widget> _buildQuestions() {
      final questions = _content!['questions'] as List;
      return List.generate(questions.length, (index) {
          final q = questions[index];
          final options = q['options'] as List;
          final correctAnswer = q['correctAnswer'];
          final userAnswer = _userAnswers[index];
          
          return Container(
              margin: const EdgeInsets.only(bottom: 24),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                      Row(
                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
                         children: [
                             Expanded(
                                child: Text(
                                    '${index + 1}. ${q['question']}',
                                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                                ),
                             ),
                             if (_showResults)
                                 TextButton.icon(
                                    onPressed: () => _showExplanation(index),
                                    icon: const Icon(Icons.info_outline, size: 16, color: AppTheme.accentBlue),
                                    label: const Text('Açıklama', style: TextStyle(color: AppTheme.accentBlue)),
                                 ),
                         ],
                      ),
                      const SizedBox(height: 12),
                      ...options.map((opt) {
                          final isSelected = userAnswer == opt;
                          final isCorrect = opt == correctAnswer;
                          Color color = Colors.white.withOpacity(0.1);
                          IconData? icon;
                          
                          if (_showResults) {
                              if (isCorrect) {
                                  color = AppTheme.accentGreen.withOpacity(0.2); // Corect Answer Highlight ALWAYS
                                  icon = Icons.check_circle;
                              } else if (isSelected && !isCorrect) {
                                  color = Colors.red.withOpacity(0.2); // Wrong selection
                                  icon = Icons.cancel;
                              }
                          } else if (isSelected) {
                              color = AppTheme.primaryPurple.withOpacity(0.2);
                          }

                          return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: InkWell(
                                  onTap: _showResults ? null : () {
                                      setState(() {
                                          _userAnswers[index] = opt;
                                      });
                                  },
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                          color: color,
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(
                                              color: _showResults && isCorrect 
                                                  ? AppTheme.accentGreen 
                                                  : (isSelected && !_showResults ? AppTheme.primaryPurple : Colors.transparent)
                                          ),
                                      ),
                                      child: Row(
                                          children: [
                                              Container(
                                                  width: 24, height: 24,
                                                  decoration: BoxDecoration(
                                                      shape: BoxShape.circle,
                                                      border: Border.all(
                                                          color: _showResults && isCorrect ? AppTheme.accentGreen : Colors.white54
                                                      ),
                                                      color: isSelected && !_showResults ? AppTheme.primaryPurple : Colors.transparent,
                                                  ),
                                                  child: isSelected && !_showResults ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(child: Text(opt, style: const TextStyle(color: Colors.white))),
                                              if (icon != null) ...[
                                                  const SizedBox(width: 8),
                                                  Icon(icon, color: icon == Icons.check_circle ? AppTheme.accentGreen : Colors.red, size: 20),
                                              ]
                                          ],
                                      ),
                                  ),
                              ),
                          );
                      }),
                  ],
              ),
          );
      });
  }
}
