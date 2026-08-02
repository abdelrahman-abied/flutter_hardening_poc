// Article 8 — executes the injection against a real in-memory SQLite database.
// Nothing here is simulated: the vulnerable query genuinely returns another
// user's row, and the parameterized one genuinely does not.

import 'package:flutter_test/flutter_test.dart';
import 'package:hardening_poc/services/sql_injection_demo.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late Database db;

  setUpAll(() {
    sqfliteFfiInit();
  });

  setUp(() async {
    db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    await SqlInjectionDemo.seed(db);
  });

  tearDown(() async => db.close());

  test('benign search behaves identically in both versions', () async {
    final v = await SqlInjectionDemo.vulnerable(db, 'gym');
    final s = await SqlInjectionDemo.safe(db, 'gym');
    expect(v.length, 1);
    expect(s.length, 1);
    expect(s.first['title'], 'gym plan');
  });

  test("THE ATTACK: ' OR '1'='1 breaks out of the owner scope", () async {
    final rows = await SqlInjectionDemo.vulnerable(
      db,
      SqlInjectionDemo.classicPayload,
    );

    final owners = rows.map((r) => r['owner']).toSet();
    expect(owners, contains('bob'),
        reason: "amy's query returned bob's row — the input became SQL");
    expect(rows.length, 3, reason: 'the whole table leaked');
  });

  test('the parameterized query refuses the same payload', () async {
    final rows = await SqlInjectionDemo.safe(
      db,
      SqlInjectionDemo.classicPayload,
    );

    expect(rows, isEmpty,
        reason: 'the payload was bound as a literal value, matching no title');
  });

  test('placeholders bind values, not identifiers — ORDER BY needs a list', () {
    expect(SqlInjectionDemo.safeOrderBy('title'), 'title');
    expect(SqlInjectionDemo.safeOrderBy('id; DROP TABLE notes'), 'id',
        reason: 'anything off the allow-list falls back to a safe default');
  });
}
