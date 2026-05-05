import 'package:equatable/equatable.dart';

class CollabPlaylist extends Equatable {
  final String id;
  final String name;
  final List<String> ownerIds; // all collaborators
  final List<CollabTrack> tracks;
  final List<CollabEdit> editLog; // append-only operation log (CRDT-like)
  final DateTime lastSyncedAt;
  final String contentHash; // SHA256 of current track list for diff detection

  const CollabPlaylist({
    required this.id,
    required this.name,
    required this.ownerIds,
    required this.tracks,
    required this.editLog,
    required this.lastSyncedAt,
    required this.contentHash,
  });

  @override
  List<Object?> get props => [id, name, ownerIds, tracks, editLog, lastSyncedAt, contentHash];
}

class CollabTrack extends Equatable {
  final String trackId;
  final String addedByUserId;
  final DateTime addedAt;
  final int position;

  const CollabTrack({
    required this.trackId,
    required this.addedByUserId,
    required this.addedAt,
    required this.position,
  });

  @override
  List<Object?> get props => [trackId, addedByUserId, addedAt, position];
}

enum CollabEditType { addTrack, removeTrack, reorder, rename }

class CollabEdit extends Equatable {
  final String editId; // UUID
  final String userId;
  final CollabEditType type;
  final Map<String, dynamic> payload;
  final DateTime timestamp;

  const CollabEdit({
    required this.editId,
    required this.userId,
    required this.type,
    required this.payload,
    required this.timestamp,
  });

  @override
  List<Object?> get props => [editId, userId, type, payload, timestamp];
}
