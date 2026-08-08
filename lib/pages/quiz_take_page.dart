import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '/services/api_client.dart';

class QuizTakePage extends StatefulWidget {
  final Map<String, dynamic> quiz;
  final String studentEmail;
  final String studentName;

  const QuizTakePage({
    super.key,
    required this.quiz,
    required this.studentEmail,
    this.studentName = 'Student',
  });

  @override
  State<QuizTakePage> createState() => _QuizTakePageState();
}

class _QuizTakePageState extends State<QuizTakePage> {
  late final List<Map<String, dynamic>> _questions;
  final Map<int, String> _mcSelections          = {};
  final Map<int, String> _identificationAnswers = {};
  final Map<int, String> _essayAnswers          = {};
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final questionsRaw = widget.quiz['questions'];
    _questions = questionsRaw is List
        ? List<Map<String, dynamic>>.from(questionsRaw)
        : [];
  }

  Future<void> _submitQuiz() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    try {
      final email = widget.studentEmail.trim();
      if (email.isEmpty) throw Exception('Student email is empty.');

      int correct = 0;
      final int total = _questions.length;

      for (int i = 0; i < _questions.length; i++) {
        final q    = _questions[i];
        final type = q['type']?.toString() ?? '';

        if (type == 'Multiple Choice') {
          final expected = (q['correctAnswer']?.toString() ?? '').trim().toUpperCase();
          final got      = (_mcSelections[i] ?? '').trim().toUpperCase();
          if (expected.isNotEmpty && got == expected) correct++;
        } else if (type == 'Identification') {
          final expected = (q['answer']?.toString() ?? '').trim().toUpperCase();
          final got      = (_identificationAnswers[i] ?? '').trim().toUpperCase();
          if (expected.isNotEmpty && got == expected) correct++;
        }
        // Essay: not auto-scored
      }

      final double percent = total > 0 ? (correct / total) * 100.0 : 0.0;

      final mcAnswers = _mcSelections.map((k, v) => MapEntry(k.toString(), v));
      final idAnswers = _identificationAnswers.map((k, v) => MapEntry(k.toString(), v));
      final essayAnswers = _essayAnswers.map((k, v) => MapEntry(k.toString(), v));

      final answersMap = {
        'multiple_choice': mcAnswers,
        'identification' : idAnswers,
        'essay'          : essayAnswers,
      };

      // ── Save to SharedPreferences as backup ──────────────────────────────
      final submission = {
        'quiz_id'      : widget.quiz['id']?.toString() ?? '',
        'quiz_title'   : widget.quiz['title']?.toString() ?? 'Untitled Quiz',
        'student_email': email,
        'student_name' : widget.studentName,
        'submitted_at' : DateTime.now().toIso8601String(),
        'score_correct': correct,
        'score_total'  : total,
        'score_percent': percent,
        'answers'      : answersMap,
        'essay_scores' : <String, int>{},
      };

      final prefs      = await SharedPreferences.getInstance();
      final key        = 'quiz_attempts_${email.replaceAll('.', '_')}';
      final existing   = prefs.getString(key);
      final List<Map<String, dynamic>> attempts = existing == null
          ? []
          : List<Map<String, dynamic>>.from(jsonDecode(existing));

      attempts.removeWhere((a) => a['quiz_id']?.toString() == submission['quiz_id']);
      attempts.add(submission);
      await prefs.setString(key, jsonEncode(attempts));

      // ── Save to database ──────────────────────────────────────────────────
      final apiClient = ApiClient();
      final response  = await apiClient.post('quiz_attempts.php', {
        'action'       : 'save',
        'quiz_id'      : submission['quiz_id'],
        'student_email': submission['student_email'],
        'student_name' : submission['student_name'],
        'answers'      : jsonEncode(answersMap),   // encode nested map
        'score_correct': correct,
        'score_total'  : total,
        'score_percent': percent,
      });

      if (response['success'] != true) {
        debugPrint('DB save warning: ${response['message']}');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Quiz submitted! Score: $correct/$total (${percent.toStringAsFixed(0)}%)')),
        );
        Navigator.pop(context, true);
      }
    } catch (e, st) {
      debugPrint('Quiz submit error: $e\n$st');
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Submission Error'),
            content: Text('Error: $e'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
            ],
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (_questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.quiz['title']?.toString() ?? 'Quiz')),
        body: const Center(child: Text('No questions found for this quiz.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.quiz['title']?.toString() ?? 'Quiz'),
        backgroundColor: const Color(0xFF0d2b5c),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if ((widget.quiz['description']?.toString() ?? '').isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  widget.quiz['description'].toString(),
                  style: TextStyle(color: Colors.grey.shade700),
                ),
              ),
            Expanded(
              child: ListView.builder(
                itemCount: _questions.length,
                itemBuilder: (context, index) {
                  final q    = _questions[index];
                  final type = q['type']?.toString() ?? '';
                  final text = q['text']?.toString() ?? '';

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${index + 1}. $text',
                              style: const TextStyle(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 10),
                          if (type == 'Multiple Choice')
                            _buildMultipleChoice(index, q)
                          else if (type == 'Identification')
                            _buildIdentification(index)
                          else
                            _buildEssay(index, q),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _submitQuiz,
                icon: _isSubmitting
                    ? const SizedBox(
                        height: 18, width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.send),
                label: const Text('Submit Quiz'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0d2b5c),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMultipleChoice(int index, Map<String, dynamic> q) {
    final choices  = List<String>.from(q['choices'] ?? []);
    final selected = _mcSelections[index];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(choices.length, (i) {
        final label = String.fromCharCode(65 + i);
        return RadioListTile<String>(
          value: label,
          groupValue: selected,
          title: Text('$label. ${choices[i]}'),
          dense: true,
          onChanged: (val) => setState(() => _mcSelections[index] = val ?? ''),
        );
      }),
    );
  }

  Widget _buildIdentification(int index) {
    return TextField(
      decoration: const InputDecoration(
        labelText: 'Your answer',
        border: OutlineInputBorder(),
      ),
      onChanged: (val) => _identificationAnswers[index] = val,
    );
  }

  Widget _buildEssay(int index, Map<String, dynamic> q) {
    final sampleAnswer = q['sampleAnswer']?.toString() ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (sampleAnswer.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
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
                      Text('Rubric:',
                          style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text(sampleAnswer,
                          style: TextStyle(fontSize: 13, color: Colors.grey.shade800)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
        TextField(
          maxLines: 5,
          decoration: InputDecoration(
            labelText: 'Your answer',
            hintText: 'Type your essay answer here...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.all(14),
          ),
          onChanged: (val) => _essayAnswers[index] = val,
        ),
      ],
    );
  }
}