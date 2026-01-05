import 'package:flutter/material.dart';
import 'dart:ui';
import '../widgets/animated_background.dart';
import '../models/word.dart';
import '../services/api_service.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../widgets/info_dialog.dart';
import '../services/global_state.dart';

class WordsPage extends StatefulWidget {
  const WordsPage({Key? key}) : super(key: key);

  @override
  State<WordsPage> createState() => _WordsPageState();
}

class _WordsPageState extends State<WordsPage> {
  final ApiService _apiService = ApiService();
  final FlutterTts _flutterTts = FlutterTts();
  DateTime _selectedDate = DateTime.now();
  List<Word> _wordsForSelectedDate = [];
  Set<String> _datesWithWords = {}; // Dates that have words (YYYY-MM-DD format)
  bool _isLoading = false;

  final List<String> _weekDays = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];

  @override
  void initState() {
    super.initState();
    _loadDatesWithWords();
    _loadWordsForDate(_selectedDate);
  }

  Future<void> _loadDatesWithWords() async {
    try {
      final dates = await _apiService.getAllDistinctDates();
      setState(() {
        _datesWithWords = dates.toSet();
      });
    } catch (e) {
      print('Error loading dates: $e');
    }
  }

  Future<void> _loadWordsForDate(DateTime date) async {
    setState(() => _isLoading = true);
    try {
      final words = await _apiService.getWordsByDate(date);
      setState(() {
        _wordsForSelectedDate = words;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading words: $e');
      setState(() => _isLoading = false);
    }
  }

  void _onDaySelected(int day) {
    if (day < 1) return;
    // Use the currently displayed month/year from _selectedDate
    final newDate = DateTime(_selectedDate.year, _selectedDate.month, day);
    
    setState(() => _selectedDate = newDate);
    _loadWordsForDate(newDate);
  }

  Future<void> _speak(String text, String languageCode) async {
    await _flutterTts.setLanguage(languageCode);
    await _flutterTts.setPitch(1.0);
    await _flutterTts.speak(text);
  }

  void _changeMonth(int delta) {
    setState(() {
      _selectedDate = DateTime(_selectedDate.year, _selectedDate.month + delta, 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const AnimatedBackground(isDark: true),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                   // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Kelime Takviminiz',
                         style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          InfoDialog.show(
                            context,
                            title: 'Kelimeler Sayfası',
                            steps: [
                              'Takvimden bir gün seçerek o günün kelimelerini görüntüleyin.',
                              'Mor renkli günler kelime içeren günlerdir.',
                              'Boş bir gün seçerek yeni kelime ekleyebilirsiniz.',
                              'Her kelime kolay, orta veya zor olarak işaretlenebilir.',
                              'Öğrendiğiniz kelimeleri takip ederek ilerlemenizi görün.',
                            ],
                          );
                        },
                        icon: Icon(Icons.info_outline, color: Colors.white.withOpacity(0.7)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Calendar Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1e3a8a).withOpacity(0.5),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                    ),
                    child: Column(
                      children: [
                        // Month Header
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              IconButton(
                                icon: Icon(Icons.chevron_left, color: Colors.white.withOpacity(0.7)),
                                onPressed: () => _changeMonth(-1),
                              ),
                              Text(
                                '${_getMonthName(_selectedDate.month)} ${_selectedDate.year}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              IconButton(
                                icon: Icon(Icons.chevron_right, color: Colors.white.withOpacity(0.7)),
                                onPressed: () => _changeMonth(1),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Days Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: _weekDays.map((day) => Text(
                            day,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.6),
                              fontSize: 14,
                            ),
                          )).toList(),
                        ),
                        const SizedBox(height: 16),
                        
                        // Days Grid
                        // A simple grid for specific month structure (e.g. Jan 2026 starts on Thursday)
                        // For dynamic: calculate start offset.
                        _buildCalendarGrid(),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Learned Words List Header
                  Text(
                    '${_selectedDate.day} ${_getMonthName(_selectedDate.month)} - Öğrenilen Kelimeler',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // List
                  if (_isLoading)
                    const Center(child: CircularProgressIndicator())
                  else if (_wordsForSelectedDate.isEmpty)
                     Container(
                       padding: const EdgeInsets.all(32),
                       decoration: BoxDecoration(
                         color: const Color(0xFF1e3a8a).withOpacity(0.3),
                         borderRadius: BorderRadius.circular(24),
                         border: Border.all(color: Colors.white.withOpacity(0.1)),
                       ),
                       child: Column(
                         children: [
                           Container(
                             padding: const EdgeInsets.all(16),
                             decoration: BoxDecoration(
                               color: Colors.blue.withOpacity(0.2),
                               borderRadius: BorderRadius.circular(16),
                             ),
                             child: const Icon(Icons.calendar_today, color: Colors.blue, size: 32),
                           ),
                           const SizedBox(height: 16),
                           const Text(
                             'Bir gün seçin',
                             style: TextStyle(
                               color: Colors.white,
                               fontSize: 18,
                               fontWeight: FontWeight.bold,
                             ),
                           ),
                           const SizedBox(height: 8),
                           Text(
                             'Takvimden bir gün seçerek o günün kelimelerini görün veya yeni kelime ekleyin',
                             textAlign: TextAlign.center,
                             style: TextStyle(
                               color: Colors.white.withOpacity(0.6),
                               fontSize: 14,
                             ),
                           ),
                         ],
                       ),
                     )
                  else
                    Column(
                      children: _wordsForSelectedDate.map((word) => _buildWordCard(word)).toList(),
                    ),
                    
                   const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildCalendarGrid() {
    final daysInMonth = DateUtils.getDaysInMonth(_selectedDate.year, _selectedDate.month);
    final firstDayOfMonth = DateTime(_selectedDate.year, _selectedDate.month, 1);
    final weekdayOffset = firstDayOfMonth.weekday - 1; // 0 for Mon
    
    // Total cells = offset + days. 
    final totalCells = 35; // Fixed 5 rows for aesthetics or 42 for 6 rows
    
    List<Widget> dayWidgets = [];
    
    // Empty slots
    for (int i = 0; i < weekdayOffset; i++) {
      dayWidgets.add(const SizedBox());
    }
    
    for (int i = 1; i <= daysInMonth; i++) {
      final isSelected = i == _selectedDate.day && 
                         _selectedDate.month == DateTime.now().month && 
                         _selectedDate.year == DateTime.now().year;
      
      // Check if this date has words learned
      final dateStr = DateTime(_selectedDate.year, _selectedDate.month, i)
          .toIso8601String()
          .split('T')[0];
      final hasWords = _datesWithWords.contains(dateStr);
      
      dayWidgets.add(
        GestureDetector(
          onTap: () => _onDaySelected(i),
          child: Container(
            margin: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isSelected 
                  ? const Color(0xFF06b6d4) // Cyan for selected
                  : (hasWords ? const Color(0xFF3b82f6).withOpacity(0.6) : Colors.white.withOpacity(0.1)),
              shape: BoxShape.rectangle,
              borderRadius: BorderRadius.circular(12),
              border: isSelected ? Border.all(color: const Color(0xFF06b6d4), width: 2) : null,
            ),
            child: Center(
              child: Text(
                '$i',
                style: TextStyle(
                  color: Colors.white.withOpacity(isSelected || hasWords ? 1.0 : 0.6),
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ),
        ),
      );
    }
    
    // Fill remaining
    while (dayWidgets.length < 35) {
      dayWidgets.add(const SizedBox());
    }
    
    return GridView.count(
      shrinkWrap: true,
      crossAxisCount: 7,
      physics: const NeverScrollableScrollPhysics(),
      children: dayWidgets,
    );
  }

  Widget _buildWordCard(Word word) {
    Color difficultyColor = Colors.amber;
    String difficultyText = 'Orta';
    if (word.difficulty == 'easy') {
      difficultyColor = Colors.green;
      difficultyText = 'Kolay';
    } else if (word.difficulty == 'hard') {
      difficultyColor = Colors.red;
      difficultyText = 'Zor';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1e3a8a).withOpacity(0.35),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.15)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            Positioned(
              top: 0,
              left: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: difficultyColor,
                  borderRadius: const BorderRadius.only(
                    bottomRight: Radius.circular(16),
                  ),
                ),
                child: Text(
                  difficultyText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 32, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          word.englishWord,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Wrap buttons in a Row to keep them together
                      Row(
                        children: [
                          _buildSmallSpeakButton('US', () => _speak(word.englishWord, 'en-US')),
                          const SizedBox(width: 8),
                          _buildSmallSpeakButton('UK', () => _speak(word.englishWord, 'en-GB')),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    word.turkishMeaning,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: _buildActionButton(
                          icon: Icons.description_outlined,
                          label: 'Cümleler',
                          onTap: () => _showSentencesDialog(word),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildActionButton(
                          icon: Icons.add,
                          label: 'Cümle Ekle',
                          onTap: () => _showAddSentenceDialog(word),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSmallSpeakButton(String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF06b6d4).withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF06b6d4).withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.volume_up, size: 14, color: Color(0xFF06b6d4)),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF06b6d4),
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18, color: const Color(0xFF06b6d4)),
      label: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF06b6d4),
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF06b6d4),
        padding: const EdgeInsets.symmetric(vertical: 12),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFF06b6d4), width: 1),
        ),
      ),
    );
  }

  void _showAddSentenceDialog(Word word) {
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
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Cümle Ekle',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${word.englishWord} kelimesi için cümleler',
                                style: const TextStyle(
                                  color: Color(0xFF06b6d4),
                                  fontSize: 13,
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
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white.withOpacity(0.1)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '1. Cümle',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _buildTextField('İngilizce cümle'),
                            const SizedBox(height: 12),
                            _buildTextField('Türkçe anlamı'),
                            const SizedBox(height: 12),
                            _buildDifficultyDropdown(),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        height: 50,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2),
                            style: BorderStyle.solid,
                          ),
                        ),
                        child: TextButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.add, color: Colors.white70),
                          label: const Text(
                            'Yeni Cümle Ekle',
                            style: TextStyle(color: Colors.white70),
                          ),
                        ),
                      ),
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
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF00c6ff), Color(0xFF0072ff)],
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ElevatedButton(
                                onPressed: () => Navigator.pop(context),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text(
                                  'Kaydet',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
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

  Widget _buildTextField(String hint) {
    return TextField(
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white38),
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

  String _getMonthName(int month) {
    const months = [
      '', 'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
      'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'
    ];
    if (month < 1 || month > 12) return '';
    return months[month];
  }

  void _showSentencesDialog(Word word) {
    Set<int> visibleTranslations = {};
    
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return ValueListenableBuilder<bool>(
              valueListenable: GlobalState.isMatching,
              builder: (context, isMatching, _) {
                final double dialogHeight = MediaQuery.of(context).size.height * (isMatching ? 0.6 : 0.8);
                
                return Center(
                  child: Material(
                    type: MaterialType.transparency,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          width: MediaQuery.of(context).size.width * 0.9,
                          height: dialogHeight,
                          decoration: BoxDecoration(
                            color: const Color(0xFF0f172a).withOpacity(0.7),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: const Color(0xFF38bdf8).withOpacity(0.5),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF38bdf8).withOpacity(0.15),
                                blurRadius: 20,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: Column(
                        children: [
                          // Header
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.03), // Subtle header bg
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                              border: Border(
                                bottom: BorderSide(
                                  color: const Color(0xFF38bdf8).withOpacity(0.2),
                                ),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.menu_book, color: Colors.white, size: 24),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Örnek Cümleler (${word.sentences.length})',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          const Icon(Icons.auto_awesome, color: Color(0xFF06b6d4), size: 12),
                                          const SizedBox(width: 4),
                                          Text(
                                            word.englishWord,
                                            style: const TextStyle(
                                              color: Color(0xFF06b6d4),
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close, color: Colors.white54),
                                  onPressed: () => Navigator.pop(context),
                                ),
                              ],
                            ),
                          ),
                          
                          // Content
                          Expanded(
                            child: word.sentences.isEmpty
                            ? Center(
                                child: Text(
                                  'Henüz örnek cümle yok.',
                                  style: TextStyle(color: Colors.white.withOpacity(0.5)),
                                ),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: word.sentences.length,
                                itemBuilder: (context, index) {
                                  final sentence = word.sentences[index];
                                  final isVisible = visibleTranslations.contains(sentence.id);
                                  return _buildSentenceCard(
                                    sentence,
                                    word.englishWord,
                                    isVisible,
                                    () {
                                      setStateDialog(() {
                                        if (isVisible) visibleTranslations.remove(sentence.id);
                                        else visibleTranslations.add(sentence.id);
                                      });
                                    },
                                  );
                                },
                              ),
                          ),
                          
                          // Footer Stats
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05))),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _buildUnilabeledDot(Colors.green, '${word.sentences.where((s) => s.difficulty == 'easy' || s.difficulty == null).length} Kolay'),
                                const SizedBox(width: 16),
                                _buildUnilabeledDot(Colors.amber, '${word.sentences.where((s) => s.difficulty == 'medium').length} Orta'),
                                const SizedBox(width: 16),
                                _buildUnilabeledDot(Colors.red, '${word.sentences.where((s) => s.difficulty == 'hard').length} Zor'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
                );
              },
            );
          },
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return Transform.scale(
          scale: anim1.value,
          child: Opacity(
            opacity: anim1.value,
            child: child,
          ),
        );
      },
    );
  }

  Widget _buildUnilabeledDot(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildSentenceCard(Sentence sentence, String targetWord, bool showTranslation, VoidCallback onToggle) {
    Color badgeColor = Colors.green;
    String badgeText = 'KOLAY';
    
    if (sentence.difficulty == 'medium') {
      badgeColor = Colors.amber;
      badgeText = 'ORTA';
    } else if (sentence.difficulty == 'hard') {
      badgeColor = Colors.red;
      badgeText = 'ZOR';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF38bdf8).withOpacity(0.25),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // Badge (Left Top)
            Positioned(
              top: 0,
              left: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeColor,
                  borderRadius: const BorderRadius.only(bottomRight: Radius.circular(12)),
                ),
                child: Text(
                  badgeText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 30, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  RichText(
                    text: TextSpan(
                      children: _buildHighlightedText(sentence.sentence, targetWord),
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 15,
                        color: Colors.white,
                        height: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Translate Button
                  InkWell(
                    onTap: onToggle,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white.withOpacity(0.2)),
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.white.withOpacity(0.05),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                             showTranslation ? Icons.visibility_off_outlined : Icons.remove_red_eye_outlined,
                             color: const Color(0xFF06b6d4),
                             size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            showTranslation ? 'Çeviriyi Gizle' : 'Çeviriyi Göster',
                            style: const TextStyle(
                              color: Color(0xFF06b6d4),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  if (showTranslation) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        sentence.translation,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<InlineSpan> _buildHighlightedText(String sentence, String target) {
    List<InlineSpan> spans = [];
    final lowerSentence = sentence.toLowerCase();
    final lowerTarget = target.toLowerCase();
    
    int start = 0;
    while (true) {
      final index = lowerSentence.indexOf(lowerTarget, start);
      if (index == -1) {
        spans.add(TextSpan(text: sentence.substring(start)));
        break;
      }
      
      if (index > start) {
        spans.add(TextSpan(text: sentence.substring(start, index)));
      }
      
      final matchedWord = sentence.substring(index, index + target.length);
      spans.add(
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
            decoration: BoxDecoration(
              color: const Color(0xFF06b6d4),
              borderRadius: BorderRadius.circular(4),
              boxShadow: [
                 BoxShadow(color: const Color(0xFF06b6d4).withOpacity(0.5), blurRadius: 4),
              ],
            ),
            child: Text(
              matchedWord,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ),
        ),
      );
      
      start = index + target.length;
    }
    return spans;
  }
}
