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

  factory GraphDelta.fromJson(Map<String, dynamic> json) => GraphDelta(
    peerId: json['peerId'] as String,
    from: DateTime.fromMillisecondsSinceEpoch(json['from'] as int),
    to: DateTime.fromMillisecondsSinceEpoch(json['to'] as int),
    nodeUpdates: (json['nodeUpdates'] as List).map((e) => NodeDelta.fromJson(e as Map<String, dynamic>)).toList(),
    edgeUpdates: (json['edgeUpdates'] as List).map((e) => EdgeDelta.fromJson(e as Map<String, dynamic>)).toList(),
    events: (json['events'] as List).cast<Map<String, dynamic>>(),
  );

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

  factory NodeDelta.fromJson(Map<String, dynamic> json) => NodeDelta(
    id: json['id'] as String,
    scoreDelta: (json['scoreDelta'] as num).toDouble(),
    type: NodeType.values.firstWhere((e) => e.name == json['type']),
    lastUpdated: DateTime.fromMillisecondsSinceEpoch(json['lastUpdated'] as int),
  );

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

  factory EdgeDelta.fromJson(Map<String, dynamic> json) => EdgeDelta(
    fromId: json['fromId'] as String,
    toId: json['toId'] as String,
    weightDelta: (json['weightDelta'] as num).toDouble(),
  );

  Map<String, dynamic> toJson() => {
    'fromId': fromId,
    'toId': toId,
    'weightDelta': weightDelta,
  };
}
