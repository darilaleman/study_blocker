import 'package:equatable/equatable.dart';

abstract class StudyGoalEvent extends Equatable {
  const StudyGoalEvent();
  @override
  List<Object?> get props => [];
}

class LoadInitialData extends StudyGoalEvent {}

class CreateNewSubject extends StudyGoalEvent {
  final String name;
  const CreateNewSubject(this.name);
  @override
  List<Object?> get props => [name];
}

class SelectSubject extends StudyGoalEvent {
  final String subjectId;
  final String subjectName;
  const SelectSubject(this.subjectId, this.subjectName);
  @override
  List<Object?> get props => [subjectId, subjectName];
}

class SetExamDate extends StudyGoalEvent {
  final DateTime date;
  const SetExamDate(this.date);
  @override
  List<Object?> get props => [date];
}

class SelectPdf extends StudyGoalEvent {
  final String filePath;
  final String fileName;
  final int fileSizeMb;
  final int pageCount;
  const SelectPdf({
    required this.filePath,
    required this.fileName,
    required this.fileSizeMb,
    required this.pageCount,
  });
  @override
  List<Object?> get props => [filePath, fileName, fileSizeMb, pageCount];
}

class ToggleAppBlock extends StudyGoalEvent {
  final String packageName;
  const ToggleAppBlock(this.packageName);
  @override
  List<Object?> get props => [packageName];
}

class SaveStudyGoal extends StudyGoalEvent {}
