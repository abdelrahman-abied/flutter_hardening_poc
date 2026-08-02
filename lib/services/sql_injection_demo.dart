// Article 8 — SQL injection in sqflite (CWE-89).
//
// This does not simulate the bug: it executes both queries against a real
// SQLite database and lets the results speak. Works with any sqflite_common
// Database, so the app passes a real one and the tests pass an in-memory
// FFI one.

import 'package:sqflite_common/sqlite_api.dart';

class SqlInjectionDemo {
  /// The payload a user types into an innocent search box.
  ///
  /// Note the shape. The naive `' OR '1'='1` does NOT work here, because `AND`
  /// binds tighter than `OR`: it degrades to
  /// `(owner='amy' AND title LIKE '%') OR ('1'='1%')`, whose right side is a
  /// plain string comparison that is false. This payload closes the LIKE
  /// pattern, adds an always-true disjunct, and comments out the rest:
  ///
  ///   ... AND title LIKE '%%' OR 1=1 --%'
  ///
  /// which collapses to `WHERE (…) OR 1=1` — the whole table.
  static const classicPayload = "%' OR 1=1 --";

  static Future<void> seed(Database db) async {
    await db.execute('DROP TABLE IF EXISTS notes');
    await db.execute(
      'CREATE TABLE notes (id INTEGER PRIMARY KEY, owner TEXT, title TEXT)',
    );
    await db.insert('notes', {'owner': 'amy', 'title': 'grocery list'});
    await db.insert('notes', {'owner': 'amy', 'title': 'gym plan'});
    // The row the attacker must never see.
    await db.insert('notes', {'owner': 'bob', 'title': 'bob salary review'});
  }

  /// THE BUG. `search` is interpolated straight into the SQL text, so the
  /// user's input stops being data and becomes part of the query.
  static Future<List<Map<String, Object?>>> vulnerable(
    Database db,
    String search, {
    String owner = 'amy',
  }) =>
      db.rawQuery(
        "SELECT * FROM notes WHERE owner = '$owner' AND title LIKE '%$search%'",
      );

  /// THE FIX. `?` placeholders bind the input as a VALUE. The query's shape is
  /// fixed before the user's text is ever considered.
  static Future<List<Map<String, Object?>>> safe(
    Database db,
    String search, {
    String owner = 'amy',
  }) =>
      db.rawQuery(
        'SELECT * FROM notes WHERE owner = ? AND title LIKE ?',
        [owner, '%$search%'],
      );

  /// Placeholders bind values, NOT identifiers — so a dynamic ORDER BY needs
  /// an allow-list, exactly like the host allow-list in Article 7.
  static const sortableColumns = <String>{'id', 'owner', 'title'};

  static String safeOrderBy(String requested) =>
      sortableColumns.contains(requested) ? requested : 'id';
}
