import 'package:flutter/foundation.dart';
import '../models/sentence_practice.dart';
import '../services/api_service.dart';

class SentenceProvider with ChangeNotifier {
  final ApiService apiService;
  
  List<SentencePractice> _sentences = [];
  bool _isLoading = false;
  String? _error;
  Map<String, dynamic>? _stats;

  SentenceProvider({required this.apiService});

  List<SentencePractice> get sentences => _sentences;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, dynamic>? get stats => _stats;

  Future<void> loadAllSentences() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _sentences = await apiService.getAllSentences();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addSentence({
    required String englishSentence,
    required String turkishTranslation,
    required String difficulty,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final newSentence = await apiService.createSentence(
        englishSentence: englishSentence,
        turkishTranslation: turkishTranslation,
        difficulty: difficulty,
      );
      _sentences.add(newSentence);
      await loadStats();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteSentence(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await apiService.deleteSentence(id);
      _sentences.removeWhere((s) => s.id == id);
      await loadStats();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadStats() async {
    try {
      _stats = await apiService.getSentenceStats();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
}

