import 'package:flutter/material.dart';
import 'package:study_blocker/domain/entities/question.dart';

class QuestionCard extends StatelessWidget {
  final Question question;
  final VoidCallback? onTap;

  const QuestionCard({super.key, required this.question, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Calculamos una etiqueta humana para el intervalo del algoritmo SM2
    final String intervalText = question.interval == 0
        ? 'Repetir hoy'
        : 'Revisión en ${question.interval} ${question.interval == 1 ? 'día' : 'días'}';

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // FILA SUPERIOR: MATERIA Y METADATO SM2
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Chip de la Asignatura / PDF
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      question.subject,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  // Indicador de Intervalo de Memorización
                  Row(
                    children: [
                      Icon(
                        Icons.hourglass_empty_rounded,
                        size: 14,
                        color: question.interval == 0
                            ? Colors.orange
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        intervalText,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: question.interval == 0
                              ? Colors.orange[800]
                              : theme.colorScheme.onSurfaceVariant,
                          fontWeight: question.interval == 0
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // TEXTO DE LA PREGUNTA
              Text(
                question.question,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),

              const Divider(height: 1),
              const SizedBox(height: 12),

              // SUBTEXTO: RESPUESTA CORRECTA EN CAPSULA
              Row(
                children: [
                  Icon(
                    Icons.check_circle_outline_rounded,
                    size: 16,
                    color: Colors.green[700],
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: RichText(
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      text: TextSpan(
                        style: theme.textTheme.bodySmall,
                        children: [
                          TextSchemeSpan(
                            text: 'Solución: ',
                            style: TextStyle(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextSpan(
                            text: question.correctAnswer,
                            style: TextStyle(
                              color: Colors.green[800],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Pequeño indicador del Factor de Facilidad (Ease Factor)
                  Text(
                    'EF ${question.easeFactor.toStringAsFixed(2)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 10,
                      color: theme.colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.6,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Helper local para corregir la nomenclatura nativa de TextSpan
typedef TextSchemeSpan = TextSpan;
