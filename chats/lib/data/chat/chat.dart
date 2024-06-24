import 'package:chats/data/message/message.dart';
import 'package:stormberry/stormberry.dart';

part 'chat.schema.dart';

@Model()
abstract class Chat{
  @PrimaryKey()
  @AutoIncrement()
  int get id;
  String get name;
  String get authorId;
  List<Message> get messages;
}