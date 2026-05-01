import 'dart:math';

enum NodeType { track, artist, album, genre, tag, creator }

class GraphNode {
  final String id;
  final NodeType type;
  double score;
  DateTime lastUpdated;

  GraphNode({
    required this.id,
    required this.type,
    this.score = 0.0,
    DateTime? lastUpdated,
  }) : lastUpdated = lastUpdated ?? DateTime.now();
}

class GraphEdge {
  final String fromId;
  final String toId;
  double weight;

  GraphEdge({
    required this.fromId,
    required this.toId,
    this.weight = 1.0,
  });
}

enum ListenEvent {
  fullListen, // +1.0
  replay, // +2.0
  liked, // +3.0
  downloaded, // +2.5
  addedToList, // +1.5
  skippedMid, // −0.3
  skippedEarly, // −0.8
}

extension ListenEventWeight on ListenEvent {
  double get weight => switch (this) {
        ListenEvent.fullListen => 1.0,
        ListenEvent.replay => 2.0,
        ListenEvent.liked => 3.0,
        ListenEvent.downloaded => 2.5,
        ListenEvent.addedToList => 1.5,
        ListenEvent.skippedMid => -0.3,
        ListenEvent.skippedEarly => -0.8,
      };
}

class ScoringGraph {
  final Map<String, GraphNode> nodes = {};
  final Map<String, List<GraphEdge>> adjacency = {};

  void recordEvent(String trackId, ListenEvent event, {
    required String artistId,
    String? albumId,
    String? creatorId,
    List<String> genres = const [],
    List<String> tags = const [],
  }) {
    final delta = event.weight;

    // track   × 1.0
    _updateNode(trackId, NodeType.track, delta * 1.0);
    
    // artist  × 0.7
    _updateNode('artist:$artistId', NodeType.artist, delta * 0.7);
    
    // album   × 0.5
    if (albumId != null) {
      _updateNode('album:$albumId', NodeType.album, delta * 0.5);
    }
    
    // creator × 0.5
    if (creatorId != null) {
      _updateNode('creator:$creatorId', NodeType.creator, delta * 0.5);
    }
    
    // genres  × 0.4  (each)
    for (final genre in genres) {
      _updateNode('genre:$genre', NodeType.genre, delta * 0.4);
    }
    
    // tags    × 0.3  (each)
    for (final tag in tags) {
      _updateNode('tag:$tag', NodeType.tag, delta * 0.3);
    }

    // Update edges (simplified for now: link track to its attributes)
    _addEdge(trackId, 'artist:$artistId', 0.7);
    if (albumId != null) _addEdge(trackId, 'album:$albumId', 0.5);
    for (final genre in genres) _addEdge(trackId, 'genre:$genre', 0.4);
    for (final tag in tags) _addEdge(trackId, 'tag:$tag', 0.3);

  }

  void _updateNode(String id, NodeType type, double delta) {
    final node = nodes[id] ??= GraphNode(id: id, type: type);
    final ageDays = DateTime.now().difference(node.lastUpdated).inDays;
    
    // 3% decay per day — recent listens dominate
    node.score = (node.score * pow(0.97, max(0, ageDays))) + delta;
    node.lastUpdated = DateTime.now();
  }

  void _addEdge(String fromId, String toId, double weight) {
    final edges = adjacency[fromId] ??= [];
    if (!edges.any((e) => e.toId == toId)) {
      edges.add(GraphEdge(fromId: fromId, toId: toId, weight: weight));
    }
    // Bidirectional for some types?
    final backEdges = adjacency[toId] ??= [];
    if (!backEdges.any((e) => e.toId == fromId)) {
      backEdges.add(GraphEdge(fromId: toId, toId: fromId, weight: weight));
    }
  }

  List<GraphNode> recommend(String seedId, {int n = 20}) {
    final visited = <String>{seedId};
    final queue = [seedId];
    final results = <GraphNode>[];

    var head = 0;
    while (head < queue.length && results.length < n * 3) {
      final current = queue[head++];
      for (final edge in (adjacency[current] ?? [])) {
        if (!visited.contains(edge.toId)) {
          visited.add(edge.toId);
          final node = nodes[edge.toId];
          if (node != null) {
            results.add(node);
            queue.add(edge.toId);
          }
        }
      }
    }
    
    results.sort((a, b) => b.score.compareTo(a.score));
    return results.take(n).toList();
  }
}
