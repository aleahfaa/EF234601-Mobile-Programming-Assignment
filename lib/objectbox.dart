import 'objectbox.g.dart';

class ObjectBox {
  late final Store store;
  ObjectBox._create(this.store);
  static Future<ObjectBox> create() async {
    final store = await openStore(); // dari objectbox.g.dart
    return ObjectBox._create(store);
  }
}
