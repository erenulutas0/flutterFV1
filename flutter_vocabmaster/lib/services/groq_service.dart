import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

/// Direkt Groq API ile iletişim kuran servis 
/// Sözlük kelime araması için kullanılır
class GroqService {
  static const String _baseUrl = 'https://api.groq.com/openai/v1/chat/completions';
  
  static String get _apiKey => dotenv.env['GROQ_API_KEY'] ?? '';

  /// Kelime anlamlarını, bağlamlarını ve örnek cümleleri getirir
  static Future<Map<String, dynamic>?> lookupWord(String word) async {
    if (_apiKey.isEmpty) {
      throw Exception('Groq API Key bulunamadı. Lütfen .env dosyasına GROQ_API_KEY ekleyin.');
    }

    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          "model": "llama-3.3-70b-versatile",
          "messages": [
            {
              "role": "system",
              "content": '''You are a comprehensive English-Turkish dictionary. When given an English word, provide a refined list of its different meanings in Turkish (up to 5). For EACH meaning, strictly provide:
1. The Turkish translation ('translation')
2. The context/nuance ('context') (e.g. literal, metaphorical, legal)
3. An English example sentence using that specific meaning ('example')

You must respond with valid JSON only. Do not include markdown formatting.
Format: { "word": "input_word", "type": "noun/verb/adj", "meanings": [ { "translation": "Turkish Meaning 1", "context": "Context 1", "example": "Example sentence 1" }, ... ] }'''
            },
            {
              "role": "user",
              "content": word
            }
          ],
          "temperature": 0.3,
          "max_tokens": 700
        }),
      ).timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final decodedBody = utf8.decode(response.bodyBytes);
        final data = jsonDecode(decodedBody);
        final content = data['choices'][0]['message']['content'];
        
        // Clean potential markdown
        String cleanContent = content.toString().trim();
        cleanContent = cleanContent.replaceAll('```json', '').replaceAll('```', '').trim();
        
        return jsonDecode(cleanContent);
      } else {
        print('Groq lookup Error: ${response.statusCode} - ${response.body}');
        throw Exception('API Hatası: ${response.statusCode}');
      }
    } catch (e) {
      print('Groq lookup error: $e');
      rethrow;
    }
  }

  /// Kelime anlamlarını DETAYLI olarak getirir - türler (n/v/adj/adv) ile birlikte
  static Future<Map<String, dynamic>> lookupWordDetailed(String word) async {
    if (_apiKey.isEmpty) {
      throw Exception('Groq API Key bulunamadı. Lütfen .env dosyasına GROQ_API_KEY ekleyin.');
    }

    final prompt = '''
Look up the English word/phrase "$word" and provide ALL its different meanings with word types.

For EACH meaning, provide:
1. "type" - Word type (n = noun, v = verb, adj = adjective, adv = adverb, phr = phrasal verb, idiom = idiom)
2. "turkishMeaning" - Turkish translation for this specific meaning
3. "englishDefinition" - Brief English definition
4. "example" - An example sentence using the word in this specific meaning
5. "exampleTranslation" - Turkish translation of the example sentence

Return ONLY valid JSON in this exact format:
{
  "word": "$word",
  "phonetic": "/phonetic transcription/",
  "meanings": [
    {
      "type": "v",
      "turkishMeaning": "neden olmak, yol açmak",
      "englishDefinition": "to cause something to happen",
      "example": "The new policy will bring about significant changes.",
      "exampleTranslation": "Yeni politika önemli değişikliklere yol açacak."
    }
  ]
}

Be comprehensive - include ALL common meanings and word types for "$word".
''';

    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          "model": "llama-3.3-70b-versatile",
          "messages": [
            {
              "role": "system",
              "content": "You are a comprehensive English-Turkish dictionary. Always return valid JSON. Be thorough and include all word types and meanings."
            },
            {"role": "user", "content": prompt}
          ],
          "temperature": 0.3,
          "response_format": {"type": "json_object"}
        }),
      ).timeout(const Duration(seconds: 25));

      if (response.statusCode == 200) {
        final decodedBody = utf8.decode(response.bodyBytes);
        final data = jsonDecode(decodedBody);
        final content = data['choices'][0]['message']['content'];
        return jsonDecode(content);
      } else {
        print('Groq lookupDetailed Error: ${response.statusCode} - ${response.body}');
        throw Exception('API Hatası: ${response.statusCode}');
      }
    } catch (e) {
      print('Groq lookupDetailed error: $e');
      rethrow;
    }
  }

  /// Belirli bir anlam için yeni örnek cümle üretir
  static Future<String> generateSpecificSentence({
    required String word,
    required String translation,
    required String context,
  }) async {
    if (_apiKey.isEmpty) throw Exception('API Key yok');

    final prompt = "Generate a new, simple English sentence using the word '$word' specifically in the sense of '$translation' ($context). Return valid JSON: { \"sentence\": \"...\" }";

    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          "model": "llama-3.3-70b-versatile",
          "messages": [
            {"role": "system", "content": "You are a helper generating specific example sentences. Return valid JSON only."},
            {"role": "user", "content": prompt}
          ],
          "temperature": 0.7
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final decoded = utf8.decode(response.bodyBytes);
        final content = jsonDecode(decoded)['choices'][0]['message']['content'];
        String cleanContent = content.toString().trim().replaceAll('```json', '').replaceAll('```', '').trim();
        final json = jsonDecode(cleanContent);
        return json['sentence'];
      } else {
        throw Exception('API Error');
      }
    } catch (e) {
      return "Cümle oluşturulamadı.";
    }
  }

  /// Cümle içinde kelimenin anlamını açıklar
  static Future<String> explainWordInSentence(String word, String sentence) async {
    if (_apiKey.isEmpty) throw Exception('API Key yok');

    final prompt = "Explain the meaning of the word '$word' inside this specific sentence: '$sentence'. Provide the definition in Turkish, keeping it very short/concise (max 15 words). Return ONLY valid JSON. Format: { \"definition\": \"...\" }";

    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          "model": "llama-3.3-70b-versatile",
          "messages": [
            {"role": "system", "content": "You are a dictionary helper. Return valid JSON."},
            {"role": "user", "content": prompt}
          ],
          "temperature": 0.3
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final decoded = utf8.decode(response.bodyBytes);
        final content = jsonDecode(decoded)['choices'][0]['message']['content'];
        String cleanContent = content.toString().trim().replaceAll('```json', '').replaceAll('```', '').trim();
        final json = jsonDecode(cleanContent);
        return json['definition'];
      } else {
        throw Exception('API Error');
      }
    } catch (e) {
      return "Anlam bulunamadı.";
    }
  }

  /// Okuma parçası üretir (IELTS/TOEFL tarzı)
  static Future<Map<String, dynamic>> generateReadingPassage(String level) async {
    if (_apiKey.isEmpty) throw Exception('API Key yok');

    final prompt = '''
    Generate a short reading passage (about 150-200 words) for English learners at level $level. 
    Topic: General academic or interesting facts (IELTS/TOEFL style).
    Include 3 multiple choice questions (with 4 options and 1 correct answer).
    Return ONLY valid JSON. 
    Format:
    {
      "title": "Passage Title",
      "text": "Full passage text here...",
      "questions": [
        {
          "question": "Question 1?",
          "options": ["A", "B", "C", "D"],
          "correctAnswer": "A",
          "explanation": "Brief explanation of why A is correct.",
          "correctAnswerQuote": "Exact sentence or phrase from the text that proves the answer."
        },
        ...
      ]
    }
    ''';

    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          "model": "llama-3.3-70b-versatile",
          "messages": [
            {"role": "system", "content": "You are an exam preparation assistant. Return strictly valid JSON."},
            {"role": "user", "content": prompt}
          ],
          "temperature": 0.5
        }),
      ).timeout(const Duration(seconds: 40));

      if (response.statusCode == 200) {
        final decodedBody = utf8.decode(response.bodyBytes);
        final jsonResponse = jsonDecode(decodedBody);
        final content = jsonResponse['choices'][0]['message']['content'];
        
        final cleanContent = content.toString().replaceAll('```json', '').replaceAll('```', '').trim();
        return jsonDecode(cleanContent);
      } else {
        throw Exception('API Error: ${response.statusCode}');
      }
    } catch (e) {
      print('Error generating passage: $e');
      rethrow;
    }
  }
}
