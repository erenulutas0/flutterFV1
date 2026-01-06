import 'word.dart';

class SentenceViewModel {
  final dynamic id;
  final String sentence;
  final String translation;
  final String difficulty;
  final Word? word;
  final bool isPractice;
  final DateTime date;

  SentenceViewModel({
    required this.id,
    required this.sentence,
    required this.translation,
    required this.difficulty,
    this.word,
    required this.isPractice,
    required this.date,
  });
}
