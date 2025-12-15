class WordReview {
  final int id;
  final int wordId;
  final DateTime reviewDate;
  final String reviewType;
  final String? notes;

  WordReview({
    required this.id,
    required this.wordId,
    required this.reviewDate,
    required this.reviewType,
    this.notes,
  });

  factory WordReview.fromJson(Map<String, dynamic> json) {
    return WordReview(
      id: json['id'] as int,
      wordId: json['wordId'] as int,
      reviewDate: DateTime.parse(json['reviewDate'] as String),
      reviewType: json['reviewType'] as String,
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'wordId': wordId,
      'reviewDate': reviewDate.toIso8601String().split('T')[0],
      'reviewType': reviewType,
      'notes': notes,
    };
  }
}

