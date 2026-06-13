import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import '../../../shapes/domain/entities/shape_entity.dart';

class Project extends Equatable {
  final String id;
  final String name;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? thumbnailPath;
  final List<ShapeEntity> shapes;

  const Project({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    this.thumbnailPath,
    this.shapes = const [],
  });

  int get shapeCount => shapes.length;

  Rect get contentBounds {
    if (shapes.isEmpty) return Rect.zero;
    return shapes.map((s) => s.rotatedBoundingBox).reduce(
      (a, b) => a.expandToInclude(b),
    );
  }

  Project copyWith({
    String? id,
    String? name,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? thumbnailPath,
    List<ShapeEntity>? shapes,
  }) {
    return Project(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      shapes: shapes ?? this.shapes,
    );
  }

  @override
  List<Object?> get props => [id, name, createdAt, updatedAt, thumbnailPath, shapes.length];
}
