import '../entities/drawing_account_summary.dart';
import '../entities/drawing_element.dart';

// ---------------------------------------------------------------------------
// DrawingRepository — Domain-layer contract for persistence.
//
// This is a pure Dart abstract class. It has NO dependencies on Flutter,
// SQLite, or any infrastructure concern. The Data layer provides
// the concrete implementation (DrawingRepositoryImpl).
//
// DESIGN NOTE — "Document" vs "Scene":
//   All elements in a given run belong to a single "document". If multi-
//   document support is added later, add a [documentId] parameter to each
//   method signature without changing the domain entities.
// ---------------------------------------------------------------------------
abstract interface class DrawingRepository {
  // ---- Accounts -----------------------------------------------------------

  /// Currently selected local account number. All reads and writes are scoped
  /// to this account.
  int get activeAccountNumber;

  /// Switch the repository to a local account number.
  Future<void> useAccount(int accountNumber);

  /// Return all local account numbers with their element and color counts.
  Future<List<DrawingAccountSummary>> loadAccountSummaries();

  // ---- Read ---------------------------------------------------------------

  /// Load every persisted [DrawingElement] ordered by [zIndex] ascending.
  /// Returns an empty list when the document is blank (never throws on empty).
  Future<List<DrawingElement>> loadAll();

  /// Fetch a single element by [id]. Returns null if not found.
  Future<DrawingElement?> findById(String id);

  // ---- Write --------------------------------------------------------------

  /// Persist a new element. Throws [DuplicateElementException] if [id] exists.
  Future<void> insert(DrawingElement element);

  /// Upsert: inserts if the element does not exist, updates if it does.
  /// Prefer this for undo/redo replay to avoid order-sensitive logic.
  Future<void> upsert(DrawingElement element);

  /// Replace an existing element (same id, possibly different geometry/style).
  /// Throws [ElementNotFoundException] if the id is not found.
  Future<void> update(DrawingElement element);

  /// Batch-update a list of elements in a single DB transaction.
  /// Useful for bulk moves (multi-select drag).
  Future<void> updateAll(List<DrawingElement> elements);

  /// Remove an element by [id].
  /// Throws [ElementNotFoundException] if the id is not found.
  Future<void> delete(String id);

  /// Remove all elements (clear canvas). Irreversible at the DB level;
  /// call only after confirming in the BLoC / undo stack.
  Future<void> deleteAll();

  // ---- Ordering -----------------------------------------------------------

  /// Reorder elements by assigning new [zIndex] values.
  /// [orderedIds] must contain the same ids that are currently persisted —
  /// the implementation assigns zIndex = list position.
  Future<void> reorder(List<String> orderedIds);

  // ---- Streams (optional reactive layer) ----------------------------------

  /// Emits the full updated list whenever the scene changes.
  /// Implementations backed by local persistence emit after each scene change.
  Stream<List<DrawingElement>> watchAll();
}

// ---------------------------------------------------------------------------
// Repository exceptions
// ---------------------------------------------------------------------------

class ElementNotFoundException implements Exception {
  final String id;
  const ElementNotFoundException(this.id);
  @override
  String toString() => 'ElementNotFoundException: No element with id "$id"';
}

class DuplicateElementException implements Exception {
  final String id;
  const DuplicateElementException(this.id);
  @override
  String toString() =>
      'DuplicateElementException: Element with id "$id" already exists';
}
