import '../entities/graph_delta.dart';
import '../entities/scoring_graph.dart';
import '../../core/intelligence/app_intelligence.dart';

class SyncEngine {
  final ScoringGraph graph;

  SyncEngine({required this.graph});

  // Produce a delta since last sync with this peer
  GraphDelta buildDelta(String localDeviceId, DateTime lastSync) {
    final now = DateTime.now();
    
    final nodeUpdates = <NodeDelta>[];
    for (final node in graph.nodes.values) {
      if (node.lastUpdated.isAfter(lastSync)) {
        nodeUpdates.add(NodeDelta(
          id: node.id,
          scoreDelta: node.score, // Simple implementation: send full score
          type: node.type,
          lastUpdated: node.lastUpdated,
        ));
      }
    }

    final edgeUpdates = <EdgeDelta>[];
    // Simplified: edges are less frequent to update
    
    return GraphDelta(
      peerId: localDeviceId,
      from: lastSync,
      to: now,
      nodeUpdates: nodeUpdates,
      edgeUpdates: edgeUpdates,
      events: [], // To be implemented with ListenEvents table
    );
  }

  // Apply a received delta — merge, don't overwrite
  void applyDelta(GraphDelta delta) {
    for (final n in delta.nodeUpdates) {
      final localNode = graph.nodes[n.id];
      if (localNode == null) {
        graph.nodes[n.id] = GraphNode(
          id: n.id,
          type: n.type,
          score: n.scoreDelta,
          lastUpdated: n.lastUpdated,
        );
      } else {
        // Take the max of local and remote score (conservative merge)
        if (n.lastUpdated.isAfter(localNode.lastUpdated)) {
          localNode.score = n.scoreDelta;
          localNode.lastUpdated = n.lastUpdated;
        }
      }
    }
    
    // After applying, we should notify the persistence layer to save
    // AppIntelligence.instance.persistGraph();
  }
}
