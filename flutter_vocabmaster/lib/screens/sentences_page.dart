import 'package:flutter/material.dart';
import 'dart:ui';
import '../widgets/animated_background.dart';
import '../models/word.dart';
import '../services/api_service.dart';

class SentencesPage extends StatefulWidget {
  const SentencesPage({Key? key}) : super(key: key);

  @override
  State<SentencesPage> createState() => _SentencesPageState();
}

class _SentencesPageState extends State<SentencesPage> {
  final ApiService _apiService = ApiService();
  List<Word> allWords = [];
  List<Sentence> allSentences = [];
  List<Sentence> filteredSentences = [];
  bool isLoading = true;
  String _activeFilter = 'Tümü'; // Tümü, Kolay, Orta, Zor
  final TextEditingController _searchController = TextEditingController();

  // Mapping sentence to its word for display meta-data
  final Map<int, Word> _sentenceToWordMap = {};

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchController.addListener(_filterSentences);
  }

  Future<void> _loadData() async {
    try {
      final words = await _apiService.getAllWords();
      final List<Sentence> sentences = [];
      for (var word in words) {
        for (var s in word.sentences) {
          sentences.add(s);
          // Assuming Sentence has an ID, or we use object identity if unique.
          // Since existing Sentence model might not have unique ID across all, rely on object.
          _sentenceToWordMap[s.hashCode] = word;
        }
      }
      setState(() {
        allWords = words;
        allSentences = sentences;
        filteredSentences = sentences;
        isLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _filterSentences() {
    final query = _searchController.text.toLowerCase();
    
    setState(() {
      filteredSentences = allSentences.where((s) {
        final word = _sentenceToWordMap[s.hashCode];
        final matchesQuery = s.sentence.toLowerCase().contains(query) || 
                             s.translation.toLowerCase().contains(query);
                             
        final matchesFilter = _activeFilter == 'Tümü' || 
                              (word != null && _mapDifficulty(word.difficulty) == _activeFilter);
        
        return matchesQuery && matchesFilter;
      }).toList();
    });
  }
  
  String _mapDifficulty(String diff) {
    if (diff == 'easy') return 'Kolay';
    if (diff == 'medium') return 'Orta';
    if (diff == 'hard') return 'Zor';
    return 'Orta';
  }

  void _setActiveFilter(String filter) {
    setState(() => _activeFilter = filter);
    _filterSentences();
  }

  @override
  Widget build(BuildContext context) {
    // Calculate stats
    int total = allSentences.length;
    int easy = allSentences.where((s) {
      final w = _sentenceToWordMap[s.hashCode];
      return w != null && w.difficulty == 'easy';
    }).length;
    int medium = allSentences.where((s) {
      final w = _sentenceToWordMap[s.hashCode];
      return w != null && w.difficulty == 'medium';
    }).length;
    int hard = allSentences.where((s) {
      final w = _sentenceToWordMap[s.hashCode];
      return w != null && w.difficulty == 'hard';
    }).length;

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddNewSentenceDialog(),
        backgroundColor: const Color(0xFF06b6d4),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Stack(
        children: [
          const AnimatedBackground(isDark: true),
          SafeArea(
            child: Column(
              children: [
                // Top Stats
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem('Toplam', total.toString(), Colors.redAccent),
                      _buildStatItem('Kolay', easy.toString(), Colors.greenAccent),
                      _buildStatItem('Orta', medium.toString(), Colors.amberAccent),
                      _buildStatItem('Zor', hard.toString(), Colors.red),
                    ],
                  ),
                ),
                
                // Search Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(color: Colors.black87),
                      decoration: const InputDecoration(
                        icon: Icon(Icons.search, color: Colors.grey),
                        hintText: 'Cümlelerde ara...',
                        hintStyle: TextStyle(color: Colors.grey),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      _buildFilterChip('Tümü'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Kolay'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Orta'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Zor'),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // List
                Expanded(
                  child: isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: filteredSentences.length,
                          itemBuilder: (context, index) {
                            final sentence = filteredSentences[index];
                            final word = _sentenceToWordMap[sentence.hashCode];
                            return SentenceCard(
                              sentence: sentence,
                              word: word,
                              mapDifficulty: _mapDifficulty,
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ... (Keep _buildStatItem and others same, delete _buildSentenceCard)
  
  Widget _buildStatItem(String label, String value, Color color) {
    return Container(
      width: 80,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1e3a8a).withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _activeFilter == label;
    return GestureDetector(
      onTap: () => _setActiveFilter(label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.cyan : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.cyan.withOpacity(0.5)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white70,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String hint) {
    return TextField(
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
      ),
    );
  }

  Widget _buildDifficultyDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: 'Kolay',
          isExpanded: true,
          dropdownColor: const Color(0xFF1e1b4b),
          style: const TextStyle(color: Colors.white),
          items: ['Kolay', 'Orta', 'Zor'].map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
          onChanged: (_) {},
        ),
      ),
    );
  }
  void _showAddNewSentenceDialog() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      pageBuilder: (context, anim1, anim2) => Container(),
      transitionBuilder: (context, anim1, anim2, child) {
        return FadeTransition(
          opacity: anim1,
          child: ScaleTransition(
            scale: anim1,
            child: Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(horizontal: 20),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    width: MediaQuery.of(context).size.width,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0f172a).withOpacity(0.7),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: const Color(0xFF06b6d4).withOpacity(0.5), 
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF06b6d4).withOpacity(0.15),
                          blurRadius: 20,
                        ),
                      ],
                    ),
                    child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Yeni Cümle Ekle',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Kelime seçerek veya seçmeden cümle\nekleyebilirsiniz',
                                style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.white54),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      
                      // Kelime Seçimi
                      const Text(
                        'Kelime Seçimi (Opsiyonel)',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: _buildTextField('İngilizce kelime')),
                          const SizedBox(width: 12),
                          Expanded(child: _buildTextField('Türkçe anlamı')),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Checkbox section
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white.withOpacity(0.1)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: Colors.white24),
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Bugünün Kelimelerine Ekle',
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  'Önce kelime ve anlamını girin',
                                  style: TextStyle(color: Colors.white38, fontSize: 11),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      const Text('İngilizce Cümle', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      _buildTextField('İngilizce cümle yazın...'),
                      
                      const SizedBox(height: 16),
                      const Text('Türkçe Anlamı', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      _buildTextField('Türkçe anlamı yazın...'),
                      
                      const SizedBox(height: 16),
                      const Text('Zorluk Seviyesi', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      _buildDifficultyDropdown(),
                      
                      const SizedBox(height: 40),
                      Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('İptal', style: TextStyle(color: Colors.white70)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Container(
                              height: 50,
                              decoration: BoxDecoration(
                                color: const Color(0xFF06b6d4),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ElevatedButton.icon(
                                onPressed: () => Navigator.pop(context),
                                icon: const Icon(Icons.add, color: Colors.white, size: 18),
                                label: const Text(
                                  'Cümle Ekle',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  },
    );
  }
}

class SentenceCard extends StatefulWidget {
  final Sentence sentence;
  final Word? word;
  final String Function(String) mapDifficulty;

  const SentenceCard({
    Key? key,
    required this.sentence,
    required this.word,
    required this.mapDifficulty,
  }) : super(key: key);

  @override
  State<SentenceCard> createState() => _SentenceCardState();
}

class _SentenceCardState extends State<SentenceCard> {
  bool _isMeaningVisible = false;

  @override
  Widget build(BuildContext context) {
    final wordText = widget.word?.englishWord ?? '';
    final difficulty = widget.word != null ? widget.mapDifficulty(widget.word!.difficulty) : 'Orta';
    
    final sentenceText = widget.sentence.sentence;
    final lowerSentence = sentenceText.toLowerCase();
    final lowerWord = wordText.toLowerCase();
    final index = lowerSentence.indexOf(lowerWord);
    
    List<InlineSpan> spans = [];
    if (index != -1 && wordText.isNotEmpty) {
      // Before the word
      spans.add(TextSpan(
        text: sentenceText.substring(0, index),
        style: const TextStyle(color: Colors.white, fontSize: 18, height: 1.5),
      ));
      
      // The highlighted word (WidgetSpan for badge effect)
      spans.add(WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF0ea5e9).withOpacity(0.3), // Blue/Cyan highlight
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF0ea5e9).withOpacity(0.5)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0ea5e9).withOpacity(0.2),
                blurRadius: 8,
              ),
            ],
          ),
          child: Text(
            sentenceText.substring(index, index + wordText.length), // Case sensitive original text
            style: const TextStyle(
              color: Colors.cyanAccent, 
              fontSize: 18, 
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ));
      
      // After the word
      spans.add(TextSpan(
        text: sentenceText.substring(index + wordText.length),
        style: const TextStyle(color: Colors.white, fontSize: 18, height: 1.5),
      ));
    } else {
      spans.add(TextSpan(
        text: sentenceText,
        style: const TextStyle(color: Colors.white, fontSize: 18, height: 1.5),
      ));
    }

    // Determine badge color based on difficulty
    Color badgeColor;
    Color badgeBgColor;
    
    switch (difficulty) {
      case 'Kolay':
        badgeColor = Colors.greenAccent;
        badgeBgColor = Colors.green.withOpacity(0.2);
        break;
      case 'Zor':
        badgeColor = Colors.redAccent;
        badgeBgColor = Colors.red.withOpacity(0.2);
        break;
      default:
        badgeColor = Colors.amberAccent;
        badgeBgColor = Colors.amber.withOpacity(0.2);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF06b6d4).withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF0f172a).withOpacity(0.6),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: const Color(0xFF06b6d4).withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: Label & Delete
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                     Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: badgeBgColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: badgeColor.withOpacity(0.3)),
                      ),
                      child: Text(
                        difficulty.toUpperCase(),
                        style: TextStyle(
                          color: badgeColor, 
                          fontSize: 11, 
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.white54, size: 20),
                      onPressed: () {
                        // Silme fonksiyonu eklenebilir
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                
                // Sentence Text with Highlight
                RichText(
                  text: TextSpan(children: spans),
                ),
                
                const SizedBox(height: 8),
                if(widget.word != null)
                   Text(
                      widget.word!.turkishMeaning, 
                       style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14),
                   ),
      
                const SizedBox(height: 20),
                
                // Shows translation box OR placeholder
                AnimatedCrossFade(
                  firstChild: Container(), 
                  secondChild: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1e3a8a).withOpacity(0.3),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF38bdf8).withOpacity(0.3)),
                      boxShadow: [
                         BoxShadow(
                           color: const Color(0xFF38bdf8).withOpacity(0.1),
                           blurRadius: 12,
                         )
                      ],
                    ),
                    child: Text(
                      widget.sentence.translation,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  crossFadeState: _isMeaningVisible ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                  duration: const Duration(milliseconds: 300),
                ),
                
                const SizedBox(height: 12),
                
                // Toggle Button
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _isMeaningVisible = !_isMeaningVisible;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    color: Colors.transparent, // Hit test için
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _isMeaningVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          color: const Color(0xFF22d3ee),
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _isMeaningVisible ? "Anlamı Gizle" : "Anlamı Göster",
                          style: const TextStyle(
                            color: Color(0xFF22d3ee), 
                            fontWeight: FontWeight.bold,
                            fontSize: 14
                          ),
                        ),
                      ],
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
}
