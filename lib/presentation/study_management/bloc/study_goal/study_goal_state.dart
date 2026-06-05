import 'package:equatable/equatable.dart';
import 'package:installed_apps/app_info.dart';

enum StudyGoalStatus { initial, loading, success, error }

class StudyGoalState extends Equatable {
  final StudyGoalStatus status;
  final String? errorMessage;

  final List<Map<String, dynamic>> existingSubjects;
  final String? selectedSubjectId;
  final String? selectedSubjectName;
  final DateTime? examDate;

  final String? pdfFilePath;
  final String? pdfFileName;
  final int? pdfPageCount;

  final List<AppInfo> installedApps;
  final Set<String> blockedAppPackages;
  final bool isVip;

  const StudyGoalState({
    this.status = StudyGoalStatus.initial,
    this.errorMessage,
    this.existingSubjects = const [],
    this.selectedSubjectId,
    this.selectedSubjectName,
    this.examDate,
    this.pdfFilePath,
    this.pdfFileName,
    this.pdfPageCount,
    this.installedApps = const [],
    this.blockedAppPackages = const {},
    this.isVip = false,
  });

  StudyGoalState copyWith({
    StudyGoalStatus? status,
    String? errorMessage,
    List<Map<String, dynamic>>? existingSubjects,
    String? selectedSubjectId,
    String? selectedSubjectName,
    DateTime? examDate,
    String? pdfFilePath,
    String? pdfFileName,
    int? pdfPageCount,
    List<AppInfo>? installedApps,
    Set<String>? blockedAppPackages,
    bool? isVip,
  }) {
    return StudyGoalState(
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      existingSubjects: existingSubjects ?? this.existingSubjects,
      selectedSubjectId: selectedSubjectId ?? this.selectedSubjectId,
      selectedSubjectName: selectedSubjectName ?? this.selectedSubjectName,
      examDate: examDate ?? this.examDate,
      pdfFilePath: pdfFilePath ?? this.pdfFilePath,
      pdfFileName: pdfFileName ?? this.pdfFileName,
      pdfPageCount: pdfPageCount ?? this.pdfPageCount,
      installedApps: installedApps ?? this.installedApps,
      blockedAppPackages: blockedAppPackages ?? this.blockedAppPackages,
      isVip: isVip ?? this.isVip,
    );
  }

  bool get isFormValid =>
      (selectedSubjectId != null || selectedSubjectName?.isNotEmpty == true) &&
      examDate != null &&
      pdfFilePath != null;

  @override
  List<Object?> get props => [
    status,
    errorMessage,
    existingSubjects,
    selectedSubjectId,
    selectedSubjectName,
    examDate,
    pdfFilePath,
    pdfFileName,
    pdfPageCount,
    installedApps,
    blockedAppPackages,
    isVip,
  ];
}
