import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class GroqService {
  // Groq API Endpoint
  static const String _baseUrl = 'https://api.groq.com/openai/v1/chat/completions';
  
  // API Key - .env dosyasından okumaya çalış, yoksa boş döner.
  // Kullanıcının .env dosyasına GROQ_API_KEY eklemesi gerekir.
  static String get _apiKey => dotenv.env['GROQ_API_KEY'] ?? '';

  /// Kelime anlamını ve örnek cümleyi getirir.
  /// Kelime anlamlarını, bağlamlarını ve her biri için örnek cümleyi getirir.
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
              "content": "You are a comprehensive English-Turkish dictionary. When given an English word, provide a refined list of its different meanings in Turkish (up to 5). For EACH meaning, strictly provide: 1. The Turkish translation ('translation'), 2. The context/nuance ('context') (e.g. literal, metaphorical, legal), 3. An English example sentence using that specific meaning ('example'). You must respond with valid JSON only. Do not include markdown formatting. Format: { \"word\": \"input_word\", \"type\": \"noun/verb/adj\", \"meanings\": [ { \"translation\": \"Turkish Meaning 1\", \"context\": \"Context 1\", \"example\": \"Example sentence 1\" }, ... ] }"
            },
            {
              "role": "user",
              "content": word
            }
          ],
          "temperature": 0.3,
          "max_tokens": 500
        }),
      );

      if (response.statusCode == 200) {
        final decodedBody = utf8.decode(response.bodyBytes);
        final data = jsonDecode(decodedBody);
        final content = data['choices'][0]['message']['content'];
        return jsonDecode(content);
      } else {
        print('Groq lookup Error Body: ${response.body}');
        throw Exception('API Hatası: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Groq lookup error: $e');
      rethrow;
    }
  }

  /// Belirli bir anlam/bağlam için yeni bir örnek cümle üretir.
  static Future<String> generateSpecificSentence({
    required String word,
    required String translation,
    required String context,
  }) async {
    if (_apiKey.isEmpty) throw Exception('API Key yok');

    final prompt = "Generate a new, simple English sentence using the word '$word' specifically in the sense of '$translation' ($context). valid JSON: { \"sentence\": \"...\" }";

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
            {"role": "system", "content": "You are a helper generating specific example sentences. Return valid JSON."},
            {"role": "user", "content": prompt}
          ],
          "temperature": 0.7
        }),
      );

      if (response.statusCode == 200) {
        final decoded = utf8.decode(response.bodyBytes);
        final json = jsonDecode(jsonDecode(decoded)['choices'][0]['message']['content']);
        return json['sentence'];
      } else {
        throw Exception('API Error');
      }
    } catch (e) {
      return "Cümle oluşturulamadı.";
    }
  }
  static Future<String> explainWordInSentence({
    required String word,
    required String sentence,
  }) async {
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
      );

      if (response.statusCode == 200) {
        final decoded = utf8.decode(response.bodyBytes);
        final json = jsonDecode(jsonDecode(decoded)['choices'][0]['message']['content']);
        return json['definition'];
      } else {
        throw Exception('API Error');
      }
    } catch (e) {
      return "Anlam bulunamadı.";
    }
  }

  /// Verilen kelime, seviye ve uzunluklara göre pratik cümleleri üretir.
  static Future<Map<String, List<String>>> generateSentences({
    required String word,
    required List<String> levels,
    required List<String> lengths,
  }) async {
    if (_apiKey.isEmpty) {
      throw Exception('Groq API Key bulunamadı.');
    }

    final prompt = "Generate 3 English sentences containing the word/phrase '$word'. Target levels: ${levels.join(', ')}. Target lengths: ${lengths.join(', ')}. Also provide their Turkish translations. Return ONLY valid JSON. Format: { \"sentences\": [\"English sentence 1\", \"English sentence 2\", \"English sentence 3\"], \"translations\": [\"Turkish translation 1\", \"Turkish translation 2\", \"Turkish translation 3\"] }";

    final body = jsonEncode({
      "model": "llama-3.3-70b-versatile",
      "messages": [
        {
          "role": "system",
          "content": "You are an English language teacher. Generate practice sentences. strictly follow JSON format. Do not include markdown formatting like ```json ... ```. Just return the raw JSON."
        },
        {
          "role": "user",
          "content": prompt
        }
      ],
      "temperature": 0.7
    });

    print('DEBUG: Groq Generate Sentences Request: $body');

    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: body,
      );

      if (response.statusCode == 200) {
        final decodedBody = utf8.decode(response.bodyBytes);
        final data = jsonDecode(decodedBody);
        final content = data['choices'][0]['message']['content'];
        final jsonContent = jsonDecode(content);
        
        return {
          'sentences': List<String>.from(jsonContent['sentences']),
          'translations': List<String>.from(jsonContent['translations']),
        };
      } else {
        print('Groq generateSentences Error Body: ${response.body}');
        throw Exception('API Hatası: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Groq generate sentences error: $e');
      rethrow;
    }
  }

  /// Kullanıcının çevirisini kontrol eder.
  static Future<Map<String, dynamic>> checkTranslation({
    required String originalSentence,
    required String userTranslation,
    required String direction, // 'EN_TO_TR' or 'TR_TO_EN'
  }) async {
    if (_apiKey.isEmpty) {
      throw Exception('Groq API Key bulunamadı.');
    }

    final prompt = """
      Check if the user's translation is correct.
      Direction: $direction
      Original: "$originalSentence"
      User Translation: "$userTranslation"
      
      Return ONLY valid JSON.
      Format:
      {
        "isCorrect": true/false, // boolean, true if meaning is preserved even if not literal
        "feedback": "Short feedback explaining why it is correct or wrong",
        "correctTranslation": "An ideal correct translation"
      }
    """;

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
              "content": "You are a language teacher correcting translations. Be encouraging but precise. Do not include markdown formatting. Return valid JSON only."
            },
            {
              "role": "user",
              "content": prompt
            }
          ],
          "temperature": 0.3
        }),
      );

      if (response.statusCode == 200) {
        final decodedBody = utf8.decode(response.bodyBytes);
        final data = jsonDecode(decodedBody);
        final content = data['choices'][0]['message']['content'];
        return jsonDecode(content);
      } else {
        print('Groq checkTranslation Error Body: ${response.body}');
        throw Exception('API Hatası: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Groq check translation error: $e');
      rethrow;
    }
  }


  static Future<Map<String, dynamic>> generateReadingPassage(String level) async {
    if (_apiKey.isEmpty) throw Exception('API Key yok');

    final prompt = """
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
    """;

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
      );

      if (response.statusCode == 200) {
        final decodedBody = utf8.decode(response.bodyBytes);
        final jsonResponse = jsonDecode(decodedBody);
        final content = jsonResponse['choices'][0]['message']['content'];
        
        // Remove markdown if present
        final cleanContent = content.replaceAll('```json', '').replaceAll('```', '').trim();
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
