import 'package:equatable/equatable.dart';

enum PeerRelation { sameUser, otherUser }

class DevicePeer extends Equatable {
  final String peerId; // UUID, stable across sessions
  final String displayName; // "My Android"
  final PeerRelation relation; // sameUser | otherUser
  final String publicKey; // X25519 for E2E encryption
  final DateTime lastSeen;
  final String? lastKnownIp;
  final String? bleAddress;
  final SyncPermissions permissions; // what this peer is allowed to sync

  const DevicePeer({
    required this.peerId,
    required this.displayName,
    required this.relation,
    required this.publicKey,
    required this.lastSeen,
    this.lastKnownIp,
    this.bleAddress,
    required this.permissions,
  });

  @override
  List<Object?> get props => [
        peerId,
        displayName,
        relation,
        publicKey,
        lastSeen,
        lastKnownIp,
        bleAddress,
        permissions,
      ];

  DevicePeer copyWith({
    String? displayName,
    PeerRelation? relation,
    String? publicKey,
    DateTime? lastSeen,
    String? lastKnownIp,
    String? bleAddress,
    SyncPermissions? permissions,
  }) {
    return DevicePeer(
      peerId: peerId,
      displayName: displayName ?? this.displayName,
      relation: relation ?? this.relation,
      publicKey: publicKey ?? this.publicKey,
      lastSeen: lastSeen ?? this.lastSeen,
      lastKnownIp: lastKnownIp ?? this.lastKnownIp,
      bleAddress: bleAddress ?? this.bleAddress,
      permissions: permissions ?? this.permissions,
    );
  }
}

class SyncPermissions extends Equatable {
  final bool streamAudio; // can this device request audio from us?
  final bool syncListenHistory;
  final bool syncGraphScores;
  final bool syncCollabPlaylists;

  const SyncPermissions({
    this.streamAudio = true,
    this.syncListenHistory = true,
    this.syncGraphScores = true,
    this.syncCollabPlaylists = true,
  });

  @override
  List<Object?> get props => [
        streamAudio,
        syncListenHistory,
        syncGraphScores,
        syncCollabPlaylists,
      ];
}
