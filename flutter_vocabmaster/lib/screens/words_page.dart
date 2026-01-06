import 'package:flutter/material.dart';
import 'dart:ui';
import '../widgets/animated_background.dart';
import '../models/word.dart';
import '../services/offline_sync_service.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../widgets/info_dialog.dart';
import '../services/global_state.dart';

class WordsPage extends StatefulWidget {
  const WordsPage({Key? key}) : super(key: key);

  @override
  State<WordsPage> createState() => _WordsPageState();
}

class _WordsPageState extends State<WordsPage> {
  final OfflineSyncService _offlineSyncService = OfflineSyncService();
  final FlutterTts _flutterTts = FlutterTts();
  DateTime _selectedDate = DateTime.now();
  List<Word> _wordsForSelectedDate = [];
  Set<String> _datesWithWords = {}; // Dates that have words (YYYY-MM-DD format)
  bool _isLoading = false;
  bool _isOnline = true;

  final List<String> _weekDays = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];

  // Form Controllers
  final TextEditingController _englishWordController = TextEditingController();
  final TextEditingController _turkishMeaningController = TextEditingController();
  String _selectedDifficulty = 'Kolay';
  bool _isAddingWord = false;

  @override
  void initState() {
    super.initState();
    _isOnline = _offlineSyncService.isOnline;
    _loadDatesWithWords();
    _loadWordsForDate(_selectedDate);
    
    // Online durumu dinle
    _offlineSyncService.onlineStatus.listen((isOnline) {
      if (mounted) {
        setState(() => _isOnline = isOnline);
        if (isOnline) {
          // Online olunca yenile
          _loadDatesWithWords();
          _loadWordsForDate(_selectedDate);
        }
      }
    });
  }

  Future<void> _loadDatesWithWords() async {
    try {
      final dates = await _offlineSyncService.getAllDistinctDates();
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
      final words = await _offlineSyncService.getWordsByDate(date);
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

  Future<void> _addNewWord() async {
    final english = _englishWordController.text.trim();
    final turkish = _turkishMeaningController.text.trim();

    if (english.isEmpty || turkish.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen tüm alanları doldurun')),
      );
      return;
    }

    setState(() => _isAddingWord = true);

    try {
      String difficulty = 'easy';
      if (_selectedDifficulty == 'Orta') difficulty = 'medium';
      if (_selectedDifficulty == 'Zor') difficulty = 'hard';

      // OfflineSyncService ile kelime ekle (Otomatik olarak offline/online yönetir)
      await _offlineSyncService.createWord(
        english: english,
        turkish: turkish,
        addedDate: _selectedDate,
        difficulty: difficulty,
      );

      // Formu temizle
      _englishWordController.clear();
      _turkishMeaningController.clear();
      setState(() => _selectedDifficulty = 'Kolay');

      // Listeyi yenile
      await _loadWordsForDate(_selectedDate);
      await _loadDatesWithWords();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kelime başarıyla eklendi!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata oluştu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isAddingWord = false);
      }
    }
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
                  
                  // Add New Word Form Header
                  const Text(
                    'Yeni Kelime Ekle',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Add New Word Form
                  _buildAddNewWordForm(),

                  const SizedBox(height: 32),

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
                             child: const Icon(Icons.history_edu, color: Colors.blue, size: 32),
                           ),
                           const SizedBox(height: 16),
                           const Text(
                             'Henüz kelime yok',
                             style: TextStyle(
                               color: Colors.white,
                               fontSize: 18,
                               fontWeight: FontWeight.bold,
                             ),
                           ),
                           const SizedBox(height: 8),
                           Text(
                             'Yukarıdaki formu kullanarak bu güne yeni bir kelime ekleyin.',
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

  void _showDeleteWordConfirmDialog(Word word) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (context, _, __) => const SizedBox(),
      transitionBuilder: (context, anim, __, child) {
        return Transform.scale(
          scale: anim.value,
          child: Opacity(
            opacity: anim.value,
            child: Dialog(
              backgroundColor: Colors.transparent,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0f172a).withOpacity(0.9),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xFF06b6d4).withOpacity(0.3)),
                      boxShadow: [
                         BoxShadow(color: const Color(0xFF06b6d4).withOpacity(0.1), blurRadius: 20),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.delete_forever, color: Colors.redAccent, size: 32),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Kelimeyi Sil',
                          style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Bu kelimeyi silmek istediğinize emin misiniz? Buna bağlı tüm cümleler de kalıcı olarak silinecektir.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('İptal', style: TextStyle(color: Colors.white60)),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () async {
                                  Navigator.pop(context);
                                  try {
                                    await _offlineSyncService.deleteWord(word.id);
                                    if (mounted) {
                                       ScaffoldMessenger.of(context).showSnackBar(
                                         const SnackBar(content: Text('Kelime ve cümleleri silindi!'), backgroundColor: Colors.green)
                                       );
                                       _loadWordsForDate(_selectedDate);
                                    }
                                  } catch (e) {
                                    if (mounted) {
                                       ScaffoldMessenger.of(context).showSnackBar(
                                         SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red)
                                       );
                                    }
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.redAccent,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                                child: const Text('Sil'),
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
        );
      },
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
              top: 4,
              right: 4,
              child: IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.white60),
                onPressed: () => _showDeleteWordConfirmDialog(word),
              ),
            ),
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
              padding: const EdgeInsets.fromLTRB(20, 56, 20, 20),
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
    final sentenceController = TextEditingController();
    final translationController = TextEditingController();
    String dialogDifficulty = 'Kolay';
    bool isAddingSentence = false;

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) => const SizedBox(),
      transitionBuilder: (context, anim1, anim2, child) {
        return FadeTransition(
          opacity: anim1,
          child: ScaleTransition(
            scale: anim1,
            child: StatefulBuilder(
              builder: (context, setStateDialog) {
                return Dialog(
                  backgroundColor: Colors.transparent,
                  insetPadding: const EdgeInsets.symmetric(horizontal: 20),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                      child: Container(
                        width: MediaQuery.of(context).size.width,
                        decoration: BoxDecoration(
                          color: const Color(0xFF0f172a).withOpacity(0.75),
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
                                        'Yeni Cümle Ekle',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${word.englishWord} kelimesi için',
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
                              
                              const Text('İngilizce Cümle', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              TextField(
                                controller: sentenceController,
                                style: const TextStyle(color: Colors.white),
                                maxLines: 2,
                                decoration: InputDecoration(
                                  hintText: 'Örn: I love learning new ${word.englishWord}.',
                                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                                  filled: true,
                                  fillColor: Colors.white.withOpacity(0.05),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                ),
                              ),
                              
                              const SizedBox(height: 16),
                              const Text('Türkçe Anlamı', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              TextField(
                                controller: translationController,
                                style: const TextStyle(color: Colors.white),
                                maxLines: 2,
                                decoration: InputDecoration(
                                  hintText: 'Cümlenin Türkçe çevirisi...',
                                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                                  filled: true,
                                  fillColor: Colors.white.withOpacity(0.05),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                ),
                              ),
                              
                              const SizedBox(height: 16),
                              const Text('Zorluk Seviyesi', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: dialogDifficulty,
                                    isExpanded: true,
                                    dropdownColor: const Color(0xFF1e1b4b),
                                    style: const TextStyle(color: Colors.white),
                                    items: ['Kolay', 'Orta', 'Zor'].map((String value) {
                                      Color dotColor = Colors.green;
                                      if (value == 'Orta') dotColor = Colors.amber;
                                      if (value == 'Zor') dotColor = Colors.red;
                                      return DropdownMenuItem<String>(
                                        value: value,
                                        child: Row(
                                          children: [
                                            Container(width: 8, height: 8, decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle)),
                                            const SizedBox(width: 10),
                                            Text(value),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: (val) {
                                      if (val != null) setStateDialog(() => dialogDifficulty = val);
                                    },
                                  ),
                                ),
                              ),
                              
                              const SizedBox(height: 32),
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
                                        gradient: const LinearGradient(colors: [Color(0xFF00c6ff), Color(0xFF0072ff)]),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: ElevatedButton.icon(
                                        onPressed: isAddingSentence ? null : () async {
                                          final sentence = sentenceController.text.trim();
                                          final translation = translationController.text.trim();
                                          
                                          if (sentence.isEmpty || translation.isEmpty) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text('Lütfen tüm alanları doldurun'))
                                            );
                                            return;
                                          }
                                          
                                          setStateDialog(() => isAddingSentence = true);
                                          
                                          String diff = 'easy';
                                          if (dialogDifficulty == 'Orta') diff = 'medium';
                                          if (dialogDifficulty == 'Zor') diff = 'hard';
                                          
                                          try {
                                            await _offlineSyncService.addSentenceToWord(
                                              wordId: word.id,
                                              sentence: sentence,
                                              translation: translation,
                                              difficulty: diff,
                                            );
                                            
                                            if (mounted) {
                                              Navigator.pop(context);
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(content: Text('Cümle başarıyla eklendi!'), backgroundColor: Colors.green)
                                              );
                                              _loadWordsForDate(_selectedDate);
                                            }
                                          } catch (e) {
                                            if (mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red)
                                              );
                                            }
                                          } finally {
                                            if (mounted) setStateDialog(() => isAddingSentence = false);
                                          }
                                        },
                                        icon: isAddingSentence 
                                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                          : const Icon(Icons.add, color: Colors.white, size: 18),
                                        label: Text(
                                          isAddingSentence ? 'Ekleniyor...' : 'Kaydet',
                                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.transparent,
                                          shadowColor: Colors.transparent,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                );
              },
            ),
          ),
        );
      },
    );
  }

  // Removed _buildTextField(String hint) as we now defined _buildTextField(TextEditingController controller, String hint)
  // in the last chunk and _buildAddNewWordForm uses it. 
  // However, _showAddSentenceDialog also used _buildTextField(String hint).
  // We need to fix _showAddSentenceDialog to use proper controllers as well or adapt the method.
  
  // Let's redefine _buildTextField(String hint) for compatibility OR update _showAddSentenceDialog usage.
  // Better approach: Since I replaced _buildTextField(String hint) in the last chunk with a controller version,
  // I must double check if other parts of the code use the old signature.
  // Yes, _showAddSentenceDialog uses it. I will keep the old one but rename the new one or update usages.
  // Actually, I'll update _showAddSentenceDialog to use controllers too, but for now let's just create a wrapper.

  // Wait, I replaced the definition in the last chunk. Let's make sure I'm doing this right.
  // The last chunk REPLACED _buildHighlightedText AND added _buildAddNewWordForm AND _buildTextField.
  // This chunk targets the *old* _buildTextField implementation to remove/replace it?
  // No, I need to make sure _showAddSentenceDialog still works.
  
  // Let's modify _showAddSentenceDialog to use controllers and replace the old field builder.


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
                                    wordId: word.id,
                                    onDelete: (bool deleteGlobally) async {
                                      try {
                                        // If NOT deleting globally, we must save it as a Practice Sentence before removing from Word
                                        if (!deleteGlobally) {
                                          await _offlineSyncService.createSentence(
                                            englishSentence: sentence.sentence,
                                            turkishTranslation: sentence.translation,
                                            difficulty: sentence.difficulty ?? 'easy',
                                          );
                                        }

                                        // Always remove from the current Word
                                        await _offlineSyncService.deleteSentenceFromWord(
                                          wordId: word.id,
                                          sentenceId: sentence.id,
                                        );
                                        
                                        if (mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('İşlem başarıyla tamamlandı!'), backgroundColor: Colors.green)
                                          );
                                          Navigator.pop(context); // Dialog'u kapat
                                          _loadWordsForDate(_selectedDate); // Listeyi yenile
                                        }
                                      } catch (e) {
                                        if (mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red)
                                          );
                                        }
                                      }
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

  Widget _buildSentenceCard(Sentence sentence, String targetWord, bool showTranslation, VoidCallback onToggle, {int? wordId, Function(bool)? onDelete}) {
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
            
            // Delete Button (Right Top)
            if (wordId != null && onDelete != null)
              Positioned(
                top: 4,
                right: 4,
                child: IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.white38, size: 20),
                  onPressed: () => _showDeleteConfirmDialog(
                    title: 'Cümleyi Sil',
                    message: 'Bu cümleyi silmek istediğinize emin misiniz?',
                    onConfirm: onDelete,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
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

  void _showDeleteConfirmDialog({
    required String title,
    required String message,
    required Function(bool) onConfirm,
  }) {
    bool deleteGlobally = false;

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (context, _, __) => const SizedBox(),
      transitionBuilder: (context, anim, __, child) {
        return Transform.scale(
          scale: anim.value,
          child: Opacity(
            opacity: anim.value,
            child: StatefulBuilder(
              builder: (context, setStateDialog) {
                return Dialog(
                  backgroundColor: Colors.transparent,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0f172a).withOpacity(0.9),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: const Color(0xFF06b6d4).withOpacity(0.3)),
                          boxShadow: [
                             BoxShadow(color: const Color(0xFF06b6d4).withOpacity(0.1), blurRadius: 20),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                               decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.delete_forever, color: Colors.redAccent, size: 32),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              title,
                              style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              message,
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14),
                            ),
                            const SizedBox(height: 16),
                            
                            // Checkbox Option
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.white.withOpacity(0.1)),
                              ),
                              child: CheckboxListTile(
                                value: deleteGlobally,
                                onChanged: (val) {
                                  setStateDialog(() => deleteGlobally = val ?? false);
                                },
                                title: const Text(
                                  'Cümleler sayfasından da sil',
                                  style: TextStyle(color: Colors.white, fontSize: 14),
                                ),
                                checkColor: Colors.white,
                                activeColor: const Color(0xFF06b6d4),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                                controlAffinity: ListTileControlAffinity.leading,
                              ),
                            ),
                            
                            const SizedBox(height: 24),
                            Row(
                              children: [
                                Expanded(
                                  child: TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('İptal', style: TextStyle(color: Colors.white60)),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                      onConfirm(deleteGlobally);
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.redAccent,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                    ),
                                    child: const Text('Sil'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildAddNewWordForm() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1e3a8a).withOpacity(0.35),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildTextField(_englishWordController, 'İngilizce Kelime'),
          const SizedBox(height: 12),
          _buildTextField(_turkishMeaningController, 'Türkçe Anlamı'),
          const SizedBox(height: 12),
          _buildFormDifficultyDropdown(),
          const SizedBox(height: 20),
          SizedBox(
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _isAddingWord ? null : _addNewWord,
              icon: _isAddingWord 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.add, color: Colors.white),
              label: Text(
                _isAddingWord ? 'Ekleniyor...' : 'Kelime Ekle',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0072ff),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint) {
    return TextField(
      controller: controller,
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
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF06b6d4)),
        ),
      ),
    );
  }

  Widget _buildFormDifficultyDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedDifficulty,
          isExpanded: true,
          dropdownColor: const Color(0xFF1e1b4b),
          style: const TextStyle(color: Colors.white),
          items: ['Kolay', 'Orta', 'Zor'].map((String value) {
            Color itemColor = Colors.white;
            if (value == 'Kolay') itemColor = Colors.green;
            if (value == 'Orta') itemColor = Colors.amber;
            if (value == 'Zor') itemColor = Colors.red;
            
            return DropdownMenuItem<String>(
              value: value,
              child: Row(
                children: [
                  Container(
                    width: 8, height: 8,
                    decoration: BoxDecoration(color: itemColor, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 8),
                  Text(value),
                ],
              ),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() => _selectedDifficulty = value);
            }
          },
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
      // ... (Rest of existing highlight logic)
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
