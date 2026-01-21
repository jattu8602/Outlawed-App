class TestModel {
  final String id;
  final String title;
  final String? description;
  final int durationMinutes;
  final int numberOfQuestions;
  final bool isPaid;
  final String? thumbnailUrl;
  final List<dynamic>? highlights;
  final double? positiveMarks;
  final double? negativeMarks;
  final int attempts;
  final bool isAttempted;
  final String? testAttemptId;
  final double? lastScore;
  final DateTime? attemptedAt;
  final bool isNew;
  final String difficulty;
  final double? rating;
  final List<dynamic>? questions; // Light mapping of {id, section}

  TestModel({
    required this.id,
    required this.title,
    this.description,
    required this.durationMinutes,
    required this.numberOfQuestions,
    required this.isPaid,
    this.thumbnailUrl,
    this.highlights,
    this.positiveMarks,
    this.negativeMarks,
    required this.attempts,
    required this.isAttempted,
    this.testAttemptId,
    this.lastScore,
    this.attemptedAt,
    required this.isNew,
    required this.difficulty,
    this.rating,
    this.questions,
  });

  factory TestModel.fromJson(Map<String, dynamic> json) {
    return TestModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      durationMinutes: json['durationMinutes'] as int,
      numberOfQuestions: json['numberOfQuestions'] as int,
      isPaid: json['isPaid'] as bool,
      thumbnailUrl: json['thumbnailUrl'] as String?,
      highlights: json['highlights'] as List<dynamic>?,
      positiveMarks: (json['positiveMarks'] as num?)?.toDouble(),
      negativeMarks: (json['negativeMarks'] as num?)?.toDouble(),
      attempts: json['attempts'] as int,
      isAttempted: json['isAttempted'] as bool,
      testAttemptId: json['testAttemptId'] as String?,
      lastScore: (json['lastScore'] as num?)?.toDouble(),
      attemptedAt: json['attemptedAt'] != null
          ? DateTime.parse(json['attemptedAt'] as String)
          : null,
      isNew: json['isNew'] as bool,
      difficulty: json['difficulty'] as String? ?? 'Medium',
      rating: (json['rating'] as num?)?.toDouble(),
      questions: json['questions'] as List<dynamic>?,
    );
  }
}
