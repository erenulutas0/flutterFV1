class SentencePractice {
  final String id; // Full ID like "practice_123" or "word_456"
  final String englishSentence;
  final String turkishTranslation;
  final String difficulty;
  final DateTime? createdDate;
  final String source; // 'practice' or 'word'
  final String? word;
  final String? wordTranslation;

  SentencePractice({
    required this.id,
    required this.englishSentence,
    required this.turkishTranslation,
    required this.difficulty,
    this.createdDate,
    required this.source,
    this.word,
    this.wordTranslation,
  });

  factory SentencePractice.fromJson(Map<String, dynamic> json) {
    // Handle both string IDs (from backend) and numeric IDs
    String id;
    if (json['id'] is String) {
      id = json['id'] as String;
    } else {
      // Fallback for numeric IDs
      id = '${json['source'] ?? 'practice'}_${json['id']}';
    }
    
    return SentencePractice(
      id: id,
      englishSentence: json['englishSentence'] as String,
      turkishTranslation: json['turkishTranslation'] as String,
      difficulty: json['difficulty'] as String? ?? 'easy',
      createdDate: json['createdDate'] != null
          ? DateTime.parse(json['createdDate'] as String)
          : null,
      source: json['source'] as String? ?? 'practice',
      word: json['word'] as String?,
      wordTranslation: json['wordTranslation'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'englishSentence': englishSentence,
      'turkishTranslation': turkishTranslation,
      'difficulty': difficulty,
      'createdDate': createdDate?.toIso8601String().split('T')[0],
      'source': source,
      'word': word,
      'wordTranslation': wordTranslation,
    };
  }
  
  // Get numeric ID part for display purposes
  int get numericId {
    try {
      return int.parse(id.split('_').last);
    } catch (e) {
      return 0;
    }
  }
}

