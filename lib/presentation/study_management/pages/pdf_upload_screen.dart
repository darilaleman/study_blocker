import 'package:flutter/material.dart';
import 'package:study_blocker/presentation/shared/widgets/custom_button.dart';
import 'package:study_blocker/presentation/shared/widgets/loading_indicator.dart';

class PdfUploadScreen extends StatefulWidget {
  const PdfUploadScreen({super.key});

  @override
  State<PdfUploadScreen> createState() => _PdfUploadScreenState();
}

class _PdfUploadScreenState extends State<PdfUploadScreen> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  String? _selectedFileName;
  String? _selectedFilePath;

  bool _isExtractingText = false;
  bool _isGeneratingWithAi = false;

  @override
  void dispose() {
    _subjectController.dispose();
    super.dispose();
  }

  Future<void> _pickPdfFile() async {
    // TODO: Implementar la llamada real a un paquete como 'file_picker'
    // Example: FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);

    // Simulación de selección de archivo exitosa:
    setState(() {
      _selectedFileName = "Apuntes_Clean_Architecture.pdf";
      _selectedFilePath = "/cache/uploads/Apuntes_Clean_Architecture.pdf";
    });
  }

  Future<void> _processDocument() async {
    if (!_formKey.currentState!.validate() || _selectedFilePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Por favor, ingresa una materia y selecciona un archivo PDF.',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Paso 1: Extracción de texto local
    setState(() => _isExtractingText = true);
    await Future.delayed(const Duration(seconds: 2));
    setState(() => _isExtractingText = false);

    // Paso 2: Generación en lote con IA Studio
    setState(() => _isGeneratingWithAi = true);
    await Future.delayed(const Duration(seconds: 3));
    setState(() => _isGeneratingWithAi = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Material de estudio e IA procesados exitosamente!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop(); // Regresar al Dashboard
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isProcessing = _isExtractingText || _isGeneratingWithAi;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Cargar Material PDF',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Crea Preguntas con IA',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Sube tus apuntes o libros en PDF. Nuestra Inteligencia Artificial extraerá los conceptos clave y creará un banco de preguntas automatizado bajo repetición espaciada.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // CAMPO: MATERIA O ASIGNATURA
                  TextFormField(
                    controller: _subjectController,
                    enabled: !isProcessing,
                    decoration: InputDecoration(
                      labelText: 'Materia / Asignatura',
                      hintText: 'Ej. Clean Architecture, Historia, Anatomía',
                      prefixIcon: const Icon(Icons.book_rounded),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Por favor, ingresa el nombre de la materia';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // ZONA DE ARRASTRE / SELECCIÓN DE ARCHIVO
                  InkWell(
                    onTap: isProcessing ? null : _pickPdfFile,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 40,
                        horizontal: 16,
                      ),
                      decoration: BoxDecoration(
                        color: _selectedFileName != null
                            ? theme.colorScheme.primaryContainer.withValues(
                                alpha: 0.1,
                              )
                            : theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _selectedFileName != null
                              ? theme.colorScheme.primary
                              : theme.colorScheme.outlineVariant,
                          style: BorderStyle.solid,
                          width: _selectedFileName != null ? 2 : 1,
                        ),
                      ),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(
                              _selectedFileName != null
                                  ? Icons.picture_as_pdf_rounded
                                  : Icons.cloud_upload_rounded,
                              size: 48,
                              color: _selectedFileName != null
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _selectedFileName ?? 'Seleccionar Documento PDF',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: _selectedFileName != null
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _selectedFileName != null
                                  ? 'Documento cargado en memoria listo para IA'
                                  : 'Formatos soportados: .pdf (Máx. 10MB)',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // BOTÓN DE ACCIÓN CENTRALIZADO
                  CustomButton(
                    text: 'Procesar con Inteligencia Artificial',
                    icon: Icons.auto_awesome_rounded,
                    onPressed: isProcessing ? null : _processDocument,
                  ),
                ],
              ),
            ),
          ),

          // OVERLAY FLOTANTE DE CARGA DINÁMICA
          if (_isExtractingText)
            const LoadingIndicator(
              isFullScreen: true,
              message:
                  'Analizando estructura del documento y extrayendo texto local plano...',
            ),
          if (_isGeneratingWithAi)
            const LoadingIndicator(
              isFullScreen: true,
              message:
                  'La Inteligencia Artificial está estructurando las preguntas de opción múltiple con el algoritmo de repetición espaciada...',
            ),
        ],
      ),
    );
  }
}
