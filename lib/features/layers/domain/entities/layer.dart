import 'package:equatable/equatable.dart';

class LayerEntity extends Equatable {
  final int id;
  final String name;
  final int order;
  final bool isVisible;
  final bool isLocked;
  final String? color;

  const LayerEntity({
    required this.id,
    required this.name,
    required this.order,
    this.isVisible = true,
    this.isLocked = false,
    this.color,
  });

  LayerEntity copyWith({
    int? id,
    String? name,
    int? order,
    bool? isVisible,
    bool? isLocked,
    String? color,
  }) {
    return LayerEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      order: order ?? this.order,
      isVisible: isVisible ?? this.isVisible,
      isLocked: isLocked ?? this.isLocked,
      color: color ?? this.color,
    );
  }

  @override
  List<Object?> get props => [id, name, order, isVisible, isLocked, color ?? ''];
}
