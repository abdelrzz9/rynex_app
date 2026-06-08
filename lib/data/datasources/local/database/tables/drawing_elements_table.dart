import 'package:drift/drift.dart';

class DrawingElementsTable extends Table {
  @override
  String get tableName => 'drawing_elements';

  // ---- Shared columns (all types) ----------------------------------------
  IntColumn get accountNumber =>
      integer().withDefault(const Constant(1)).named('account_number')();
  TextColumn get id => text().withLength(min: 1, max: 64)();
  TextColumn get type => text().withLength(min: 1, max: 16)();
  IntColumn get color => integer()();
  RealColumn get strokeWidth => real()();
  RealColumn get positionX => real()();
  RealColumn get positionY => real()();
  IntColumn get zIndex => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();
  TextColumn get geometryJson => text()();

  // ---- Type-specific denormalised fast-path columns ----------------------
  // RectElement
  RealColumn get rectWidth => real().nullable().named('rect_width')();
  RealColumn get rectHeight => real().nullable().named('rect_height')();

  // LineElement
  RealColumn get lineEndX => real().nullable().named('line_end_x')();
  RealColumn get lineEndY => real().nullable().named('line_end_y')();

  // StrokeElement Bounding Box
  RealColumn get strokeMinX => real().nullable().named('stroke_min_x')();
  RealColumn get strokeMinY => real().nullable().named('stroke_min_y')();
  RealColumn get strokeMaxX => real().nullable().named('stroke_max_x')();
  RealColumn get strokeMaxY => real().nullable().named('stroke_max_y')();

  @override
  Set<Column> get primaryKey => {accountNumber, id};
}
