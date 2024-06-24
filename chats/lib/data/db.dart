import 'package:stormberry/stormberry.dart';

late Database db;

void initDatabase() {
  db = Database();
  db.debugPrint = true;
  db.open();
}
