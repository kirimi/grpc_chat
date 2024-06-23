import 'package:stormberry/stormberry.dart';

late Database db;

Database initDatabase() => Database(
    username: 'kirimi',
    password: 'kirimi',
    port: 4500,
    useSSL: false,
  );
