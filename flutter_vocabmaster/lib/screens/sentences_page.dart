import 'package:flutter/material.dart';
import 'dart:ui';
import '../widgets/animated_background.dart';
import '../models/word.dart';
import '../models/sentence_practice.dart';
import '../models/sentence_view_model.dart';
import '../services/offline_sync_service.dart';

class SentencesPage extends StatefulWidget {
  const SentencesPage({Key? key}) : super(key: key);

  @override
  State<SentencesPage> createState() => _SentencesPageState();
}

class _SentencesPageState extends State<SentencesPage> {
  final OfflineSyncService _offlineSyncService = OfflineSyncService();
  List<Word> allWords = [];
  List<SentenceViewModel> allSentences = [];
  List<SentenceViewModel> filteredSentences = [];
  bool isLoading = true;
  bool _isOnline = true;
  String _activeFilter = 'Tümü'; // Tümü, Kolay, Orta, Zor
  final TextEditingController _searchController = TextEditingController();

  // Add Sentence Dialog Controllers
  final TextEditingController _newWordEnglishController = TextEditingController();
  final TextEditingController _newWordTurkishController = TextEditingController();
  final TextEditingController _newSentenceEnglishController = TextEditingController();
  final TextEditingController _newSentenceTurkishController = TextEditingController();
  bool _isAddingToDailyWords = false;
  String _newSentenceDifficulty = 'Kolay';
  bool _isAddingSentenceState = false;

  // Mapping sentence to its word for display meta-data
  final Map<int, Word> _sentenceToWordMap = {};

  @override
  void initState() {
    super.initState();
    _isOnline = _offlineSyncService.isOnline;
    _loadData();
    _searchController.addListener(_filterSentences);
    
    // Online durumu dinle
    _offlineSyncService.onlineStatus.listen((isOnline) {
      if (mounted) {
        setState(() => _isOnline = isOnline);
        if (isOnline) {
          _loadData(); // Online olunca yenile
        }
      }
    });
  }

  Future<void> _loadData() async {
    try {
      final words = await _offlineSyncService.getAllWords();
      final practiceSentences = await _offlineSyncService.getAllSentences();

      final List<SentenceViewModel> viewModels = [];
      final Set<int> seenIds = {};

      // 1. Word Sentences
      for (var word in words) {
        for (var s in word.sentences) {
          if (seenIds.contains(s.id)) continue;
          seenIds.add(s.id);
          
          viewModels.add(SentenceViewModel(
            id: s.id,
            sentence: s.sentence,
            translation: s.translation,
            difficulty: s.difficulty ?? 'easy',
            word: word,
            isPractice: false,
            date: word.learnedDate,
          ));
        }
      }

      // 2. Practice Sentences
      for (var s in practiceSentences) {
        // Deduplication: Only skip if it's NOT a practice-source sentence (e.g. it's a word sentence retrieved via allSentences)
        // If source is 'practice', we keep it even if ID collides with a Word Sentence (different tables).
        if (s.source != 'practice' && s.numericId != 0 && seenIds.contains(s.numericId)) continue;
        
        viewModels.add(SentenceViewModel(
          id: s.id,
          sentence: s.englishSentence,
          translation: s.turkishTranslation,
          difficulty: s.difficulty,
          word: null,
          isPractice: true,
          date: s.createdDate ?? DateTime.now(),
        ));
      }

      // Sort: Newest first (En yeni en başta)
      viewModels.sort((a, b) => b.date.compareTo(a.date));

      setState(() {
        allWords = words;
        allSentences = viewModels;
        filteredSentences = viewModels;
        isLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
    }
  }


  void _filterSentences() {
    final query = _searchController.text.toLowerCase();
    
    setState(() {
      filteredSentences = allSentences.where((vm) {
        final matchesQuery = vm.sentence.toLowerCase().contains(query) || 
                             vm.translation.toLowerCase().contains(query) ||
                             (vm.word?.englishWord.toLowerCase().contains(query) ?? false);
                             
        final matchesFilter = _activeFilter == 'Tümü' || 
                              _mapDifficulty(vm.difficulty) == _activeFilter;
        
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
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 100.0),
        child: Container(
          width: 65,
          height: 65,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF00c6ff), Color(0xFF0072ff)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(35),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0072ff).withOpacity(0.4),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: FloatingActionButton(
            onPressed: _showAddNewSentenceDialog,
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: const Icon(Icons.add, color: Colors.white, size: 32),
          ),
        ),
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
                            final vm = filteredSentences[index];
                            return SentenceCard(
                              vm: vm,
                              mapDifficulty: _mapDifficulty,
                              onDelete: () async {
                                try {
                                  if (vm.isPractice) {
                                     await _offlineSyncService.deletePracticeSentence(vm.id);
                                  } else {
                                     if (vm.word != null) {
                                        await _offlineSyncService.deleteSentenceFromWord(
                                          wordId: vm.word!.id,
                                          sentenceId: vm.id,
                                        );
                                     }
                                  }
                                  
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Cümle silindi!'), backgroundColor: Colors.green)
                                    );
                                    _loadData();
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
    // Reset controllers
    _newWordEnglishController.clear();
    _newWordTurkishController.clear();
    _newSentenceEnglishController.clear();
    _newSentenceTurkishController.clear();
    setState(() {
      _isAddingToDailyWords = false;
      _newSentenceDifficulty = 'Kolay';
      _isAddingSentenceState = false;
    });

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
                  insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 400),
                        width: MediaQuery.of(context).size.width,
                        decoration: BoxDecoration(
                          color: const Color(0xFF0f172a).withOpacity(0.75),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.1),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 30,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Yeni Cümle Ekle',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 22,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          'Kelime seçerek veya seçmeden cümle ekleyebilirsiniz',
                                          style: TextStyle(
                                            color: Colors.white.withOpacity(0.6),
                                            fontSize: 13,
                                          ),
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
                              const SizedBox(height: 24),
                              Container(height: 1, color: Colors.white.withOpacity(0.1)),
                              const SizedBox(height: 24),

                              // Kelime Seçimi
                              const Text(
                                'Kelime Seçimi (Opsiyonel)',
                                style: TextStyle(
                                  color: Colors.white, 
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(child: _buildDialogTextField(_newWordEnglishController, 'İngilizce kelime')),
                                  const SizedBox(width: 12),
                                  Expanded(child: _buildDialogTextField(_newWordTurkishController, 'Türkçe anlamı')),
                                ],
                              ),
                              
                              const SizedBox(height: 16),
                              
                              // Checkbox section
                              GestureDetector(
                                onTap: () {
                                  setStateDialog(() => _isAddingToDailyWords = !_isAddingToDailyWords);
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: _isAddingToDailyWords 
                                        ? const Color(0xFF0072ff).withOpacity(0.15) 
                                        : Colors.white.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: _isAddingToDailyWords 
                                          ? const Color(0xFF0072ff).withOpacity(0.5) 
                                          : Colors.white.withOpacity(0.1)
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 24,
                                        height: 24,
                                        decoration: BoxDecoration(
                                          color: _isAddingToDailyWords ? const Color(0xFF0072ff) : Colors.transparent,
                                          borderRadius: BorderRadius.circular(6),
                                          border: _isAddingToDailyWords 
                                              ? null 
                                              : Border.all(color: Colors.white54, width: 2),
                                        ),
                                        child: _isAddingToDailyWords 
                                            ? const Icon(Icons.check, size: 16, color: Colors.white) 
                                            : null,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Bugünün Kelimelerine Ekle',
                                              style: TextStyle(
                                                color: _isAddingToDailyWords ? const Color(0xFF60a5fa) : Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              'Önce kelime ve anlamını girin',
                                              style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              
                              const SizedBox(height: 24),
                              
                              const Text('İngilizce Cümle', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              _buildDialogTextField(_newSentenceEnglishController, 'İngilizce cümle yazın...'),
                              
                              const SizedBox(height: 16),
                              const Text('Türkçe Anlamı', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              _buildDialogTextField(_newSentenceTurkishController, 'Türkçe anlamı yazın...'),
                              
                              const SizedBox(height: 16),
                              const Text('Zorluk Seviyesi', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              _buildDialogDifficultyDropdown(setStateDialog),
                              
                              const SizedBox(height: 32),
                              
                              Row(
                                children: [
                                  Expanded(
                                    child: SizedBox(
                                      height: 50,
                                      child: OutlinedButton(
                                        onPressed: () => Navigator.pop(context),
                                        style: OutlinedButton.styleFrom(
                                          side: BorderSide(color: Colors.white.withOpacity(0.2)),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        ),
                                        child: const Text('İptal', style: TextStyle(color: Colors.white70)),
                                      ),
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
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFF0072ff).withOpacity(0.3),
                                            blurRadius: 8,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: ElevatedButton.icon(
                                        onPressed: _isAddingSentenceState 
                                            ? null 
                                            : () => _handleAddNewSentence(context, setStateDialog),
                                        icon: _isAddingSentenceState 
                                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                                            : const Icon(Icons.add, color: Colors.white, size: 20),
                                        label: Text(
                                          _isAddingSentenceState ? 'Ekleniyor' : 'Cümle Ekle',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.transparent,
                                          shadowColor: Colors.transparent,
                                          padding: EdgeInsets.zero,
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
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildDialogTextField(TextEditingController controller, String hint) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 14),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
          borderSide: const BorderSide(color: Color(0xFF00c6ff)),
        ),
      ),
    );
  }

  Widget _buildDialogDifficultyDropdown(StateSetter setStateDialog) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _newSentenceDifficulty,
          isExpanded: true,
          dropdownColor: const Color(0xFF1e1b4b),
          style: const TextStyle(color: Colors.white, fontSize: 14),
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white54),
          items: ['Kolay', 'Orta', 'Zor'].map((String value) {
            Color itemColor = Colors.white;
            if (value == 'Kolay') itemColor = Colors.greenAccent;
            if (value == 'Orta') itemColor = Colors.amberAccent;
            if (value == 'Zor') itemColor = Colors.redAccent;

            return DropdownMenuItem<String>(
              value: value,
              child: Row(
                children: [
                  Container(
                    width: 8, height: 8,
                    decoration: BoxDecoration(color: itemColor, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 10),
                  Text(value),
                ],
              ),
            );
          }).toList(),
          onChanged: (val) {
            if (val != null) {
              setStateDialog(() => _newSentenceDifficulty = val);
            }
          },
        ),
      ),
    );
  }

  Future<void> _handleAddNewSentence(BuildContext context, StateSetter setStateDialog) async {
    final sentence = _newSentenceEnglishController.text.trim();
    final translation = _newSentenceTurkishController.text.trim();
    final word = _newWordEnglishController.text.trim();
    
    if (sentence.isEmpty || translation.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cümle ve anlamı gerekli.')));
      return;
    }

    setStateDialog(() => _isAddingSentenceState = true);

    try {
      String diff = 'easy';
      if (_newSentenceDifficulty == 'Orta') diff = 'medium';
      if (_newSentenceDifficulty == 'Zor') diff = 'hard';

      if (!_isAddingToDailyWords) {
           await _offlineSyncService.createSentence(
             englishSentence: sentence,
             turkishTranslation: translation,
             difficulty: diff
           );
      } else {
          int? wordId;
          String targetWord = word.isEmpty ? "General" : word;
          
          final existingWord = allWords.firstWhere(
            (w) => w.englishWord.toLowerCase() == targetWord.toLowerCase(),
            orElse: () => Word(id: -1, englishWord: '', turkishMeaning: '', learnedDate: DateTime.now(), difficulty: 'easy', sentences: [])
          );

          if (existingWord.id != -1) {
             wordId = existingWord.id;
          } else {
             final dialogMeaning = _newWordTurkishController.text.trim().isEmpty ? 'Genel' : _newWordTurkishController.text.trim();
             final newWord = await _offlineSyncService.createWord(
                english: targetWord,
                turkish: dialogMeaning,
                addedDate: DateTime.now(),
                difficulty: 'medium'
             );
             wordId = newWord?.id;
          }
          
          if (wordId != null && wordId != 0) {
             await _offlineSyncService.addSentenceToWord(
                wordId: wordId,
                sentence: sentence,
                translation: translation,
                difficulty: diff
             );
          }
      }

      // Başarılı
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cümle başarıyla eklendi!'), backgroundColor: Colors.green)
        );
        _loadData();
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) {
        setStateDialog(() => _isAddingSentenceState = false);
      }
    }
  }

}

class SentenceCard extends StatefulWidget {
  final SentenceViewModel vm;
  final String Function(String) mapDifficulty;
  final VoidCallback? onDelete;

  const SentenceCard({
    Key? key,
    required this.vm,
    required this.mapDifficulty,
    this.onDelete,
  }) : super(key: key);

  @override
  State<SentenceCard> createState() => _SentenceCardState();
}

class _SentenceCardState extends State<SentenceCard> {
  bool _isMeaningVisible = false;

  @override
  Widget build(BuildContext context) {
    final wordText = widget.vm.word?.englishWord ?? '';
    final difficulty = widget.mapDifficulty(widget.vm.difficulty);
    
    final sentenceText = widget.vm.sentence;
    final lowerSentence = sentenceText.toLowerCase();
    final lowerWord = wordText.toLowerCase();
    final int index = (wordText.isNotEmpty) ? lowerSentence.indexOf(lowerWord) : -1;
    
    List<InlineSpan> spans = [];
    if (index != -1) {
      // Before the word
      if (index > 0) {
        spans.add(TextSpan(
          text: sentenceText.substring(0, index),
          style: const TextStyle(color: Colors.white, fontSize: 18, height: 1.5),
        ));
      }
      
      // The highlighted word
      spans.add(WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF0ea5e9).withOpacity(0.3),
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
            sentenceText.substring(index, index + wordText.length),
            style: const TextStyle(
              color: Colors.cyanAccent, 
              fontSize: 18, 
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ));
      
      // After the word
      if (index + wordText.length < sentenceText.length) {
        spans.add(TextSpan(
          text: sentenceText.substring(index + wordText.length),
          style: const TextStyle(color: Colors.white, fontSize: 18, height: 1.5),
        ));
      }
    } else {
      spans.add(TextSpan(
        text: sentenceText,
        style: const TextStyle(color: Colors.white, fontSize: 18, height: 1.5),
      ));
    }

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
                      onPressed: widget.onDelete != null ? () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            backgroundColor: const Color(0xFF1e1b4b),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            title: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.delete_forever, color: Colors.red, size: 24),
                                ),
                                const SizedBox(width: 12),
                                const Text('Cümleyi Sil', style: TextStyle(color: Colors.white, fontSize: 18)),
                              ],
                            ),
                            content: const Text(
                              'Bu cümleyi silmek istediğinize emin misiniz?',
                              style: TextStyle(color: Colors.white70),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('İptal', style: TextStyle(color: Colors.white54)),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  widget.onDelete!();
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                child: const Text('Sil', style: TextStyle(color: Colors.white)),
                              ),
                            ],
                          ),
                        );
                      } : null,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Sentence with Highlight
                RichText(
                  text: TextSpan(
                    children: spans,
                    style: const TextStyle(height: 1.5),
                  ),
                ),
                
                // Meaning (Collapsible)
                AnimatedCrossFade(
                  firstChild: const SizedBox(height: 0),
                  secondChild: Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(height: 1, color: Colors.white.withOpacity(0.1)),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            const Icon(Icons.translate, color: Colors.white54, size: 16),
                            const SizedBox(width: 8),
                            Expanded(child: Text(
                              widget.vm.translation, // Use VM translation
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 16,
                                fontStyle: FontStyle.italic,
                              ),
                            )),
                          ],
                        ),
                      ],
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
