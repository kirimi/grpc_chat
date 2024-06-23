import 'package:stormberry/stormberry.dart';

late Database db;

void initDatabase() {
  db = Database(
    username: 'kirimi',
    password: 'kirimi',
    port: 4500,
    useSSL: false,
  );
  db.debugPrint = true;
  db.open();
}
