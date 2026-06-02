import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:study_blocker/domain/entities/question.dart';
import 'package:study_blocker/presentation/quiz_overlay/bloc/quiz_bloc.dart';
import 'package:study_blocker/presentation/quiz_overlay/bloc/quiz_event.dart';
import 'package:study_blocker/presentation/quiz_overlay/bloc/quiz_state.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  String? _selectedOption;
  bool _hasSubmitted = false;
  bool? _isCorrectResult;
  String _correctAnswerText = '';
  Question?
  _currentQuestion; // Almacenamos localmente la pregunta activa para que no desaparezca de la UI

  @override
  void initState() {
    super.initState();
    // Solicitamos la pregunta urgente al SM2 al iniciar
    context.read<QuizBloc>().add(FetchQuizQuestion());
  }

  void _onOptionSelected(String option) {
    if (_hasSubmitted) return; // Bloquear selección tras enviar
    setState(() {
      _selectedOption = option;
    });
  }

  void _onSubmit(Question question) {
    if (_selectedOption == null || _hasSubmitted) return;

    context.read<QuizBloc>().add(
      SubmitQuizAnswer(question: question, selectedAnswer: _selectedOption!),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Desbloqueo de Enfoque',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        automaticallyImplyLeading:
            false, // Impedir que el estudiante escape saltándose el cuestionario
      ),
      body: SafeArea(
        child: BlocConsumer<QuizBloc, QuizState>(
          listener: (context, state) {
            // Capturamos el resultado de la evaluación de forma reactiva sin destruir la UI de la pregunta
            if (state is QuizAnswerResult) {
              setState(() {
                _hasSubmitted = true;
                _isCorrectResult = state.isCorrect;
                _correctAnswerText = state.correctAnswer;
              });

              // Si es correcto, podemos cerrar el overlay automáticamente tras un breve delay instructivo
              if (state.isCorrect) {
                Future.delayed(const Duration(seconds: 2), () {
                  if (mounted) {
                    // TODO: Implementar aquí el canal nativo para cerrar la ventana flotante (System Alert Window)
                    // Navigator.of(context).pop();
                  }
                });
              }
            }
          },
          buildWhen: (previous, current) {
            // Evitamos que los estados de resultado destruyan el árbol visual de la pregunta actual
            return current is QuizLoading ||
                current is QuizQuestionLoaded ||
                current is QuizError;
          },
          builder: (context, state) {
            if (state is QuizLoading && _currentQuestion == null) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is QuizError && _currentQuestion == null) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Text(
                    state.message,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                ),
              );
            }

            if (state is QuizQuestionLoaded) {
              _currentQuestion = state.question;
            }

            // Si tenemos una pregunta cargada (ya sea del estado o en memoria local mientras se evalúa)
            if (_currentQuestion != null) {
              final question = _currentQuestion!;

              return Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Enunciado de la Pregunta
                    Text(
                      question.question,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Listado dinámico de opciones de opción múltiple
                    Expanded(
                      child: ListView.builder(
                        itemCount: question.options.length,
                        itemBuilder: (context, index) {
                          final option = question.options[index];
                          final isSelected = _selectedOption == option;

                          // Colores basados en el estado de la validación
                          Color tileColor = theme.colorScheme.surface;
                          Color borderColor = theme.colorScheme.outlineVariant;

                          if (isSelected) {
                            tileColor = theme.colorScheme.primaryContainer
                                .withOpacity(0.3);
                            borderColor = theme.colorScheme.primary;
                          }

                          if (_hasSubmitted) {
                            if (option == _correctAnswerText) {
                              tileColor = Colors.green.withOpacity(0.2);
                              borderColor = Colors.green;
                            } else if (isSelected &&
                                _isCorrectResult == false) {
                              tileColor = theme.colorScheme.errorContainer
                                  .withOpacity(0.4);
                              borderColor = theme.colorScheme.error;
                            }
                          }

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            key: ValueKey(option),
                          ).buildTile(
                            context,
                            child: ListTile(
                              title: Text(option),
                              leading: Radio<String>(
                                value: option,
                                groupValue: _selectedOption,
                                onChanged: _hasSubmitted
                                    ? null
                                    : (_) => _onOptionSelected(option),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                  color: borderColor,
                                  width: isSelected || _hasSubmitted ? 2 : 1,
                                ),
                              ),
                              tileColor: tileColor,
                              onTap: () => _onOptionSelected(option),
                            ),
                          );
                        },
                      ),
                    ),

                    // BOTÓN DE ACCIÓN / VERIFICACIÓN
                    FilledButton(
                      onPressed:
                          _selectedOption == null ||
                              (_hasSubmitted && _isCorrectResult == true)
                          ? null
                          : () => _onSubmit(question),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        backgroundColor: _hasSubmitted
                            ? (_isCorrectResult == true
                                  ? Colors.green
                                  : theme.colorScheme.error)
                            : theme.colorScheme.primary,
                      ),
                      child: state is QuizLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              _hasSubmitted
                                  ? (_isCorrectResult == true
                                        ? '¡Desbloqueado con éxito!'
                                        : 'Respuesta Incorrecta - Reintentar')
                                  : 'Verificar Respuesta',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              );
            }

            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: Text('No hay preguntas disponibles por el momento.'),
              ),
            );
          },
        ),
      ),
    );
  }
}

// Extensión utilitaria local para simplificar el wrapping de padding
extension on Padding {
  Widget buildTile(BuildContext context, {required Widget child}) {
    return Padding(padding: padding, child: child);
  }
}
