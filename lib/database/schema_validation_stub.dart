import 'package:drift/drift.dart';

class SchemaMismatch implements Exception {}

extension VerifySelf on GeneratedDatabase {
  Future<void> validateDatabaseSchema() async {
    // No-op on web
  }
}
