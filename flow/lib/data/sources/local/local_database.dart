import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'local_database.g.dart';

@DataClassName('TrackEntity')
class Tracks extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get artist => text()();
  TextColumn get artistId => text()();
  TextColumn get album => text().nullable()();
  TextColumn get albumId => text().nullable()();
  TextColumn get year => text().nullable()();
  TextColumn get genres => text().nullable()(); // JSON array
  TextColumn get tags => text().nullable()(); // JSON array
  TextColumn get youtubeId => text().nullable()();
  TextColumn get ytmBrowseId => text().nullable()();
  TextColumn get spotifyId => text().nullable()();
  TextColumn get sourceChannelId => text().nullable()();
  TextColumn get artworkUrl => text().nullable()();
  TextColumn get localArtworkPath => text().nullable()();
  RealColumn get bpm => real().nullable()();
  RealColumn get energy => real().nullable()();
  RealColumn get danceability => real().nullable()();
  TextColumn get key => text().nullable()();
  TextColumn get mode => text().nullable()();
  IntColumn get playCount => integer().withDefault(const Constant(0))();
  IntColumn get skipCount => integer().withDefault(const Constant(0))();
  IntColumn get replayCount => integer().withDefault(const Constant(0))();
  IntColumn get lastPlayed => integer().nullable()(); // timestamp
  BoolColumn get liked => boolean().withDefault(const Constant(false))();
  BoolColumn get downloaded => boolean().withDefault(const Constant(false))();
  TextColumn get downloadedPath => text().nullable()();
  BoolColumn get cachedAudio => boolean().withDefault(const Constant(false))();
  RealColumn get graphScore => real().withDefault(const Constant(0.0))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('ListenEventEntity')
class ListenEvents extends Table {
  TextColumn get id => text()(); // UUID
  TextColumn get trackId => text()();
  TextColumn get eventType => text()();
  IntColumn get timestamp => integer()();
  IntColumn get listenDurationSeconds => integer().nullable()();
  TextColumn get sourceUserId => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('GraphNodeEntity')
class GraphNodes extends Table {
  TextColumn get id => text()();
  TextColumn get nodeType => text()();
  RealColumn get score => real().withDefault(const Constant(0.0))();
  IntColumn get lastUpdated => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('GraphEdgeEntity')
class GraphEdges extends Table {
  TextColumn get fromId => text()();
  TextColumn get toId => text()();
  RealColumn get weight => real().withDefault(const Constant(0.1))();

  @override
  Set<Column> get primaryKey => {fromId, toId};
}

@DataClassName('PlaylistEntity')
class Playlists extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get description => text().nullable()();
  IntColumn get createdAt => integer().nullable()();
  TextColumn get type => text().nullable()(); // local | yt | spotify | collab | auto
  TextColumn get sourceId => text().nullable()(); // remote ID
  TextColumn get ownerIds => text().nullable()(); // JSON array

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('PlaylistTrackEntity')
class PlaylistTracks extends Table {
  TextColumn get playlistId => text()();
  TextColumn get trackId => text()();
  IntColumn get position => integer()();
  TextColumn get addedBy => text().nullable()();
  IntColumn get addedAt => integer().nullable()();

  @override
  Set<Column> get primaryKey => {playlistId, trackId};
}

@DataClassName('PeerEntity')
class Peers extends Table {
  TextColumn get peerId => text()();
  TextColumn get displayName => text()();
  TextColumn get relation => text()(); // sameUser | otherUser
  TextColumn get publicKey => text()();
  TextColumn get shareLevel => text().nullable()();
  IntColumn get lastSeen => integer().nullable()();
  TextColumn get lastKnownIp => text().nullable()();
  TextColumn get bleAddress => text().nullable()();
  TextColumn get permissions => text().nullable()(); // JSON
  TextColumn get graphDataBlob => text().nullable()();
  IntColumn get lastSyncTime => integer().nullable()();

  @override
  Set<Column> get primaryKey => {peerId};
}

@DataClassName('CollabEditEntity')
class CollabEdits extends Table {
  TextColumn get editId => text()();
  TextColumn get playlistId => text()();
  TextColumn get userId => text()();
  TextColumn get editType => text()();
  TextColumn get payload => text()(); // JSON
  IntColumn get timestamp => integer()();
  BoolColumn get applied => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {editId};
}

@DriftDatabase(tables: [Tracks, ListenEvents, GraphNodes, GraphEdges, Playlists, PlaylistTracks, Peers, CollabEdits])
class LocalDatabase extends _$LocalDatabase {


  LocalDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'flow.sqlite'));
    return NativeDatabase(file);
  });
}
