import 'package:flutter/material.dart';
import 'dart:convert';

class QuizResultPage extends StatelessWidget {
  final Map<String, dynamic> quiz;
  final Map<String, dynamic> attempt;

  const QuizResultPage({
    super.key,
    required this.quiz,
    required this.attempt,
  });
  @override
  Widget build(BuildContext context) {
  final questions = List<Map<String, dynamic>>.from(quiz['questions'] ?? []);

  dynamic rawAnswers = attempt['answers'];
  if (rawAnswers is String) {
    try { rawAnswers = jsonDecode(rawAnswers); } catch (_) { rawAnswers = {}; }
  }
  final answersMap = (rawAnswers is Map) ? rawAnswers : {};

  Map<String, String> safeStringMap(dynamic val) {
    if (val is Map) {
      return val.map((k, v) => MapEntry(k.toString(), v?.toString() ?? ''));
    }
    return {};
  }

  final mcAnswers    = safeStringMap(answersMap['multiple_choice']);
  final idAnswers    = safeStringMap(answersMap['identification']);
  final essayAnswers = safeStringMap(answersMap['essay']);

  dynamic rawEssayScores = attempt['essay_scores'];
  Map<String, int> essayScores = {};
  if (rawEssayScores is Map) {
    essayScores = rawEssayScores.map(
      (k, v) => MapEntry(k.toString(), int.tryParse(v.toString()) ?? 0),
    );
  }

  final essayTotal = attempt['essay_score_total'] != null
      ? int.tryParse(attempt['essay_score_total'].toString()) ?? 0
      : essayScores.values.fold(0, (a, b) => a + b);
  final hasEssayScores = essayScores.values.any((s) => s > 0);

  final scoreCorrect = attempt['score_correct'] ?? 0;
  final scoreTotal   = attempt['score_total'] ?? questions.length;
  final essayCount   = questions.where((q) => q['type']?.toString() == 'Essay').length;

    return Scaffold(
      appBar: AppBar(
        title: Text(quiz['title'] ?? 'Quiz Results'),
        backgroundColor: const Color(0xFF0d2b5c),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // ── Score header ──────────────────────────────────────────────────
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.quiz, size: 32, color: Color(0xFF0d2b5c)),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Objective Score',
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                        Text('$scoreCorrect / $scoreTotal',
                            style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0d2b5c))),
                      ],
                    ),
                  ],
                ),
                // Essay score row
                if (essayCount > 0) ...[
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 8),
                  if (hasEssayScores)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.grade, size: 20, color: Colors.green.shade600),
                        const SizedBox(width: 8),
                        Text(
                          'Essay Score: $essayTotal pts (teacher-graded)',
                          style: TextStyle(
                              color: Colors.green.shade700,
                              fontWeight: FontWeight.w600,
                              fontSize: 14),
                        ),
                      ],
                    )
                  else
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.pending, size: 20, color: Colors.orange.shade600),
                        const SizedBox(width: 8),
                        Text(
                          'Essay: awaiting teacher score',
                          style: TextStyle(
                              color: Colors.orange.shade700,
                              fontWeight: FontWeight.w500,
                              fontSize: 14),
                        ),
                      ],
                    ),
                ],
              ],
            ),
          ),

          // ── Question list ─────────────────────────────────────────────────
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: questions.length,
              itemBuilder: (context, index) {
                final q            = questions[index];
                final type         = q['type']?.toString() ?? '';
                final questionText = q['text']?.toString() ?? '';

                final userAnswer = _getUserAnswer(
                  index: index, type: type,
                  mcAnswers: mcAnswers, idAnswers: idAnswers, essayAnswers: essayAnswers,
                );
                final isCorrect     = _isAnswerCorrect(q, type, userAnswer);
                final correctAnswer = _getCorrectAnswer(q, type);

                final choices = (q['choices'] is List)
                    ? List<String>.from(q['choices'].map((e) => e?.toString() ?? ''))
                    : <String>[];

                // Teacher's essay score for this question
                final teacherScore = essayScores[index.toString()];

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Question text
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0d2b5c).withOpacity(0.05),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${index + 1}. $questionText',
                            style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                                color: Color(0xFF1a2b4a)),
                          ),
                        ),
                        const SizedBox(height: 12),

                        if (type == 'Multiple Choice')
                          _buildMultipleChoiceResult(
                            choices: choices,
                            userChoice: userAnswer,
                            correctChoiceLetter: q['correctAnswer']?.toString() ?? '',
                          )
                        else if (type == 'Identification')
                          _buildIdentificationResult(
                            userAnswer: userAnswer,
                            correctAnswer: correctAnswer,
                            isCorrect: isCorrect,
                          )
                        else
                          _buildEssayResult(
                            userAnswer: userAnswer,
                            sampleAnswer: correctAnswer,
                            teacherScore: teacherScore,
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ── Multiple choice ─────────────────────────────────────────────────────────
  Widget _buildMultipleChoiceResult({
    required List<String> choices,
    required String userChoice,
    required String correctChoiceLetter,
  }) {
    final selectedLetter = userChoice.trim().toUpperCase();
    final correctLetter  = correctChoiceLetter.trim().toUpperCase();

    return Column(
      children: List.generate(choices.length, (i) {
        final letter         = String.fromCharCode(65 + i);
        final isSelected     = letter == selectedLetter;
        final isCorrectChoice= letter == correctLetter;

        Color bgColor   = Colors.grey.shade50;
        Color textColor = Colors.grey.shade800;
        Widget? trailing;

        if (isSelected && isCorrectChoice) {
          bgColor   = Colors.green.shade50;
          textColor = Colors.green.shade800;
          trailing  = const Icon(Icons.check, color: Colors.green, size: 18);
        } else if (isSelected && !isCorrectChoice) {
          bgColor   = Colors.red.shade100;
          textColor = Colors.red.shade900;
          trailing  = const Icon(Icons.cancel, color: Colors.red, size: 20);
        } else if (isCorrectChoice) {
          bgColor   = Colors.green.shade50;
          textColor = Colors.green.shade800;
          trailing  = const Icon(Icons.check, color: Colors.green, size: 18);
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected && !isCorrectChoice
                  ? Colors.red.shade300
                  : isCorrectChoice
                      ? Colors.green.shade300
                      : Colors.grey.shade300,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text('$letter. ${choices[i]}',
                    style: TextStyle(
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        color: textColor)),
              ),
              if (trailing != null) trailing,
            ],
          ),
        );
      }),
    );
  }

  // ── Identification ──────────────────────────────────────────────────────────
  Widget _buildIdentificationResult({
    required String userAnswer,
    required String correctAnswer,
    required bool isCorrect,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _answerRow('Your answer:', userAnswer,    isCorrect ? Colors.green : Colors.red),
        const SizedBox(height: 8),
        _answerRow('Correct answer:', correctAnswer, Colors.green),
      ],
    );
  }

  Widget _answerRow(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Text(label,
              style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(value.isNotEmpty ? value : '(blank)',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: color)),
          ),
        ],
      ),
    );
  }

  // ── Essay ───────────────────────────────────────────────────────────────────
  Widget _buildEssayResult({
    required String userAnswer,
    required String sampleAnswer,
    int? teacherScore,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Teacher score badge
        if (teacherScore != null && teacherScore > 0)
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.shade300),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.grade, size: 18, color: Colors.green.shade700),
                const SizedBox(width: 6),
                Text(
                  'Teacher Score: $teacherScore / 10',
                  style: TextStyle(
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.bold,
                      fontSize: 14),
                ),
              ],
            ),
          )
        else
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.shade300),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.pending, size: 18, color: Colors.orange.shade700),
                const SizedBox(width: 6),
                Text(
                  'Awaiting teacher score',
                  style: TextStyle(color: Colors.orange.shade700, fontSize: 13),
                ),
              ],
            ),
          ),

        // Sample answer / rubric
        if (sampleAnswer.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.lightbulb_outline, size: 16, color: Colors.amber.shade700),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Rubric / Sample Answer:',
                          style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text(sampleAnswer,
                          style: TextStyle(fontSize: 13, color: Colors.grey.shade800, height: 1.4)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],

        // Student answer
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.edit_note, size: 16, color: Colors.grey.shade600),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Your answer:',
                        style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.w500)),
                    const SizedBox(height: 4),
                    Text(
                      userAnswer.isNotEmpty ? userAnswer : '(blank)',
                      style: const TextStyle(
                          fontSize: 15, color: Color(0xFF1a2b4a), height: 1.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────
  String _getUserAnswer({
    required int index, required String type,
    required Map<String, String> mcAnswers,
    required Map<String, String> idAnswers,
    required Map<String, String> essayAnswers,
  }) {
    final i = index.toString();
    if (type == 'Multiple Choice') return mcAnswers[i] ?? '';
    if (type == 'Identification')  return idAnswers[i] ?? '';
    return essayAnswers[i] ?? '';
  }

  String _getCorrectAnswer(Map<String, dynamic> q, String type) {
    if (type == 'Multiple Choice') {
      final letter = q['correctAnswer']?.toString() ?? '';
      final choices = (q['choices'] is List)
          ? List<String>.from(q['choices'].map((e) => e?.toString() ?? ''))
          : <String>[];
      final idx = letter.toUpperCase().codeUnitAt(0) - 65;
      if (idx >= 0 && idx < choices.length) return '${letter.toUpperCase()}. ${choices[idx]}';
      return letter;
    }
    if (type == 'Identification') return q['answer']?.toString() ?? '';
    return q['sampleAnswer']?.toString() ?? '';
  }

  bool _isAnswerCorrect(Map<String, dynamic> q, String type, String userAnswer) {
    if (type == 'Multiple Choice') {
      return userAnswer.trim().toUpperCase() ==
          (q['correctAnswer']?.toString().trim().toUpperCase() ?? '');
    }
    if (type == 'Identification') {
      return userAnswer.trim().toUpperCase() ==
          (q['answer']?.toString().trim().toUpperCase() ?? '');
    }
    return false;
  }
}