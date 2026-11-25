import 'package:drift/native.dart';
import 'package:excellium_storage_drift/excellium_storage_drift.dart';
import 'package:excellium_store_contract/excellium_store_contract.dart';

void main() {
  runStoreContractTests(
    'Drift (SQLite en mémoire)',
    () => DriftStore(NativeDatabase.memory()),
  );
}
