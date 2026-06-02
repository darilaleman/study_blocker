import 'package:flutter/material.dart';
import 'package:study_blocker/domain/entities/question.dart';
import 'package:study_blocker/presentation/quiz_overlay/widgets/question_card.dart';

class StudyMaterialScreen extends StatefulWidget {
  const StudyMaterialScreen({super.key});

  @override
  State<StudyMaterialScreen> createState() => _StudyMaterialScreenState();
}

class _StudyMaterialScreenState extends State<StudyMaterialScreen>
    with SingleTickerProviderStateMixin {
  TabController? _tabController;

  final List<String> _subjects = [
    'Todos',
    'Clean Architecture',
    'Sistemas Operativos',
    'Estructuras de Datos',
  ];

  late final List<Question> _mockQuestions;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _subjects.length, vsync: this);

    // Corregido: Agregados todos los campos requeridos por la entidad del dominio
    _mockQuestions = [
      Question(
        id: 1,
        subject: 'Clean Architecture',
        question:
            '¿Cuál es la responsabilidad principal de la capa de Dominio (Domain Layer)?',
        options: [
          'Gestionar las conexiones de red y APIs externas.', // Corregido el "and" por "y"
          'Alojar las entidades y las reglas puras de negocio de forma independiente.',
          'Pintar los widgets y reaccionar a las interacciones del usuario.',
          'Administrar las migraciones de la base de datos local SQLite.',
        ],
        correctAnswer:
            'Alojar las entidades y las reglas puras de negocio de forma independiente.',
        nextReview: DateTime.now(),
        interval: 0,
        easeFactor: 2.5,
        repetitions: 0,
      ),
      Question(
        id: 2,
        subject: 'Sistemas Operativos',
        question:
            '¿Qué problema resuelve principalmente el algoritmo de planificación Round Robin?',
        options: [
          'La fragmentación interna de la memoria RAM estática.',
          'La asignación equitativa del tiempo de CPU evitando la hambruna de procesos.',
          'El cifrado asimétrico de los bloques de disco en sistemas EXT4.',
          'La sincronización de hilos mediante semáforos de exclusión mutua.',
        ],
        correctAnswer:
            'La asignación equitativa del tiempo de CPU evitando la hambruna de procesos.',
        nextReview: DateTime.now().add(const Duration(days: 4)),
        interval: 4,
        easeFactor: 2.6,
        repetitions: 2,
      ),
    ];
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  List<Question> _getFilteredQuestions(String subject) {
    if (subject == 'Todos') return _mockQuestions;
    return _mockQuestions.where((q) => q.subject == subject).toList();
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
                            : theme.colorScheme.surfaceContainerHighest
                                  .withValues(alpha: 0.3),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Material de Estudio',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: _subjects.map((subject) => Tab(text: subject)).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _subjects.map((subject) {
          final questions = _getFilteredQuestions(subject);

          if (questions.isEmpty) {
            return const Center(
              child: Text('No hay preguntas generadas para esta categoría.'),
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
  }
}
