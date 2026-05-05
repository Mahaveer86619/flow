import 'dart:convert';
import 'package:cryptography/cryptography.dart';
import 'package:drift/drift.dart';
import '../../data/sources/local/local_database.dart';
import '../../domain/entities/device_peer.dart';
import '../logger/app_logger.dart';

class PeerManager {
  PeerManager._();
  static final PeerManager instance = PeerManager._();

  final LocalDatabase _db = LocalDatabase();
  static const _tag = 'PeerManager';

  final List<DevicePeer> _peers = [];
  List<DevicePeer> get peers => List.unmodifiable(_peers);

  KeyPair? _keyPair;
  String? _publicKeyBase64;

  Future<void> init() async {
    await loadPeers();
    await _initKeys();
    AppLogger.i(_tag, 'Initialised with ${_peers.length} peers');
  }

  Future<void> _initKeys() async {
    final algorithm = X25519();
    _keyPair = await algorithm.newKeyPair();
    final publicKey = await _keyPair!.extractPublicKey();
    if (publicKey is SimplePublicKey) {
      _publicKeyBase64 = base64Encode(publicKey.bytes);
      AppLogger.d(_tag, 'Local public key generated');
    }
  }


  String get localPublicKey => _publicKeyBase64 ?? '';

  Future<void> loadPeers() async {
    try {
      final entities = await _db.select(_db.peers).get();
      _peers.clear();
      for (final e in entities) {
        _peers.add(_mapEntityToPeer(e));
      }
    } catch (e) {
      AppLogger.e(_tag, 'Failed to load peers', e);
    }
  }

  Future<void> savePeer(DevicePeer peer) async {
    try {
      await _db.into(_db.peers).insertOnConflictUpdate(
        PeersCompanion.insert(
          peerId: peer.peerId,
          displayName: peer.displayName,
          relation: peer.relation.name,
          publicKey: peer.publicKey,
          lastSeen: Value(peer.lastSeen.millisecondsSinceEpoch),
          lastKnownIp: Value(peer.lastKnownIp),
          bleAddress: Value(peer.bleAddress),
          permissions: Value(jsonEncode({
            'streamAudio': peer.permissions.streamAudio,
            'syncListenHistory': peer.permissions.syncListenHistory,
            'syncGraphScores': peer.permissions.syncGraphScores,
            'syncCollabPlaylists': peer.permissions.syncCollabPlaylists,
          })),
        ),
      );
      await loadPeers();
    } catch (e) {
      AppLogger.e(_tag, 'Failed to save peer', e);
    }
  }

  DevicePeer? getActivePeer() {
    // For now, return the first online peer found on LAN
    if (_peers.isEmpty) return null;
    return _peers.firstWhere((p) => p.lastKnownIp != null, orElse: () => _peers.first);
  }

  String generatePairingData() {
    return jsonEncode({
      'v': 1,
      'id': 'flow-${localPublicKey.hashCode}',
      'name': 'My Device',
      'key': localPublicKey,
    });
  }

  Future<void> pairWithDevice(String pairingJson) async {
    try {
      final data = jsonDecode(pairingJson) as Map<String, dynamic>;
      if (data['v'] != 1) throw Exception('Unsupported pairing version');

      final peer = DevicePeer(
        peerId: data['id'] as String,
        displayName: data['name'] as String,
        relation: PeerRelation.sameUser,
        publicKey: data['key'] as String,
        lastSeen: DateTime.now(),
        permissions: const SyncPermissions(),
      );

      await savePeer(peer);
      AppLogger.i(_tag, 'Paired with device: ${peer.displayName}');
    } catch (e) {
      AppLogger.e(_tag, 'Pairing failed', e);
      rethrow;
    }
  }

  DevicePeer _mapEntityToPeer(PeerEntity e) {
    final permsJson = e.permissions != null ? jsonDecode(e.permissions!) as Map<String, dynamic> : {};
    return DevicePeer(
      peerId: e.peerId,
      displayName: e.displayName,
      relation: e.relation == 'sameUser' ? PeerRelation.sameUser : PeerRelation.otherUser,
      publicKey: e.publicKey,
      lastSeen: e.lastSeen != null ? DateTime.fromMillisecondsSinceEpoch(e.lastSeen!) : DateTime.now(),
      lastKnownIp: e.lastKnownIp,
      bleAddress: e.bleAddress,
      permissions: SyncPermissions(
        streamAudio: permsJson['streamAudio'] ?? true,
        syncListenHistory: permsJson['syncListenHistory'] ?? true,
        syncGraphScores: permsJson['syncGraphScores'] ?? true,
        syncCollabPlaylists: permsJson['syncCollabPlaylists'] ?? true,
      ),
    );
  }
}
