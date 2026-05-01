import 'scoring_graph.dart';

class GraphDelta {
  final String peerId;
  final DateTime from;
  final DateTime to;
  final List<NodeDelta> nodeUpdates;
  final List<EdgeDelta> edgeUpdates;
  final List<Map<String, dynamic>> events;

  GraphDelta({
    required this.peerId,
    required this.from,
    required this.to,
    required this.nodeUpdates,
    required this.edgeUpdates,
    required this.events,
  });

  Map<String, dynamic> toJson() => {
    'peerId': peerId,
    'from': from.millisecondsSinceEpoch,
    'to': to.millisecondsSinceEpoch,
    'nodeUpdates': nodeUpdates.map((e) => e.toJson()).toList(),
    'edgeUpdates': edgeUpdates.map((e) => e.toJson()).toList(),
    'events': events,
  };
}

class NodeDelta {
  final String id;
  final double scoreDelta;
  final NodeType type;
  final DateTime lastUpdated;

  NodeDelta({
    required this.id,
    required this.scoreDelta,
    required this.type,
    required this.lastUpdated,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'scoreDelta': scoreDelta,
    'type': type.name,
    'lastUpdated': lastUpdated.millisecondsSinceEpoch,
  };
}

class EdgeDelta {
  final String fromId;
  final String toId;
  final double weightDelta;

  EdgeDelta({
    required this.fromId,
    required this.toId,
    required this.weightDelta,
  });

  Map<String, dynamic> toJson() => {
    'fromId': fromId,
    'toId': toId,
    'weightDelta': weightDelta,
  };
}
