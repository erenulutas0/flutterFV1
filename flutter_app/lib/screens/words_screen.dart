import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../providers/word_provider.dart';
import '../models/word.dart';
import '../theme/app_theme.dart';
import 'word_sentences_screen.dart';

class WordsScreen extends StatefulWidget {
  const WordsScreen({super.key});

  @override
  State<WordsScreen> createState() => _WordsScreenState();
}

class _WordsScreenState extends State<WordsScreen> {
  DateTime _selectedDate = DateTime.now();
  Word? _selectedWord;
  final TextEditingController _englishController = TextEditingController();
  final TextEditingController _turkishController = TextEditingController();
  String _selectedDifficulty = 'easy';
  final Map<int, bool> _showTurkishMeaning = {}; // Kelime ID'sine göre Türkçe anlam gösterimi
  final ScrollController _scrollController = ScrollController(); // Scroll pozisyonunu korumak için

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<WordProvider>(context, listen: false);
      provider.loadDistinctDates();
      provider.loadWordsByDate(_selectedDate);
    });
  }

  @override
  void dispose() {
    _englishController.dispose();
    _turkishController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelime Öğrenme Takviminiz'),
      ),
      body: Consumer<WordProvider>(
        builder: (context, provider, _) {
          return Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: AppTheme.darkGradient,
              ),
            ),
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Calendar
                  Card(
                    color: AppTheme.darkSurface,
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: TableCalendar(
                        firstDay: DateTime.utc(2020, 1, 1),
                        lastDay: DateTime.utc(2030, 12, 31),
                        focusedDay: _selectedDate,
                        selectedDayPredicate: (day) {
                          return isSameDay(_selectedDate, day);
                        },
                        onDaySelected: (selectedDay, focusedDay) {
                          setState(() {
                            _selectedDate = selectedDay;
                            _selectedWord = null;
                          });
                          provider.loadWordsByDate(selectedDay);
                        },
                        eventLoader: (day) {
                          final markedDates = _buildMarkedDates(provider.dates);
                          return markedDates.contains(day) ? [day] : [];
                        },
                        calendarStyle: CalendarStyle(
                          defaultTextStyle: const TextStyle(color: AppTheme.textPrimary),
                          weekendTextStyle: TextStyle(color: AppTheme.textSecondary),
                          outsideTextStyle: TextStyle(color: AppTheme.textTertiary),
                          selectedDecoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: AppTheme.purpleGradient,
                            ),
                            shape: BoxShape.circle,
                          ),
                          todayDecoration: BoxDecoration(
                            color: AppTheme.primaryPurple.withOpacity(0.3),
                            shape: BoxShape.circle,
                            border: Border.all(color: AppTheme.primaryPurple, width: 2),
                          ),
                          markerDecoration: BoxDecoration(
                            color: AppTheme.accentGreen,
                            shape: BoxShape.circle,
                          ),
                        ),
                        headerStyle: HeaderStyle(
                          formatButtonVisible: false,
                          titleCentered: true,
                          titleTextStyle: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          leftChevronIcon: const Icon(
                            Icons.chevron_left,
                            color: AppTheme.textPrimary,
                          ),
                          rightChevronIcon: const Icon(
                            Icons.chevron_right,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        daysOfWeekStyle: const DaysOfWeekStyle(
                          weekdayStyle: TextStyle(color: AppTheme.textSecondary),
                          weekendStyle: TextStyle(color: AppTheme.textSecondary),
                        ),
                        calendarBuilders: CalendarBuilders(
                          defaultBuilder: (context, date, focusedDay) {
                            final markedDates = _buildMarkedDates(provider.dates);
                            final isMarked = _isDateMarked(date, markedDates);
                            
                            if (isMarked && !isSameDay(date, _selectedDate) && !isSameDay(date, DateTime.now())) {
                              return Container(
                                margin: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryPurple.withOpacity(0.5),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppTheme.primaryPurple,
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppTheme.primaryPurple.withOpacity(0.6),
                                      blurRadius: 6,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Text(
                                    '${date.day}',
                                    style: const TextStyle(
                                      color: AppTheme.textPrimary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              );
                            }
                            return null;
                          },
                          todayBuilder: (context, date, focusedDay) {
                            final markedDates = _buildMarkedDates(provider.dates);
                            final isMarked = _isDateMarked(date, markedDates);
                            
                            return Container(
                              margin: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: isMarked 
                                  ? AppTheme.primaryPurple.withOpacity(0.6)
                                  : AppTheme.primaryPurple.withOpacity(0.3),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppTheme.primaryPurple,
                                  width: isMarked ? 3 : 2,
                                ),
                                boxShadow: isMarked ? [
                                  BoxShadow(
                                    color: AppTheme.primaryPurple.withOpacity(0.7),
                                    blurRadius: 8,
                                    spreadRadius: 2,
                                  ),
                                ] : null,
                              ),
                              child: Center(
                                child: Text(
                                  '${date.day}',
                                  style: TextStyle(
                                    color: AppTheme.textPrimary,
                                    fontWeight: isMarked ? FontWeight.bold : FontWeight.w600,
                                    fontSize: isMarked ? 16 : 14,
                                  ),
                                ),
                              ),
                            );
                          },
                          selectedBuilder: (context, date, focusedDay) {
                            final markedDates = _buildMarkedDates(provider.dates);
                            final isMarked = _isDateMarked(date, markedDates);
                            
                            return Container(
                              margin: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: isMarked 
                                    ? [AppTheme.primaryPurple, AppTheme.lightPurple, AppTheme.purpleAccent]
                                    : AppTheme.purpleGradient,
                                ),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.primaryPurple.withOpacity(isMarked ? 0.8 : 0.6),
                                    blurRadius: isMarked ? 10 : 8,
                                    spreadRadius: isMarked ? 3 : 2,
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  '${date.day}',
                                  style: const TextStyle(
                                    color: AppTheme.textPrimary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            );
                          },
                          markerBuilder: (context, date, events) {
                            if (events.isNotEmpty) {
                              return Positioned(
                                bottom: 1,
                                child: Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: AppTheme.accentGreen,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppTheme.accentGreen.withOpacity(0.6),
                                        blurRadius: 3,
                                        spreadRadius: 1,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }
                            return null;
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Add Word Section
                  Card(
                    color: AppTheme.darkSurface,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Yeni Kelime Ekle',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 20),
                          TextField(
                            controller: _englishController,
                            style: const TextStyle(color: AppTheme.textPrimary),
                            decoration: const InputDecoration(
                              labelText: 'İngilizce Kelime',
                              labelStyle: TextStyle(color: AppTheme.textSecondary),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _turkishController,
                            style: const TextStyle(color: AppTheme.textPrimary),
                            decoration: const InputDecoration(
                              labelText: 'Türkçe Anlamı',
                              labelStyle: TextStyle(color: AppTheme.textSecondary),
                            ),
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            value: _selectedDifficulty,
                            dropdownColor: AppTheme.darkSurfaceVariant,
                            style: const TextStyle(color: AppTheme.textPrimary),
                            decoration: const InputDecoration(
                              labelText: 'Zorluk',
                              labelStyle: TextStyle(color: AppTheme.textSecondary),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'easy', child: Text('Kolay')),
                              DropdownMenuItem(value: 'medium', child: Text('Orta')),
                              DropdownMenuItem(value: 'difficult', child: Text('Zor')),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _selectedDifficulty = value!;
                              });
                            },
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: provider.isLoading
                                ? null
                                : () async {
                                    if (_englishController.text.isNotEmpty &&
                                        _turkishController.text.isNotEmpty) {
                                      await provider.addWord(
                                        english: _englishController.text,
                                        turkish: _turkishController.text,
                                        addedDate: _selectedDate,
                                        difficulty: _selectedDifficulty,
                                      );
                                      _englishController.clear();
                                      _turkishController.clear();
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: const Text('Kelime başarıyla eklendi!'),
                                            backgroundColor: AppTheme.accentGreen,
                                          ),
                                        );
                                      }
                                    }
                                  },
                            child: const Text('Kelime Ekle'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Word List Header
                  Text(
                    'Seçilen Tarihteki Kelimeler: ${DateFormat('dd/MM/yyyy').format(_selectedDate)}',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  if (provider.isLoading)
                    const Center(child: CircularProgressIndicator())
                  else if (provider.error != null)
                    Card(
                      color: AppTheme.darkSurface,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'Hata: ${provider.error}',
                          style: const TextStyle(color: AppTheme.accentRed),
                        ),
                      ),
                    )
                  else if (provider.words.isEmpty)
                    Card(
                      color: AppTheme.darkSurface,
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Center(
                          child: Text(
                            'Bu tarihte kelime bulunamadı.',
                            style: TextStyle(color: AppTheme.textTertiary),
                          ),
                        ),
                      ),
                    )
                  else
                    ...provider.words.map((word) => _buildWordCard(word, provider)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Set<DateTime> _buildMarkedDates(List<String> dateStrings) {
    return dateStrings
        .map((dateStr) {
          try {
            // Sadece tarih kısmını al (saat bilgisini yok say)
            final date = DateTime.parse(dateStr);
            return DateTime(date.year, date.month, date.day);
          } catch (e) {
            return null;
          }
        })
        .whereType<DateTime>()
        .toSet();
  }

  bool _isDateMarked(DateTime date, Set<DateTime> markedDates) {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    return markedDates.any((markedDate) {
      final normalizedMarked = DateTime(markedDate.year, markedDate.month, markedDate.day);
      return normalizedDate == normalizedMarked;
    });
  }

  Widget _buildWordCard(Word word, WordProvider provider) {
    final isSelected = _selectedWord?.id == word.id;
    final difficultyColor = _getDifficultyColor(word.difficulty);
    final showTurkish = _showTurkishMeaning[word.id] ?? false;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: isSelected ? AppTheme.darkSurfaceVariant : AppTheme.darkSurface,
      child: ExpansionTile(
        leading: IconButton(
          icon: const Icon(Icons.delete, color: AppTheme.accentRed),
          onPressed: () async {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                backgroundColor: AppTheme.darkSurface,
                title: const Text('Kelime Sil', style: TextStyle(color: AppTheme.textPrimary)),
                content: Text(
                  '"${word.englishWord}" kelimesini silmek istediğinizden emin misiniz?',
                  style: const TextStyle(color: AppTheme.textSecondary),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('İptal'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: TextButton.styleFrom(foregroundColor: AppTheme.accentRed),
                    child: const Text('Sil'),
                  ),
                ],
              ),
            );
            if (confirm == true) {
              await provider.deleteWord(word.id);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Kelime silindi'),
                    backgroundColor: AppTheme.accentGreen,
                  ),
                );
              }
              if (isSelected) {
                setState(() {
                  _selectedWord = null;
                });
              }
            }
          },
        ),
        title: Text(
          word.englishWord,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: difficultyColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            word.difficulty.toUpperCase(),
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        onExpansionChanged: (expanded) {
          if (expanded) {
            setState(() {
              _selectedWord = word;
            });
          }
        },
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Türkçe anlam butonu
                InkWell(
                  onTap: () {
                    setState(() {
                      _showTurkishMeaning[word.id] = !showTurkish;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.darkSurfaceVariant,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppTheme.primaryPurple.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          showTurkish ? Icons.visibility_off : Icons.visibility,
                          color: AppTheme.primaryPurple,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          showTurkish ? 'Türkçe Anlamı Gizle' : 'Ne Anlama Gelir?',
                          style: TextStyle(
                            color: AppTheme.primaryPurple,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (showTurkish) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.darkBackground,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      word.turkishMeaning,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Text(
                  'Zorluk: ${word.difficulty}',
                  style: const TextStyle(color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 8),
                Text(
                  'Öğrenme Tarihi: ${DateFormat('dd/MM/yyyy').format(word.learnedDate)}',
                  style: const TextStyle(color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          // Scroll pozisyonunu kaydet
                          final scrollPosition = _scrollController.hasClients 
                              ? _scrollController.offset 
                              : 0.0;
                          
                          // Cümleler ekranına git
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => WordSentencesScreen(
                                word: word,
                              ),
                            ),
                          );
                          
                          // Geri döndüğünde scroll pozisyonunu geri yükle
                          if (mounted && _scrollController.hasClients) {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (_scrollController.hasClients) {
                                _scrollController.jumpTo(scrollPosition);
                              }
                            });
                          }
                        },
                        icon: const Icon(Icons.text_fields),
                        label: const Text('Cümleler'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryPurple,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _showAddSentenceDialog(word, provider),
                        icon: const Icon(Icons.add),
                        label: const Text('Cümle Ekle'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return AppTheme.accentGreen;
      case 'medium':
        return AppTheme.accentOrange;
      case 'difficult':
        return AppTheme.accentRed;
      default:
        return AppTheme.gray600;
    }
  }

  void _showAddSentenceDialog(Word word, WordProvider provider) {
    final sentenceController = TextEditingController();
    final translationController = TextEditingController();
    String difficulty = 'easy';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkSurface,
        title: const Text('Cümle Ekle', style: TextStyle(color: AppTheme.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: sentenceController,
              style: const TextStyle(color: AppTheme.textPrimary),
              decoration: const InputDecoration(
                labelText: 'İngilizce Cümle',
                labelStyle: TextStyle(color: AppTheme.textSecondary),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: translationController,
              style: const TextStyle(color: AppTheme.textPrimary),
              decoration: const InputDecoration(
                labelText: 'Türkçe Çevirisi',
                labelStyle: TextStyle(color: AppTheme.textSecondary),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: difficulty,
              dropdownColor: AppTheme.darkSurfaceVariant,
              style: const TextStyle(color: AppTheme.textPrimary),
              decoration: const InputDecoration(
                labelText: 'Zorluk',
                labelStyle: TextStyle(color: AppTheme.textSecondary),
              ),
              items: const [
                DropdownMenuItem(value: 'easy', child: Text('Kolay')),
                DropdownMenuItem(value: 'medium', child: Text('Orta')),
                DropdownMenuItem(value: 'difficult', child: Text('Zor')),
              ],
              onChanged: (value) {
                difficulty = value!;
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (sentenceController.text.isNotEmpty &&
                  translationController.text.isNotEmpty) {
                await provider.addSentenceToWord(
                  wordId: word.id,
                  sentence: sentenceController.text,
                  translation: translationController.text,
                  difficulty: difficulty,
                );
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Cümle eklendi!'),
                      backgroundColor: AppTheme.accentGreen,
                    ),
                  );
                }
              }
            },
            child: const Text('Ekle'),
          ),
        ],
      ),
    );
  }
}
