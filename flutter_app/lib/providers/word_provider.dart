import 'package:flutter/foundation.dart';
import '../models/word.dart';
import '../services/api_service.dart';

class WordProvider with ChangeNotifier {
  final ApiService apiService;
  
  List<Word> _words = [];
  List<String> _dates = [];
  bool _isLoading = false;
  String? _error;

  WordProvider({required this.apiService});

  List<Word> get words => _words;
  List<String> get dates => _dates;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadAllWords() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _words = await apiService.getAllWords();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Word?> loadWordById(int id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final word = await apiService.getWordById(id);
      _error = null;
      return word;
    } catch (e) {
      _error = e.toString();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadWordsByDate(DateTime date) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _words = await apiService.getWordsByDate(date);
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadDistinctDates() async {
    try {
      _dates = await apiService.getAllDistinctDates();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> addWord({
    required String english,
    required String turkish,
    required DateTime addedDate,
    String difficulty = 'easy',
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final newWord = await apiService.createWord(
        english: english,
        turkish: turkish,
        addedDate: addedDate,
        difficulty: difficulty,
      );
      _words.add(newWord);
      await loadDistinctDates();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteWord(int id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await apiService.deleteWord(id);
      _words.removeWhere((word) => word.id == id);
      await loadDistinctDates();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addSentenceToWord({
    required int wordId,
    required String sentence,
    required String translation,
    String difficulty = 'easy',
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final updatedWord = await apiService.addSentenceToWord(
        wordId: wordId,
        sentence: sentence,
        translation: translation,
        difficulty: difficulty,
      );
      final index = _words.indexWhere((w) => w.id == wordId);
      if (index != -1) {
        _words[index] = updatedWord;
      }
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteSentenceFromWord(int wordId, int sentenceId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await apiService.deleteSentenceFromWord(wordId, sentenceId);
      final wordIndex = _words.indexWhere((w) => w.id == wordId);
      if (wordIndex != -1) {
        final word = _words[wordIndex];
        final updatedSentences = word.sentences
            .where((s) => s.id != sentenceId)
            .toList();
        _words[wordIndex] = Word(
          id: word.id,
          englishWord: word.englishWord,
          turkishMeaning: word.turkishMeaning,
          learnedDate: word.learnedDate,
          notes: word.notes,
          difficulty: word.difficulty,
          sentences: updatedSentences,
        );
      }
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

