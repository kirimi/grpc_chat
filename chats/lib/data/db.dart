import 'package:stormberry/stormberry.dart';

late Database db;

void initDatabase() {
  db = Database(
    host: 'localhost',
    port: 4501,
    useSSL: false,
    username: 'kirimi',
    password: 'kirimi',
  );
  db.debugPrint = true;
  db.open();
}
