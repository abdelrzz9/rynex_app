import 'package:equatable/equatable.dart';

class ProjectSummary extends Equatable {
  final String id;
  final String name;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int shapeCount;
  final String? thumbnailPath;

  const ProjectSummary({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    required this.shapeCount,
    this.thumbnailPath,
  });

  @override
  List<Object?> get props => [id, name, createdAt, updatedAt, shapeCount, thumbnailPath];
}
