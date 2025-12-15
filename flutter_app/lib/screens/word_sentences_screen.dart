import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/word.dart';
import '../theme/app_theme.dart';
import '../providers/word_provider.dart';

class WordSentencesScreen extends StatefulWidget {
  final Word word;

  const WordSentencesScreen({
    super.key,
    required this.word,
  });

  @override
  State<WordSentencesScreen> createState() => _WordSentencesScreenState();
}

class _WordSentencesScreenState extends State<WordSentencesScreen> {
  Word? _currentWord;
  bool _showDefinition = false;

  @override
  void initState() {
    super.initState();
    _currentWord = widget.word;
    // Kelimeyi yeniden yükle
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshWord();
    });
  }

  Future<void> _refreshWord() async {
    final provider = Provider.of<WordProvider>(context, listen: false);
    // Kelimeyi ID'ye göre yükle - bu cümleler dahil olacak
    final updatedWord = await provider.loadWordById(widget.word.id);
    if (mounted && updatedWord != null) {
      setState(() {
        _currentWord = updatedWord;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final word = _currentWord ?? widget.word;
    
    return Scaffold(
      appBar: AppBar(
        title: Text('${word.englishWord} - Cümleler'),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: AppTheme.darkGradient,
          ),
        ),
        child: word.sentences.isEmpty
            ? Center(
                child: Card(
                  color: AppTheme.darkSurface,
                  margin: const EdgeInsets.all(16),
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.text_fields,
                          size: 64,
                          color: AppTheme.textTertiary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Bu kelime için henüz cümle eklenmemiş.',
                          style: TextStyle(color: AppTheme.textTertiary),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              )
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Kelime açıklama bölümü - en üstte
                  _buildWordDefinitionCard(word),
                  const SizedBox(height: 16),
                  // Cümleler listesi
                  ...word.sentences.map((sentence) => 
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildSentenceCard(context, sentence, word),
                    )
                  ).toList(),
                ],
              ),
      ),
    );
  }

  Widget _buildSentenceCard(BuildContext context, Sentence sentence, Word word) {
    final difficultyColor = _getDifficultyColor(sentence.difficulty ?? 'easy');

    return Card(
      color: AppTheme.darkSurface,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: difficultyColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    (sentence.difficulty ?? 'easy').toUpperCase(),
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                Builder(
                  builder: (context) => IconButton(
                    icon: const Icon(Icons.delete, color: AppTheme.accentRed),
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          backgroundColor: AppTheme.darkSurface,
                          title: const Text(
                            'Cümle Sil',
                            style: TextStyle(color: AppTheme.textPrimary),
                          ),
                          content: const Text(
                            'Bu cümleyi silmek istediğinizden emin misiniz?',
                            style: TextStyle(color: AppTheme.textSecondary),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('İptal'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              style: TextButton.styleFrom(
                                foregroundColor: AppTheme.accentRed,
                              ),
                              child: const Text('Sil'),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true && context.mounted) {
                        final provider = Provider.of<WordProvider>(context, listen: false);
                        await provider.deleteSentenceFromWord(word.id, sentence.id);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Cümle silindi'),
                              backgroundColor: AppTheme.accentGreen,
                            ),
                          );
                          // Kelimeyi yeniden yükle
                          await _refreshWord();
                        }
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              sentence.sentence,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              sentence.translation,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWordDefinitionCard(Word word) {
    return Card(
      color: AppTheme.darkSurface,
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _showDefinition = !_showDefinition;
              });
            },
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(
                    Icons.visibility_outlined,
                    color: AppTheme.primaryPurple,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Anlamı Göster',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryPurple,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    _showDefinition 
                        ? Icons.keyboard_arrow_up 
                        : Icons.keyboard_arrow_down,
                    color: AppTheme.primaryPurple,
                  ),
                ],
              ),
            ),
          ),
          if (_showDefinition) ...[
            const Divider(height: 1, color: AppTheme.gray700),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.book, size: 18, color: AppTheme.primaryPurple),
                      const SizedBox(width: 8),
                      Text(
                        word.englishWord,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.darkSurfaceVariant,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 4,
                          height: 16,
                          margin: const EdgeInsets.only(right: 12, top: 2),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: AppTheme.purpleGradient,
                            ),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            word.turkishMeaning,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppTheme.textSecondary,
                              height: 1.5,
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
      case 'hard':
      case 'difficult':
        return AppTheme.accentRed;
      default:
        return AppTheme.gray600;
    }
  }
}

