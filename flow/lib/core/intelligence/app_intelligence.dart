import '../../domain/entities/scoring_graph.dart' as domain;
import '../../domain/entities/track.dart' as domain;
import '../../domain/entities/song.dart' as domain_song;
import '../../data/sources/local_database.dart' as db;
import '../../domain/repositories/music_repository.dart';
import '../logger/app_logger.dart';
import 'package:drift/drift.dart';
import '../../domain/entities/graph_delta.dart';
import '../../domain/engines/sync_engine.dart';

class AppIntelligence {
  AppIntelligence._();
  static final AppIntelligence instance = AppIntelligence._();

  final db.LocalDatabase _database = db.LocalDatabase();
  final domain.ScoringGraph _graph = domain.ScoringGraph();
  late final SyncEngine _syncEngine;

  Future<void> init() async {
    _syncEngine = SyncEngine(graph: _graph);
    
    // Load graph from DB
    final nodes = await _database.select(_database.graphNodes).get();
    for (final n in nodes) {
      _graph.nodes[n.id] = domain.GraphNode(
        id: n.id,
        type: domain.NodeType.values.firstWhere((e) => e.name == n.nodeType),
        score: n.score,
        lastUpdated: n.lastUpdated != null 
          ? DateTime.fromMillisecondsSinceEpoch(n.lastUpdated!) 
          : DateTime.now(),
      );
    }

    final edges = await _database.select(_database.graphEdges).get();
    for (final e in edges) {
      final adjacency = _graph.adjacency[e.fromId] ??= [];
      adjacency.add(domain.GraphEdge(fromId: e.fromId, toId: e.toId, weight: e.weight));
    }

    // Check for weekly digest (Simplified: if Sunday and hasn't run today)
    final now = DateTime.now();
    if (now.weekday == DateTime.sunday) {
      // TODO: Add persistence for last digest generation date
      // generateWeeklyDigest(repository);
    }
  }

  Future<void> recordEvent(domain.Track track, domain.ListenEvent event) async {
    // Use fingerprint as the unique identifier for the track node in the graph
    // to merge scores between YTM and Local files.
    final trackNodeId = 'track:${track.fingerprint}';

    _graph.recordEvent(
      trackNodeId,
      event,
      artistId: track.artistId,
      albumId: track.albumId,
      creatorId: track.sourceChannelId,
      genres: track.genres,
      tags: track.tags,
    );

    // Persist to DB
    await _persistGraph();
    
    // Also update track behavioral state in DB (using original ID for track table)
    await (_database.update(_database.tracks)..where((t) => t.id.equals(track.id))).write(
      db.TracksCompanion(
        playCount: Value(event == domain.ListenEvent.fullListen ? (track.playCount + 1) : track.playCount),
        skipCount: Value(event == domain.ListenEvent.skippedEarly || event == domain.ListenEvent.skippedMid ? (track.skipCount + 1) : track.skipCount),
        replayCount: Value(event == domain.ListenEvent.replay ? (track.replayCount + 1) : track.replayCount),
        lastPlayed: Value(DateTime.now().millisecondsSinceEpoch),
        liked: Value(event == domain.ListenEvent.liked ? true : track.liked),
        graphScore: Value(_graph.nodes[trackNodeId]?.score ?? 0.0),
      ),
    );
  }

  Future<void> _persistGraph() async {
    await _database.batch((batch) {
      // Upsert nodes
      for (final node in _graph.nodes.values) {
        batch.insert(
          _database.graphNodes,
          db.GraphNodesCompanion.insert(
            id: node.id,
            nodeType: node.type.name,
            score: Value(node.score),
            lastUpdated: Value(node.lastUpdated.millisecondsSinceEpoch),
          ),
          mode: InsertMode.insertOrReplace,
        );
      }
      
      // Upsert edges
      for (final edges in _graph.adjacency.values) {
        for (final edge in edges) {
          batch.insert(
            _database.graphEdges,
            db.GraphEdgesCompanion.insert(
              fromId: edge.fromId,
              toId: edge.toId,
              weight: Value(edge.weight),
            ),
            mode: InsertMode.insertOrReplace,
          );
        }
      }
    });
  }

  domain.ScoringGraph get graph => _graph;

  // ── Sync Methods ──────────────────────────────────────────────────────────

  Future<GraphDelta> getDeltaForPeer(String peerId) async {
    // TODO: Get last sync time from DB
    final lastSync = DateTime.now().subtract(const Duration(days: 1));
    return _syncEngine.buildDelta('local-device-id', lastSync);
  }

  Future<void> applyDelta(GraphDelta delta) async {
    _syncEngine.applyDelta(delta);
    await _persistGraph();
  }

  // ── Stats Methods ──────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getTopArtists({int limit = 10}) async {
    final query = _database.select(_database.graphNodes)
      ..where((t) => t.nodeType.equals(domain.NodeType.artist.name))
      ..orderBy([(t) => OrderingTerm(expression: t.score, mode: OrderingMode.desc)])
      ..limit(limit);
    
    final nodes = await query.get();
    return nodes.map((n) => {
      'id': n.id.replaceFirst('artist:', ''),
      'score': n.score,
    }).toList();
  }

  Future<List<Map<String, dynamic>>> getTopGenres({int limit = 10}) async {
    final query = _database.select(_database.graphNodes)
      ..where((t) => t.nodeType.equals(domain.NodeType.genre.name))
      ..orderBy([(t) => OrderingTerm(expression: t.score, mode: OrderingMode.desc)])
      ..limit(limit);
    
    final nodes = await query.get();
    return nodes.map((n) => {
      'id': n.id.replaceFirst('genre:', ''),
      'score': n.score,
    }).toList();
  }

  Future<Map<DateTime, int>> getListeningHeatmap({int days = 30}) async {
    final now = DateTime.now();
    final start = now.subtract(Duration(days: days));
    
    final query = _database.select(_database.listenEvents)
      ..where((t) => t.timestamp.isBiggerThanValue(start.millisecondsSinceEpoch));
    
    final events = await query.get();
    final heatmap = <DateTime, int>{};
    
    for (final e in events) {
      final date = DateTime.fromMillisecondsSinceEpoch(e.timestamp);
      final day = DateTime(date.year, date.month, date.day);
      heatmap[day] = (heatmap[day] ?? 0) + 1;
    }
    
    return heatmap;
  }

  // ── Playlist Methods ───────────────────────────────────────────────────────

  Future<void> saveLocalPlaylist(String name, List<String> trackIds) async {
    final id = 'local:${DateTime.now().millisecondsSinceEpoch}';
    await _database.batch((batch) {
      batch.insert(_database.playlists, db.PlaylistsCompanion.insert(
        id: id,
        name: name,
        createdAt: Value(DateTime.now().millisecondsSinceEpoch),
        type: const Value('local'),
      ));

      for (int i = 0; i < trackIds.length; i++) {
        batch.insert(_database.playlistTracks, db.PlaylistTracksCompanion.insert(
          playlistId: id,
          trackId: trackIds[i],
          position: i,
        ));
      }
    });
  }

  // ── Weekly Digest ─────────────────────────────────────────────────────────

  Future<void> generateWeeklyDigest(MusicRepository repository) async {
    AppLogger.i('AppIntelligence', 'Generating Weekly Digest...');
    
    // 1. Get top artists from graph
    final topArtists = await getTopArtists(limit: 5);
    if (topArtists.isEmpty) {
      AppLogger.w('AppIntelligence', 'Not enough data for Weekly Digest');
      return;
    }

    final digestTracks = <String>{};
    
    // 2. Fetch some tracks for each top artist
    for (final artist in topArtists) {
      try {
        final results = await repository.searchSongs(artist['id'], limit: 10);
        for (final song in results) {
          digestTracks.add(song.id);
          if (digestTracks.length >= 30) break;
        }
      } catch (e) {}
      if (digestTracks.length >= 30) break;
    }

    if (digestTracks.isNotEmpty) {
      final dateStr = '${DateTime.now().day}/${DateTime.now().month}';
      await saveLocalPlaylist('Weekly Digest $dateStr', digestTracks.toList());
      AppLogger.i('AppIntelligence', 'Weekly Digest generated with ${digestTracks.length} tracks');
    }
  }
}
