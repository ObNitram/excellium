import 'package:excellium_core/memory.dart';
import 'package:excellium_store_contract/excellium_store_contract.dart';

void main() {
  runStoreContractTests('mémoire', InMemoryStore.new);
}
