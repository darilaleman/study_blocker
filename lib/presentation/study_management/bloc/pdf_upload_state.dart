import 'package:equatable/equatable.dart';

enum PdfUploadStatus {
  initial,
  loading,
  success,
  aiProcessing,
  aiSuccess,
  error,
}

class PdfUploadState extends Equatable {
  final PdfUploadStatus status;
  final bool isVip;
  final String subjectName;
  final DateTime? examDate;
  final String? fileName;
  final String? filePath;
  final int? pageCount;
  final String errorMessage;

  const PdfUploadState({
    this.status = PdfUploadStatus.initial,
    this.isVip = false,
    this.subjectName = '',
    this.examDate,
    this.fileName,
    this.filePath,
    this.pageCount,
    this.errorMessage = '',
  });

  PdfUploadState copyWith({
    PdfUploadStatus? status,
    bool? isVip,
    String? subjectName,
    DateTime? examDate,
    String? fileName,
    String? filePath,
    int? pageCount,
    String? errorMessage,
  }) {
    return PdfUploadState(
      status: status ?? this.status,
      isVip: isVip ?? this.isVip,
      subjectName: subjectName ?? this.subjectName,
      examDate: examDate ?? this.examDate,
      fileName: fileName ?? this.fileName,
      filePath: filePath ?? this.filePath,
      pageCount: pageCount ?? this.pageCount,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  bool get isFormValid =>
      subjectName.isNotEmpty && examDate != null && filePath != null;

  @override
  List<Object?> get props => [
    status,
    isVip,
    subjectName,
    examDate,
    fileName,
    filePath,
    pageCount,
    errorMessage,
  ];
}
