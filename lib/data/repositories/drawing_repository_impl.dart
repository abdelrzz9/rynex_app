import '../../domain/entities/drawing_account_summary.dart';
import '../../domain/entities/drawing_element.dart';
import '../../domain/repositories/drawing_repository.dart';
import '../datasources/local/dao/drawing_element_dao.dart';
import '../mappers/drawing_element_mapper.dart';

class DrawingRepositoryImpl implements DrawingRepository {
  final DrawingElementDao _dao;

  const DrawingRepositoryImpl(this._dao);

  @override
  int get activeAccountNumber => _dao.activeAccountNumber;

  @override
  Future<void> useAccount(int accountNumber) {
    return _dao.useAccount(accountNumber);
  }

  @override
  Future<List<DrawingAccountSummary>> loadAccountSummaries() {
    return _dao.loadAccountSummaries();
  }

  @override
  Future<List<DrawingElement>> loadAll() async {
    final rows = await _dao.loadAll();
    return rows.map(DrawingElementMapper.toEntity).toList();
  }

  @override
  Future<DrawingElement?> findById(String id) async {
    final row = await _dao.findById(id);
    if (row == null) return null;
    return DrawingElementMapper.toEntity(row);
  }

  @override
  Future<void> insert(DrawingElement element) async {
    try {
      await _dao.insertElement(DrawingElementMapper.toCompanion(element));
    } catch (e) {
      throw DuplicateElementException(element.id);
    }
  }

  @override
  Future<void> upsert(DrawingElement element) async {
    await _dao.upsertElement(DrawingElementMapper.toCompanion(element));
  }

  @override
  Future<void> update(DrawingElement element) async {
    final success = await _dao.updateElement(
      DrawingElementMapper.toCompanion(element),
    );
    if (!success) {
      throw ElementNotFoundException(element.id);
    }
  }

  @override
  Future<void> updateAll(List<DrawingElement> elements) async {
    final companions = elements.map(DrawingElementMapper.toCompanion).toList();
    await _dao.updateAll(companions);
  }

  @override
  Future<void> delete(String id) async {
    final affectedRows = await _dao.deleteById(id);
    if (affectedRows == 0) {
      throw ElementNotFoundException(id);
    }
  }

  @override
  Future<void> deleteAll() async {
    await _dao.deleteAll();
  }

  @override
  Future<void> reorder(List<String> orderedIds) async {
    await _dao.reorder(orderedIds);
  }

  @override
  Stream<List<DrawingElement>> watchAll() {
    return _dao.watchAll().map(
      (rows) => rows.map(DrawingElementMapper.toEntity).toList(),
    );
  }
}
