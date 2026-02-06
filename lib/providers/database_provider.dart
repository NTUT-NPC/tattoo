import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tattoo/database/database.dart';

part 'database_provider.g.dart';

/// Provides the singleton [AppDatabase] instance.
///
/// The database is kept alive for the entire app lifetime.
@Riverpod(keepAlive: true)
AppDatabase database(Ref ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
}
