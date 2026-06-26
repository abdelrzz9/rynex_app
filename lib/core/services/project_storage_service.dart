import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../../features/projects/domain/entities/project.dart';
import '../../features/projects/domain/entities/project_summary.dart';
import '../../features/shapes/domain/entities/shape_factory.dart';

class ProjectStorageService {
  Directory? _baseDir;

  Future<Directory> _getDir() async {
    if (_baseDir != null) return _baseDir!;
    final appDir = await getApplicationDocumentsDirectory();
    _baseDir = Directory('${appDir.path}/rynex/projects');
    if (!await _baseDir!.exists()) {
      await _baseDir!.create(recursive: true);
    }
    return _baseDir!;
  }

  String _filePath(String projectId) => '$projectId.json';

  Future<void> saveProject(Project project) async {
    final dir = await _getDir();
    final data = {
      'id': project.id,
      'name': project.name,
      'createdAt': project.createdAt.toIso8601String(),
      'updatedAt': project.updatedAt.toIso8601String(),
      'thumbnailPath': project.thumbnailPath,
      'shapes': project.shapes.map((s) => s.toJson()).toList(),
    };
    final file = File('${dir.path}/${_filePath(project.id)}');
    await file.writeAsString(jsonEncode(data));
  }

  Future<Project?> loadProject(String id) async {
    try {
      final dir = await _getDir();
      final file = File('${dir.path}/${_filePath(id)}');
      if (!await file.exists()) return null;
      final data = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      return _parseProject(data);
    } on Object catch (_) {
      return null;
    }
  }

  Future<void> deleteProject(String id) async {
    final dir = await _getDir();
    final file = File('${dir.path}/${_filePath(id)}');
    if (await file.exists()) {
      await file.delete();
    }
  }

  Future<List<ProjectSummary>> listProjects() async {
    final dir = await _getDir();
    final files = await dir.list().toList();
    final summaries = <ProjectSummary>[];
    for (final entity in files) {
      if (entity is! File || !entity.path.endsWith('.json')) continue;
      try {
        final data = jsonDecode(await entity.readAsString()) as Map<String, dynamic>;
        summaries.add(ProjectSummary(
          id: data['id'] as String,
          name: data['name'] as String,
          createdAt: DateTime.parse(data['createdAt'] as String),
          updatedAt: DateTime.parse(data['updatedAt'] as String),
          thumbnailPath: data['thumbnailPath'] as String?,
          shapeCount: (data['shapes'] as List).length,
        ));
      } on Object catch (_) {}
    }
    summaries.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return summaries;
  }

  Project _parseProject(Map<String, dynamic> data) {
    try {
      final shapesData = data['shapes'] as List;
      final shapes = shapesData.map((s) => ShapeFactory.fromJson(s as Map<String, dynamic>)).toList();
      return Project(
        id: data['id'] as String,
        name: data['name'] as String,
        createdAt: DateTime.parse(data['createdAt'] as String),
        updatedAt: DateTime.parse(data['updatedAt'] as String),
        thumbnailPath: data['thumbnailPath'] as String?,
        shapes: shapes,
      );
    } on Object catch (_) {
      rethrow;
    }
  }
}
