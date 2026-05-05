import '../entities/collab_playlist.dart';

class CollabEngine {
  /// Merges two collab playlists using CRDT rules:
  /// - addTrack + addTrack (same track) → deduplicate, keep one
  /// - removeTrack wins over addTrack if timestamp is later
  /// - reorder conflicts → last-write-wins by timestamp
  /// - rename → last-write-wins by timestamp
  CollabPlaylist merge(CollabPlaylist local, List<CollabEdit> remoteEdits) {
    // 1. Combine and sort all edits by timestamp
    final allEdits = [...local.editLog, ...remoteEdits];
    allEdits.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    // 2. Re-play all edits to build the final state
    String currentName = local.name;
    final List<CollabTrack> currentTracks = [];
    final Map<String, CollabEdit> latestReorders = {};

    for (final edit in allEdits) {
      switch (edit.type) {
        case CollabEditType.addTrack:
          final trackId = edit.payload['trackId'] as String;
          if (!currentTracks.any((t) => t.trackId == trackId)) {
            currentTracks.add(CollabTrack(
              trackId: trackId,
              addedByUserId: edit.userId,
              addedAt: edit.timestamp,
              position: currentTracks.length,
            ));
          }
          break;
        case CollabEditType.removeTrack:
          final trackId = edit.payload['trackId'] as String;
          currentTracks.removeWhere((t) => t.trackId == trackId);
          break;
        case CollabEditType.reorder:
          final trackId = edit.payload['trackId'] as String;
          // Last-write-wins for reorder
          latestReorders[trackId] = edit;
          break;
        case CollabEditType.rename:
          currentName = edit.payload['name'] as String;
          break;
      }
    }

    // 3. Apply latest reorders
    for (final trackId in latestReorders.keys) {
      final edit = latestReorders[trackId]!;
      final idx = currentTracks.indexWhere((t) => t.trackId == trackId);
      if (idx != -1) {
        final track = currentTracks.removeAt(idx);
        final targetPos = (edit.payload['position'] as int).clamp(0, currentTracks.length);
        currentTracks.insert(targetPos, track);
      }
    }

    // 4. Normalize positions
    final normalizedTracks = <CollabTrack>[];
    for (int i = 0; i < currentTracks.length; i++) {
      normalizedTracks.add(CollabTrack(
        trackId: currentTracks[i].trackId,
        addedByUserId: currentTracks[i].addedByUserId,
        addedAt: currentTracks[i].addedAt,
        position: i,
      ));
    }

    return CollabPlaylist(
      id: local.id,
      name: currentName,
      ownerIds: local.ownerIds,
      tracks: normalizedTracks,
      editLog: _deduplicateEdits(allEdits),
      lastSyncedAt: DateTime.now(),
      contentHash: _computeHash(normalizedTracks),
    );
  }

  List<CollabEdit> _deduplicateEdits(List<CollabEdit> edits) {
    final Map<String, CollabEdit> unique = {};
    for (final e in edits) {
      unique[e.editId] = e;
    }
    return unique.values.toList()..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }

  String _computeHash(List<CollabTrack> tracks) {
    // Simplified hash: just join IDs
    return tracks.map((t) => t.trackId).join(',');
  }
}
