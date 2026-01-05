import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

/// Chatbot servisi - Direkt Groq API kullanır (backend bağımsız)
/// Cümle üretimi, çeviri kontrolü ve chatbot işlemleri için kullanılır.
class ChatbotService {
  static const String _groqUrl = 'https://api.groq.com/openai/v1/chat/completions';
  static String get _apiKey => dotenv.env['GROQ_API_KEY'] ?? '';

  /// Kelime için pratik cümleleri üretir - DİREKT GROQ API
  Future<Map<String, dynamic>> generateSentences({
    required String word,
    List<String> levels = const ['B1'],
    List<String> lengths = const ['medium'],
    bool checkGrammar = false,
  }) async {
    if (_apiKey.isEmpty) {
      throw Exception('GROQ_API_KEY bulunamadı. .env dosyasını kontrol edin.');
    }

    // Random seed for variety
    final randomSeed = DateTime.now().millisecondsSinceEpoch;

    final prompt = '''
Generate 3 COMPLETELY NEW and UNIQUE English sentences using the word/phrase "$word".
Target levels: ${levels.join(', ')}
Target lengths: ${lengths.join(', ')} (short=5-8 words, medium=9-15 words, long=16+ words)

IMPORTANT: 
- Generate DIFFERENT sentences each time - be creative and varied!
- Use different contexts, scenarios, and sentence structures.
- Random seed for this request: $randomSeed

For each sentence, provide:
1. The English sentence
2. A natural, fluent Turkish translation (NOT word-for-word)

Return ONLY a valid JSON object in this exact format:
{
  "sentences": ["English sentence 1", "English sentence 2", "English sentence 3"],
  "translations": ["Türkçe çeviri 1", "Türkçe çeviri 2", "Türkçe çeviri 3"]
}
''';

    try {
      final response = await http.post(
        Uri.parse(_groqUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          "model": "llama-3.3-70b-versatile",
          "messages": [
            {"role": "system", "content": "You are an expert English-Turkish translator. Generate NEW, CREATIVE, and UNIQUE sentences each time. Never repeat the same sentences. Return ONLY valid JSON."},
            {"role": "user", "content": prompt}
          ],
          "temperature": 1.0,
          "top_p": 0.95,
          "response_format": {"type": "json_object"}
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final content = data['choices'][0]['message']['content'];
        return jsonDecode(content);
      } else {
        print('Groq generateSentences error: ${response.statusCode} - ${response.body}');
        throw Exception('Cümleler üretilemedi: ${response.statusCode}');
      }
    } catch (e) {
      print('ChatbotService.generateSentences error: $e');
      rethrow;
    }
  }

  /// Kullanıcının çevirisini kontrol eder - DİREKT GROQ API
  Future<Map<String, dynamic>> checkTranslation({
    required String originalSentence,
    required String userTranslation,
    required String direction, // 'EN_TO_TR' or 'TR_TO_EN'
    String? referenceSentence,
  }) async {
    if (_apiKey.isEmpty) {
      throw Exception('GROQ_API_KEY bulunamadı.');
    }

    String prompt;
    if (direction == 'EN_TO_TR') {
      prompt = '''
Check this English to Turkish translation:

English: "$originalSentence"
User's Turkish translation: "$userTranslation"

Be GENEROUS - if the meaning is correct and grammar is mostly right, mark as correct.
Ignore minor typos or spelling errors.

Return ONLY a JSON object:
{
  "isCorrect": true or false,
  "correctTranslation": "doğru Türkçe çeviri",
  "feedback": "Türkçe açıklama - teşvik edici olun"
}
''';
    } else {
      prompt = '''
Check this Turkish to English translation:

Turkish: "$originalSentence"
User's English translation: "$userTranslation"
${referenceSentence != null ? 'Reference: "$referenceSentence"' : ''}

Be GENEROUS - if the meaning is correct and grammar is mostly right, mark as correct.
Ignore minor typos.

Return ONLY a JSON object:
{
  "isCorrect": true or false,
  "correctTranslation": "correct English translation",
  "feedback": "explanation in Turkish"
}
''';
    }

    try {
      final response = await http.post(
        Uri.parse(_groqUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          "model": "llama-3.3-70b-versatile",
          "messages": [
            {"role": "system", "content": "You are a supportive translation checker. Return ONLY valid JSON."},
            {"role": "user", "content": prompt}
          ],
          "temperature": 0.3,
          "response_format": {"type": "json_object"}
        }),
      ).timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final content = data['choices'][0]['message']['content'];
        return jsonDecode(content);
      } else {
        throw Exception('Çeviri kontrol edilemedi: ${response.statusCode}');
      }
    } catch (e) {
      print('ChatbotService.checkTranslation error: $e');
      rethrow;
    }
  }

  /// AI Bot ile sohbet - DİREKT GROQ API
  Future<String> chat(String message) async {
    if (_apiKey.isEmpty) {
      throw Exception('GROQ_API_KEY bulunamadı.');
    }

    final systemPrompt = '''
You are Owen, a friendly English chat buddy. NOT a teacher. Just a friend chatting.

RULES:
1. MAX 10-12 words per sentence. Keep it short.
2. Start with a filler: "Alright...", "Nice!", "Hmm...", "Well...", "Okay...", "Oh!", "Cool!"
3. End with a question to keep conversation going.
4. Use contractions: I'm, you're, don't, can't, won't, let's.
5. NO teaching or grammar explanations. Just chat naturally.
6. If user makes a mistake, naturally use the correct form without correcting.

Format: [Filler] + [1-2 short sentences] + [Question]
''';

    try {
      final response = await http.post(
        Uri.parse(_groqUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          "model": "llama-3.3-70b-versatile",
          "messages": [
            {"role": "system", "content": systemPrompt},
            {"role": "user", "content": message}
          ],
          "temperature": 0.8,
          "max_tokens": 150
        }),
      ).timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return data['choices'][0]['message']['content'];
      } else {
        throw Exception('Chat failed: ${response.statusCode}');
      }
    } catch (e) {
      print('ChatbotService.chat error: $e');
      rethrow;
    }
  }

  /// Kelimeyi bugüne kaydet - BACKEND API (kelime kaydetme işlemi için)
  Future<Map<String, dynamic>> saveWordToToday({
    required String englishWord,
    List<String> meanings = const [],
    List<String> sentences = const [],
  }) async {
    final baseUrl = await AppConfig.apiBaseUrl;
    
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/chatbot/save-to-today'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'englishWord': englishWord,
          'meanings': meanings,
          'sentences': sentences,
        }),
      ).timeout(const Duration(seconds: 15));
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Kelime kaydedilemedi: ${response.statusCode}');
      }
    } catch (e) {
      print('ChatbotService.saveWordToToday error: $e');
      rethrow;
    }
  }

  /// IELTS/TOEFL Speaking test soruları oluştur - DİREKT GROQ API
  Future<Map<String, dynamic>> generateSpeakingTestQuestions({
    required String testType, // 'IELTS' or 'TOEFL'
    required String part,
  }) async {
    if (_apiKey.isEmpty) {
      throw Exception('GROQ_API_KEY bulunamadı.');
    }

    final prompt = '''
Generate authentic $testType Speaking test questions for $part.

For IELTS:
- Part 1: Personal questions (3-4 questions about everyday topics)
- Part 2: Cue card topic with sub-points
- Part 3: Abstract discussion questions (3-4 questions)

For TOEFL:
- Task 1: Independent speaking (personal opinion question)
- Task 2-4: Integrated speaking questions

Return ONLY a JSON object:
{
  "question": "The main question to ask",
  "questions": ["question1", "question2", ...],
  "instructions": "specific instructions for this part",
  "timeLimit": 60
}
''';

    try {
      final response = await http.post(
        Uri.parse(_groqUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          "model": "llama-3.3-70b-versatile",
          "messages": [
            {"role": "system", "content": "You are an expert $testType examiner. Return ONLY valid JSON."},
            {"role": "user", "content": prompt}
          ],
          "temperature": 0.7,
          "response_format": {"type": "json_object"}
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final content = data['choices'][0]['message']['content'];
        return jsonDecode(content);
      } else {
        throw Exception('Sorular oluşturulamadı: ${response.statusCode}');
      }
    } catch (e) {
      print('ChatbotService.generateSpeakingTestQuestions error: $e');
      rethrow;
    }
  }

  /// Speaking test cevabını değerlendir - DİREKT GROQ API
  Future<Map<String, dynamic>> evaluateSpeakingTest({
    required String testType,
    required String question,
    required String response,
  }) async {
    if (_apiKey.isEmpty) {
      throw Exception('GROQ_API_KEY bulunamadı.');
    }

    final prompt = '''
Evaluate this $testType Speaking test response:

Question: "$question"
Candidate's Response: "$response"

For IELTS, score 0-9 on: Fluency, Lexical Resource, Grammar, Pronunciation
For TOEFL, score 0-30 total on: Delivery, Language Use, Topic Development

Be fair and encouraging. Provide constructive feedback.

Return ONLY a JSON object:
{
  "score": number (IELTS: 0-9, TOEFL: 0-30),
  "band": "score as string",
  "feedback": "detailed feedback in Turkish",
  "suggestions": "improvement suggestions in Turkish"
}
''';

    try {
      final httpResponse = await http.post(
        Uri.parse(_groqUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          "model": "llama-3.3-70b-versatile",
          "messages": [
            {"role": "system", "content": "You are an expert $testType examiner. Return ONLY valid JSON."},
            {"role": "user", "content": prompt}
          ],
          "temperature": 0.5,
          "response_format": {"type": "json_object"}
        }),
      ).timeout(const Duration(seconds: 30));

      if (httpResponse.statusCode == 200) {
        final data = jsonDecode(utf8.decode(httpResponse.bodyBytes));
        final content = data['choices'][0]['message']['content'];
        return jsonDecode(content);
      } else {
        throw Exception('Değerlendirme başarısız: ${httpResponse.statusCode}');
      }
    } catch (e) {
      print('ChatbotService.evaluateSpeakingTest error: $e');
      rethrow;
    }
  }
}
