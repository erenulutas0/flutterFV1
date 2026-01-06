import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/word.dart';
import '../models/sentence_practice.dart';
import '../config/app_config.dart';

class ApiService {
  Future<String> get baseUrl async {
    return await AppConfig.apiBaseUrl;
  }

  // ==================== WORDS ====================

  Future<List<Word>> getAllWords() async {
    try {
      final url = await baseUrl;
      final response = await http.get(Uri.parse('$url/words'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Word.fromJson(json)).toList();
      }
      throw Exception('Failed to load words: ${response.statusCode}');
    } catch (e) {
      print('Error fetching words: $e');
      return []; 
    }
  }

  Future<Word> getWordById(int id) async {
    try {
      final url = await baseUrl;
      final response = await http.get(Uri.parse('$url/words/$id'));
      if (response.statusCode == 200) {
        return Word.fromJson(json.decode(response.body));
      }
      throw Exception('Failed to load word: ${response.statusCode}');
    } catch (e) {
      throw Exception('Error fetching word: $e');
    }
  }

  Future<List<String>> getAllDistinctDates() async {
    try {
      final url = await baseUrl;
      final response = await http.get(Uri.parse('$url/words/dates'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.cast<String>();
      }
      throw Exception('Failed to load dates: ${response.statusCode}');
    } catch (e) {
      print('Error fetching dates: $e');
      return [];
    }
  }

  Future<List<Word>> getWordsByDate(DateTime date) async {
    try {
      final url = await baseUrl;
      final dateStr = date.toIso8601String().split('T')[0];
      final response = await http.get(Uri.parse('$url/words/date/$dateStr'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Word.fromJson(json)).toList();
      }
      throw Exception('Failed to load words for date: ${response.statusCode}');
    } catch (e) {
      print('Error fetching words by date: $e');
      return [];
    }
  }

  Future<Word> createWord({
    required String english,
    required String turkish,
    required DateTime addedDate,
    String difficulty = 'easy',
  }) async {
    try {
      final url = await baseUrl;
      final response = await http.post(
        Uri.parse('$url/words'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'englishWord': english,
          'turkishMeaning': turkish,
          'learnedDate': addedDate.toIso8601String().split('T')[0],
          'notes': '',
          'difficulty': difficulty,
        }),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return Word.fromJson(json.decode(response.body));
      }
      throw Exception('Failed to create word: ${response.statusCode}');
    } catch (e) {
      throw Exception('Error creating word: $e');
    }
  }

  Future<void> deleteWord(int id) async {
    try {
      final url = await baseUrl;
      final response = await http.delete(Uri.parse('$url/words/$id'));
      if (response.statusCode != 200 && response.statusCode != 204 && response.statusCode != 404) {
        throw Exception('Failed to delete word: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error deleting word: $e');
    }
  }

  Future<Word> addSentenceToWord({
    required int wordId,
    required String sentence,
    required String translation,
    String difficulty = 'easy',
  }) async {
    try {
      final url = await baseUrl;
      final response = await http.post(
        Uri.parse('$url/words/$wordId/sentences'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'sentence': sentence,
          'translation': translation,
          'difficulty': difficulty,
        }),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return Word.fromJson(json.decode(response.body));
      }
      throw Exception('Failed to add sentence: ${response.statusCode}');
    } catch (e) {
      throw Exception('Error adding sentence: $e');
    }
  }

  Future<void> deleteSentenceFromWord(int wordId, int sentenceId) async {
    try {
      final url = await baseUrl;
      final response = await http.delete(
        Uri.parse('$url/words/$wordId/sentences/$sentenceId'),
      );
      if (response.statusCode != 200 && response.statusCode != 204 && response.statusCode != 404) {
        throw Exception('Failed to delete sentence: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error deleting sentence: $e');
    }
  }

  // ==================== SENTENCES ====================

  Future<List<SentencePractice>> getAllSentences() async {
    try {
      final url = await baseUrl;
      final response = await http.get(Uri.parse('$url/sentences'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => SentencePractice.fromJson(json)).toList();
      }
      throw Exception('Failed to load sentences: ${response.statusCode}');
    } catch (e) {
      print('Error fetching sentences: $e');
      return [];
    }
  }

  Future<SentencePractice> createSentence({
    required String englishSentence,
    required String turkishTranslation,
    required String difficulty,
  }) async {
    try {
      final url = await baseUrl;
      final response = await http.post(
        Uri.parse('$url/sentences'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'englishSentence': englishSentence,
          'turkishTranslation': turkishTranslation,
          'difficulty': difficulty.toUpperCase(),
          'createdDate': DateTime.now().toIso8601String().split('T')[0],
        }),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = json.decode(response.body);
        return SentencePractice.fromJson({
          'id': 'practice_${responseData['id']}',
          'englishSentence': responseData['englishSentence'],
          'turkishTranslation': responseData['turkishTranslation'],
          'difficulty': responseData['difficulty'],
          'createdDate': responseData['createdDate'],
          'source': 'practice',
        });
      }
      throw Exception('Failed to create sentence: ${response.statusCode}');
    } catch (e) {
      throw Exception('Error creating sentence: $e');
    }
  }

  Future<void> deleteSentence(String id) async {
    try {
      final url = await baseUrl;
      final response = await http.delete(Uri.parse('$url/sentences/$id'));
      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Failed to delete sentence: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error deleting sentence: $e');
    }
  }

  Future<Map<String, dynamic>> getSentenceStats() async {
    try {
      final url = await baseUrl;
      final response = await http.get(Uri.parse('$url/sentences/stats'));
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      throw Exception('Failed to load stats: ${response.statusCode}');
    } catch (e) {
      print('Error fetching stats: $e');
      return {};
    }
  }
}

