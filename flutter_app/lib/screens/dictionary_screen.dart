import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/groq_service.dart';
import '../theme/app_theme.dart';
import '../providers/word_provider.dart';

class DictionaryScreen extends StatefulWidget {
  const DictionaryScreen({super.key});

  @override
  State<DictionaryScreen> createState() => _DictionaryScreenState();
}

class _DictionaryScreenState extends State<DictionaryScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode(); // Klavye kontrolü için
  bool _isLoading = false;
  Map<String, dynamic>? _result;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Ekran açılınca klavyeyi aç
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _searchWord() async {
    final word = _searchController.text.trim();
    if (word.isEmpty) return;

    setState(() {
      _isLoading = true;
      _error = null;
      _result = null;
    });

    // Klavyeyi kapat
    _focusNode.unfocus();

    try {
      final result = await GroqService.lookupWord(word);
      setState(() {
        _result = result;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().contains('GROQ_API_KEY') 
            ? 'API Anahtarı eksik. Lütfen ayarlardan ekleyin.'
            : 'Bir hata oluştu. Lütfen tekrar deneyin.';
        _isLoading = false;
      });
    }
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _result = null;
      _error = null;
    });
    // Temizleyince tekrar odaklan
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hızlı Sözlük'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        height: double.infinity, // Tüm ekranı kapla
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
              // Arama Çubuğu
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                  ),
                  child: TextField(
                    controller: _searchController,
                    focusNode: _focusNode,
                    style: const TextStyle(color: Colors.white, fontSize: 18),
                    decoration: InputDecoration(
                      hintText: 'Kelime yazın (örn: apple)',
                      hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                      prefixIcon: const Icon(Icons.search, color: AppTheme.primaryPurple),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, color: Colors.grey),
                              onPressed: _clearSearch,
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    ),
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => _searchWord(),
                    onChanged: (val) {
                      // Yazarken çarpı ikonunu güncellemek için setState
                      setState(() {});
                    },
                  ),
                ),
              ),

              // İçerik Alanı
              Expanded(
                child: SingleChildScrollView( // Scroll eklendi
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      if (_isLoading)
                        const Center(child: CircularProgressIndicator(color: AppTheme.primaryPurple))
                      else if (_error != null)
                        _buildErrorCard()
                      else if (_result != null)
                        _buildResultCard()
                      else
                        _buildEmptyState(),
                        
                      // Klavye açıldığında altta boşluk bırakmak için
                      SizedBox(height: MediaQuery.of(context).viewInsets.bottom + 20),
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          Icon(Icons.translate, size: 80, color: Colors.white.withOpacity(0.1)),
          const SizedBox(height: 16),
          Text(
            'Çeviri için kelime arayın',
            style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _error!,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // State for interactive practice
  String? _selectedContext;
  String? _selectedTranslation;
  String? _generatedPracticeSentence;
  bool _isGeneratingSentence = false;

  Widget _buildResultCard() {
    final word = _result!['word'] as String;
    final type = _result!['type'] as String? ?? 'unk';
    final meanings = List<Map<String, dynamic>>.from(_result!['meanings'] ?? []);

    return Column(
      children: [
        // Main Dictionary Card
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppTheme.darkSurfaceVariant,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppTheme.primaryPurple.withOpacity(0.1),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      word,
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryPurple,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            type,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: () {
                            // İlk anlamı varsayılan olarak al
                            final meanings = List<Map<String, dynamic>>.from(_result!['meanings'] ?? []);
                            final firstMeaning = meanings.isNotEmpty ? meanings.first['translation'] : '';
                            _showAddWordDialog(english: word, turkish: firstMeaning);
                          },
                          icon: const Icon(Icons.bookmark_add, color: Colors.white),
                          tooltip: 'Kelimelerime Ekle',
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Meanings List
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ANLAMLAR VE ÖRNEKLER',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...meanings.map((m) {
                        final translation = m['translation'] ?? '';
                        final context = m['context'] ?? '';
                        final example = m['example'] ?? '';
                        
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Padding(
                                    padding: EdgeInsets.only(top: 6),
                                    child: Icon(Icons.circle, size: 8, color: AppTheme.accentGreen),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: RichText(
                                      text: TextSpan(
                                        children: [
                                          TextSpan(
                                            text: translation,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          if (context.isNotEmpty)
                                            TextSpan(
                                              text: '  ($context)',
                                              style: TextStyle(
                                                color: Colors.white.withOpacity(0.6),
                                                fontSize: 14,
                                                fontStyle: FontStyle.italic,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.all(12),
                                margin: const EdgeInsets.only(left: 20),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.white.withOpacity(0.05)),
                                ),
                                child: Text(
                                  example,
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: 14,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                    }),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Interactive Practice Section
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppTheme.darkSurfaceVariant,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.primaryPurple.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.psychology, color: AppTheme.primaryPurple),
                  const SizedBox(width: 12),
                  const Text(
                    'Özel Pratik Yap',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Hangi anlamda cümle kurmak istersiniz?',
                style: TextStyle(color: Colors.white.withOpacity(0.7)),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: meanings.map((m) {
                  final translation = m['translation'] as String;
                  final context = m['context'] as String;
                  final label = context.isNotEmpty ? '$translation ($context)' : translation;
                  final isSelected = _selectedContext == context && _selectedTranslation == translation;

                  return ChoiceChip(
                    label: Text(label),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedContext = context;
                          _selectedTranslation = translation;
                          _generatedPracticeSentence = null;
                        } else {
                          _selectedContext = null;
                          _selectedTranslation = null;
                        }
                      });
                    },
                    selectedColor: AppTheme.primaryPurple,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.white70,
                    ),
                    backgroundColor: Colors.white.withOpacity(0.1),
                  );
                }).toList(),
              ),

              const SizedBox(height: 20),

              if (_selectedTranslation != null) ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isGeneratingSentence ? null : () async {
                      setState(() {
                        _isGeneratingSentence = true;
                        _generatedPracticeSentence = null;
                      });
                      
                      final sentence = await GroqService.generateSpecificSentence(
                        word: word,
                        translation: _selectedTranslation!,
                        context: _selectedContext!,
                      );

                      setState(() {
                        _generatedPracticeSentence = sentence;
                        _isGeneratingSentence = false;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryPurple,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isGeneratingSentence
                      ? const SizedBox(
                          height: 20, 
                          width: 20, 
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                        )
                      : const Text('Bu Anlamda Cümle Oluştur', style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],

              if (_generatedPracticeSentence != null) ...[
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.accentGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.accentGreen.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'OLUŞTURULAN CÜMLE:',
                            style: TextStyle(
                              color: AppTheme.accentGreen,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.refresh, color: AppTheme.accentGreen, size: 20),
                            tooltip: 'Yeni Cümle',
                            constraints: const BoxConstraints(),
                            padding: EdgeInsets.zero,
                            onPressed: _isGeneratingSentence ? null : () async {
                              setState(() {
                                _isGeneratingSentence = true;
                                _generatedPracticeSentence = null;
                                _wordExplanation = null; // Reset explanation
                              });
                              
                              final sentence = await GroqService.generateSpecificSentence(
                                word: word,
                                translation: _selectedTranslation!,
                                context: _selectedContext!,
                              );

                              setState(() {
                                _generatedPracticeSentence = sentence;
                                _isGeneratingSentence = false;
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _buildInteractiveSentence(_generatedPracticeSentence!),
                    ],
                  ),
                ),
                if (_wordExplanation != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Stack(
                      alignment: Alignment.topCenter,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(top: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.lightbulb, color: Colors.orange, size: 20),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  _wordExplanation!,
                                  style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Arrow for bubble effect
                        Positioned(
                          top: 0,
                          child: Transform.translate(
                            offset: const Offset(0, 1),
                            child: const Icon(Icons.arrow_drop_up, color: Colors.white, size: 24),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // Helper handling for interactive words
  String? _wordExplanation;
  
  Widget _buildInteractiveSentence(String sentence) {
    // Remove punctuation for cleaner splitting but keep it for display if possible.
    // Simple split by space
    final words = sentence.split(' ');
    
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: words.map((w) {
         // Clean word for search API (remove commas, dots)
         final cleanWord = w.replaceAll(RegExp(r'[^\w\s]'), '');
         
         return Material(
           color: Colors.transparent,
           child: InkWell(
             borderRadius: BorderRadius.circular(4),
             onTapDown: (details) async {
               final position = RelativeRect.fromLTRB(
                 details.globalPosition.dx,
                 details.globalPosition.dy,
                 details.globalPosition.dx,
                 details.globalPosition.dy,
               );
               
               final result = await showMenu<String>(
                 context: context,
                 position: position,
                 color: AppTheme.darkSurfaceVariant,
                 items: [
                   PopupMenuItem(
                     value: 'search',
                     child: Row(
                       children: [
                         const Icon(Icons.search, color: Colors.white, size: 18),
                         const SizedBox(width: 8),
                         const Text('Kelimeyi Arat', style: TextStyle(color: Colors.white)),
                       ],
                     ),
                   ),
                   PopupMenuItem(
                     value: 'meaning',
                     child: Row(
                       children: [
                         const Icon(Icons.help_outline, color: AppTheme.accentBlue, size: 18),
                         const SizedBox(width: 8),
                         const Text('Anlamına Bak', style: TextStyle(color: Colors.white)),
                       ],
                     ),
                   ),
                   PopupMenuItem(
                     value: 'add',
                     child: Row(
                       children: [
                         const Icon(Icons.bookmark_add, color: AppTheme.accentGreen, size: 18),
                         const SizedBox(width: 8),
                         const Text('Kelimelerime Ekle', style: TextStyle(color: Colors.white)),
                       ],
                     ),
                   ),
                 ],
               );
               
               if (result == 'search') {
                 _searchController.text = cleanWord;
                 _searchWord();
               } else if (result == 'meaning') {
                 setState(() => _wordExplanation = 'Yükleniyor...');
                 final expl = await GroqService.explainWordInSentence(
                   word: cleanWord, 
                   sentence: sentence
                 );
                 setState(() => _wordExplanation = '$cleanWord: $expl');
               } else if (result == 'add') {
                 _showAddWordDialog(english: cleanWord);
               }
             },
             child: Padding(
               padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
               child: Text(
                 w,
                 style: const TextStyle(
                   color: Colors.white,
                   fontSize: 16,
                   fontWeight: FontWeight.w500,
                   decoration: TextDecoration.underline,
                   decorationStyle: TextDecorationStyle.dotted,
                   decorationColor: Colors.white30,
                 ),
               ),
             ),
           ),
         );
      }).toList(),
    );
  }

  void _showAddWordDialog({required String english, String? turkish}) {
    final turkishController = TextEditingController(text: turkish);
    String difficulty = 'easy';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: AppTheme.darkSurface,
          title: const Text('Kelimelerime Ekle', style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                english,
                style: const TextStyle(
                  color: AppTheme.primaryPurple,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: turkishController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Türkçe Anlamı',
                  labelStyle: TextStyle(color: Colors.white70),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white30)),
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppTheme.primaryPurple)),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: difficulty,
                dropdownColor: AppTheme.darkSurfaceVariant,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Zorluk',
                  labelStyle: TextStyle(color: Colors.white70),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white30)),
                ),
                items: const [
                  DropdownMenuItem(value: 'easy', child: Text('Kolay')),
                  DropdownMenuItem(value: 'medium', child: Text('Orta')),
                  DropdownMenuItem(value: 'difficult', child: Text('Zor')),
                ],
                onChanged: (val) => setState(() => difficulty = val!),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () {
                if (turkishController.text.isNotEmpty) {
                  Provider.of<WordProvider>(context, listen: false).addWord(
                    english: english,
                    turkish: turkishController.text,
                    difficulty: difficulty,
                    addedDate: DateTime.now(),
                  );
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Kelime başarıyla eklendi!'),
                      backgroundColor: AppTheme.accentGreen,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryPurple),
              child: const Text('Kaydet', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
