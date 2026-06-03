import 'package:flutter/material.dart';
import 'package:study_blocker/data/datasources/local/question_local_datasource.dart';
import 'package:study_blocker/domain/entities/question.dart';
import 'package:study_blocker/injection_container.dart';
import 'package:study_blocker/presentation/quiz_overlay/widgets/question_card.dart';

class StudyMaterialScreen extends StatefulWidget {
  const StudyMaterialScreen({super.key});

  @override
  State<StudyMaterialScreen> createState() => _StudyMaterialScreenState();
}

class _StudyMaterialScreenState extends State<StudyMaterialScreen> {
  final QuestionLocalDataSource _questionLocalDataSource = sl();
  bool _isLoading = true;
  List<Map<String, dynamic>> _subjects = [];
  List<Question> _questions = [];

  @override
  void initState() {
    super.initState();
    _loadStudyData();
  }

  Future<void> _loadStudyData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final subjects = await _questionLocalDataSource.getAllSubjects();
      final questions = await _questionLocalDataSource.getAllQuestions();

      setState(() {
        _subjects = subjects;
        _questions = questions;
      });
    } catch (_) {
      setState(() {
        _subjects = [];
        _questions = [];
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<String> get _tabs {
    return ['Todos', ..._subjects.map((subject) => subject['name'] as String)];
  }

  List<Question> _getFilteredQuestions(String subject) {
    if (subject == 'Todos') return _questions;
    return _questions.where((q) => q.subject == subject).toList();
  }

  void _showQuestionDetailsBottomSheet(Question question) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final theme = Theme.of(context);
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          minChildSize: 0.4,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.outlineVariant,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.secondaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          question.subject,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.onSecondaryContainer,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Text(
                        'Repeticiones: ${question.repetitions}',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    question.question,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Opciones de Respuesta:',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...question.options.map((option) {
                    final isCorrect = option == question.correctAnswer;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isCorrect
                            ? Colors.green.withValues(alpha: 0.08)
                            : theme.colorScheme.surface.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isCorrect
                              ? Colors.green
                              : theme.colorScheme.outlineVariant,
                          width: isCorrect ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isCorrect
                                ? Icons.check_circle_rounded
                                : Icons.radio_button_unchecked_rounded,
                            color: isCorrect
                                ? Colors.green
                                : theme.colorScheme.onSurfaceVariant,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              option,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: isCorrect
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final scaffold = Scaffold(
      appBar: AppBar(
        title: const Text(
          'Material de Estudio',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        bottom: _isLoading || _tabs.isEmpty
            ? null
            : TabBar(
                isScrollable: true,
                tabs: _tabs.map((subject) => Tab(text: subject)).toList(),
              ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _tabs.isEmpty
          ? const Center(
              child: Text(
                'No hay materias registradas. Añade un PDF desde el Dashboard.',
                textAlign: TextAlign.center,
              ),
            )
          : TabBarView(
              children: _tabs.map((subject) {
                final questions = _getFilteredQuestions(subject);

                if (questions.isEmpty) {
                  return const Center(
                    child: Text(
                      'No hay preguntas generadas para esta categoría.',
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: questions.length,
                  itemBuilder: (context, index) {
                    final question = questions[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: QuestionCard(
                        question: question,
                        onTap: () => _showQuestionDetailsBottomSheet(question),
                      ),
                    );
                  },
                );
              }).toList(),
            ),
    );

    if (_isLoading || _tabs.isEmpty) {
      return scaffold;
    }

    return DefaultTabController(length: _tabs.length, child: scaffold);
  }
}
