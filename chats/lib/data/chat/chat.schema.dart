// ignore_for_file: annotate_overrides

part of 'chat.dart';

extension ChatRepositories on Session {
  ChatRepository get chats => ChatRepository._(this);
}

abstract class ChatRepository
    implements
        ModelRepository,
        KeyedModelRepositoryInsert<ChatInsertRequest>,
        ModelRepositoryUpdate<ChatUpdateRequest>,
        ModelRepositoryDelete<int> {
  factory ChatRepository._(Session db) = _ChatRepository;

  Future<ShortChatView?> queryShortView(int id);
  Future<List<ShortChatView>> queryShortViews([QueryParams? params]);
  Future<FullChatView?> queryFullView(int id);
  Future<List<FullChatView>> queryFullViews([QueryParams? params]);
}

class _ChatRepository extends BaseRepository
    with
        KeyedRepositoryInsertMixin<ChatInsertRequest>,
        RepositoryUpdateMixin<ChatUpdateRequest>,
        RepositoryDeleteMixin<int>
    implements ChatRepository {
  _ChatRepository(super.db) : super(tableName: 'chats', keyName: 'id');

  @override
  Future<ShortChatView?> queryShortView(int id) {
    return queryOne(id, ShortChatViewQueryable());
  }

  @override
  Future<List<ShortChatView>> queryShortViews([QueryParams? params]) {
    return queryMany(ShortChatViewQueryable(), params);
  }

  @override
  Future<FullChatView?> queryFullView(int id) {
    return queryOne(id, FullChatViewQueryable());
  }

  @override
  Future<List<FullChatView>> queryFullViews([QueryParams? params]) {
    return queryMany(FullChatViewQueryable(), params);
  }

  @override
  Future<List<int>> insert(List<ChatInsertRequest> requests) async {
    if (requests.isEmpty) return [];
    var values = QueryValues();
    var rows = await db.execute(
      Sql.named('INSERT INTO "chats" ( "name", "author_id" )\n'
          'VALUES ${requests.map((r) => '( ${values.add(r.name)}:text, ${values.add(r.authorId)}:text )').join(', ')}\n'
          'RETURNING "id"'),
      parameters: values.values,
    );
    var result = rows.map<int>((r) => TextEncoder.i.decode(r.toColumnMap()['id'])).toList();

    return result;
  }

  @override
  Future<void> update(List<ChatUpdateRequest> requests) async {
    if (requests.isEmpty) return;
    var values = QueryValues();
    await db.execute(
      Sql.named('UPDATE "chats"\n'
          'SET "name" = COALESCE(UPDATED."name", "chats"."name"), "author_id" = COALESCE(UPDATED."author_id", "chats"."author_id")\n'
          'FROM ( VALUES ${requests.map((r) => '( ${values.add(r.id)}:int8::int8, ${values.add(r.name)}:text::text, ${values.add(r.authorId)}:text::text )').join(', ')} )\n'
          'AS UPDATED("id", "name", "author_id")\n'
          'WHERE "chats"."id" = UPDATED."id"'),
      parameters: values.values,
    );
  }
}

class ChatInsertRequest {
  ChatInsertRequest({
    required this.name,
    required this.authorId,
  });

  final String name;
  final String authorId;
}

class ChatUpdateRequest {
  ChatUpdateRequest({
    required this.id,
    this.name,
    this.authorId,
  });

  final int id;
  final String? name;
  final String? authorId;
}

class ShortChatViewQueryable extends KeyedViewQueryable<ShortChatView, int> {
  @override
  String get keyName => 'id';

  @override
  String encodeKey(int key) => TextEncoder.i.encode(key);

  @override
  String get query => 'SELECT "chats".*'
      'FROM "chats"';

  @override
  String get tableAlias => 'chats';

  @override
  ShortChatView decode(TypedMap map) =>
      ShortChatView(id: map.get('id'), name: map.get('name'), authorId: map.get('author_id'));
}

class ShortChatView {
  ShortChatView({
    required this.id,
    required this.name,
    required this.authorId,
  });

  final int id;
  final String name;
  final String authorId;
}

class FullChatViewQueryable extends KeyedViewQueryable<FullChatView, int> {
  @override
  String get keyName => 'id';

  @override
  String encodeKey(int key) => TextEncoder.i.encode(key);

  @override
  String get query => 'SELECT "chats".*, "messages"."data" as "messages"'
      'FROM "chats"'
      'LEFT JOIN ('
      '  SELECT "messages"."chat_id",'
      '    to_jsonb(array_agg("messages".*)) as data'
      '  FROM (${MessageViewQueryable().query}) "messages"'
      '  GROUP BY "messages"."chat_id"'
      ') "messages"'
      'ON "chats"."id" = "messages"."chat_id"';

  @override
  String get tableAlias => 'chats';

  @override
  FullChatView decode(TypedMap map) => FullChatView(
      id: map.get('id'),
      name: map.get('name'),
      authorId: map.get('author_id'),
      messages: map.getListOpt('messages', MessageViewQueryable().decoder) ?? const []);
}

class FullChatView {
  FullChatView({
    required this.id,
    required this.name,
    required this.authorId,
    required this.messages,
  });

  final int id;
  final String name;
  final String authorId;
  final List<MessageView> messages;
}
