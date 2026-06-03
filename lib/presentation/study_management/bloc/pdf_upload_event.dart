import 'package:equatable/equatable.dart';

abstract class PdfUploadEvent extends Equatable {
  const PdfUploadEvent();
  @override
  List<Object?> get props => [];
}

class InitializePdfUpload extends PdfUploadEvent {}

class SubjectNameChanged extends PdfUploadEvent {
  final String name;
  const SubjectNameChanged(this.name);
  @override
  List<Object?> get props => [name];
}

class ExamDateChanged extends PdfUploadEvent {
  final DateTime date;
  const ExamDateChanged(this.date);
  @override
  List<Object?> get props => [date];
}

class PdfFileSelected extends PdfUploadEvent {
  final String filePath;
  final String fileName;
  final int fileSizeMb;
  final int pageCount;

  const PdfFileSelected({
    required this.filePath,
    required this.fileName,
    required this.fileSizeMb,
    required this.pageCount,
  });

  @override
  List<Object?> get props => [filePath, fileName, fileSizeMb, pageCount];
}

class SavePdfRequested extends PdfUploadEvent {}

class ProcessAiRequested extends PdfUploadEvent {}
