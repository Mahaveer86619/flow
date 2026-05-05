import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../../../../core/platform/desktop_controller.dart';
import '../../../../core/network/lan_stream_bridge.dart';
import '../../../../core/network/mdns_service.dart';
import '../../../../core/network/ble_discovery_service.dart';
import '../../../../core/network/peer_manager.dart';
import '../../../../core/intelligence/app_intelligence.dart';
import '../../../../core/app_event_bus.dart';
import '../../../../domain/entities/device_peer.dart';
import '../../../../domain/repositories/music_repository.dart';
import '../../../cubits/settings/settings_cubit.dart';
import '../../../cubits/settings/settings_state.dart';
import 'scan_screen.dart';

class ConnectionsScreen extends StatefulWidget {
  const ConnectionsScreen({super.key});

  @override
  State<ConnectionsScreen> createState() => _ConnectionsScreenState();
}

class _ConnectionsScreenState extends State<ConnectionsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _lanPeers = [];
  List<ScanResult> _blePeers = [];
  bool _isSearching = false;
  StreamSubscription? _bleSub;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _bleSub = BleDiscoveryService.instance.discoveredDevicesStream.listen((results) {
      if (mounted) setState(() => _blePeers = results);
    });
    _searchForPeers();
  }

  @override
  void dispose() {
    _bleSub?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _searchForPeers() async {
    if (_isSearching) return;
    setState(() => _isSearching = true);
    
    final lanPeers = await MDnsService.instance.findPeers();
    await BleDiscoveryService.instance.startScan();

    if (mounted) {
      setState(() {
        _lanPeers = lanPeers;
        _isSearching = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final cubit = context.watch<SettingsCubit>();
    final state = cubit.state;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: cs.surface,
        title: Text('Connections', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: _isSearching 
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.refresh_rounded),
            onPressed: _searchForPeers,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'My Devices'),
            Tab(text: 'Friends'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _DevicesTab(state: state, cubit: cubit, lanPeers: _lanPeers, blePeers: _blePeers),
          const _FriendsTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showPairingOptions(context),
        label: const Text('Add New'),
        icon: const Icon(Icons.add_rounded),
      ),
    );
  }

  void _showPairingOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.qr_code_scanner_rounded),
            title: const Text('Scan QR Code'),
            onTap: () {
              Navigator.pop(ctx);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ScanScreen())).then((val) {
                if (val == true && mounted) setState(() {});
              });
            },
          ),
          ListTile(
            leading: const Icon(Icons.qr_code_rounded),
            title: const Text('Show My QR Code'),
            onTap: () {
              Navigator.pop(ctx);
              _showMyQrCode(context);
            },
          ),
        ],
      ),
    );
  }

  void _showMyQrCode(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('My Pairing Code'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 200,
              height: 200,
              child: QrImageView(
                data: PeerManager.instance.generatePairingData(),
                version: QrVersions.auto,
                eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: Colors.white),
                dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: Colors.white),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Scan this code on your other device to link it.'),
          ],
        ),
      ),
    );
  }
}

class _DevicesTab extends StatelessWidget {
  final SettingsState state;
  final SettingsCubit cubit;
  final List<Map<String, dynamic>> lanPeers;
  final List<ScanResult> blePeers;

  const _DevicesTab({
    required this.state, 
    required this.cubit,
    required this.lanPeers,
    required this.blePeers,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final pairedPeers = PeerManager.instance.peers.where((p) => p.relation == PeerRelation.sameUser).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const _SectionTitle('Local Device'),
        const SizedBox(height: 12),
        _ConnectionTile(
          name: 'My ${DesktopController.instance.isMini ? "Desktop" : "Mobile"} (This Device)',
          subtitle: 'Streaming source active',
          status: 'Online',
        ),
        const SizedBox(height: 24),
        const _SectionTitle('Streaming Mode'),
        const SizedBox(height: 12),
        Card(
          color: cs.surfaceContainer,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: Column(
            children: [
              RadioListTile<StreamingMode>(
                title: const Text('Standalone', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                subtitle: const Text('Resolve streams on this device', style: TextStyle(fontSize: 12)),
                value: StreamingMode.standalone,
                groupValue: state.streamingMode,
                onChanged: (v) { if (v != null) cubit.setStreamingMode(v); },
                activeColor: cs.primary,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              ),
              const Divider(height: 1, indent: 16),
              RadioListTile<StreamingMode>(
                title: const Text('Relay from Peer', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                subtitle: const Text('Route through paired mobile (Mobile → Desktop)', style: TextStyle(fontSize: 12)),
                value: StreamingMode.relayFromPeer,
                groupValue: state.streamingMode,
                onChanged: (v) { if (v != null) cubit.setStreamingMode(v); },
                activeColor: cs.primary,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              ),
              const Divider(height: 1, indent: 16),
              RadioListTile<StreamingMode>(
                title: const Text('Hybrid', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                subtitle: const Text('Local first, then fallback to peer', style: TextStyle(fontSize: 12)),
                value: StreamingMode.hybridPreferLocal,
                groupValue: state.streamingMode,
                onChanged: (v) { if (v != null) cubit.setStreamingMode(v); },
                activeColor: cs.primary,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const _SectionTitle('Paired Devices'),
        const SizedBox(height: 12),
        if (pairedPeers.isEmpty)
          const Center(
            child: Text(
              'No other devices paired',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          )
        else
          ...pairedPeers.map((p) => _ConnectionTile(
            name: p.displayName,
            subtitle: p.lastKnownIp ?? 'Offline',
            status: p.lastKnownIp != null ? 'Online' : 'Paired',
            onSync: p.lastKnownIp != null ? () => _triggerSync(context, p) : null,
          )),
        const SizedBox(height: 24),
        const _SectionTitle('Discovered LAN Peers'),
        const SizedBox(height: 12),
        if (lanPeers.isEmpty)
          const Center(
            child: Text(
              'No other devices found on LAN',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          )
        else
          ...lanPeers.map((p) => _ConnectionTile(
            name: p['name'],
            subtitle: 'IP: ${p['ip']}',
            status: 'Found',
          )),
        const SizedBox(height: 24),
        const _SectionTitle('Discovered BLE Peers'),
        const SizedBox(height: 12),
        if (blePeers.isEmpty)
          const Center(
            child: Text(
              'No Flow devices detected via BLE',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          )
        else
          ...blePeers.map((p) => _ConnectionTile(
            name: p.advertisementData.advName.isNotEmpty ? p.advertisementData.advName : p.device.remoteId.toString(),
            subtitle: 'RSSI: ${p.rssi}',
            status: 'Proximity',
          )),
      ],
    );
  }

  Future<void> _triggerSync(BuildContext context, DevicePeer peer) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Syncing with ${peer.displayName}...')),
    );
    
    try {
      await LanStreamBridge.instance.triggerPeerSync(peer);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sync complete!')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sync failed: $e')),
        );
      }
    }
  }
}

class _FriendsTab extends StatelessWidget {
  const _FriendsTab();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final peers = PeerManager.instance.peers.where((p) => p.relation == PeerRelation.otherUser).toList();

    if (peers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline_rounded, size: 64, color: cs.outline),
            const SizedBox(height: 16),
            const Text('No friends linked yet'),
            const SizedBox(height: 8),
            const Text(
              'Link with friends to share taste blends!',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const _SectionTitle('Linked Friends'),
        const SizedBox(height: 12),
        ...peers.map((p) => _FriendTile(peer: p)),
      ],
    );
  }
}

class _FriendTile extends StatelessWidget {
  final DevicePeer peer;
  const _FriendTile({required this.peer});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      color: cs.surfaceContainer,
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: cs.primary.withAlpha(40),
          child: Text(peer.displayName[0].toUpperCase()),
        ),
        title: Text(peer.displayName, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('Last seen: ${_formatDate(peer.lastSeen)}'),
        trailing: IconButton(
          icon: const Icon(Icons.settings_outlined),
          onPressed: () => _showFriendSettings(context, peer),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${date.day}/${date.month}';
  }

  void _showFriendSettings(BuildContext context, DevicePeer peer) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text('Settings for ${peer.displayName}', style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.blender_outlined),
            title: const Text('Compute Taste Blend'),
            onTap: () {
              Navigator.pop(ctx);
              _triggerBlend(context, peer);
            },
          ),
          ListTile(
            leading: const Icon(Icons.person_remove_rounded, color: Colors.redAccent),
            title: const Text('Remove Friend', style: TextStyle(color: Colors.redAccent)),
            onTap: () {
              Navigator.pop(ctx);
              // TODO: Remove friend logic
            },
          ),
        ],
      ),
    );
  }

  Future<void> _triggerBlend(BuildContext context, DevicePeer peer) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Computing taste blend with ${peer.displayName}...')),
    );
    
    try {
      final repository = context.read<MusicRepository>();
      final blendedSongs = await repository.getBlendedRecommendations(peer.peerId);
      
      if (blendedSongs.isNotEmpty && context.mounted) {
        await AppIntelligence.instance.saveLocalPlaylist('Blend with ${peer.displayName}', blendedSongs.map((s) => s.id).toList());
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Taste Blend saved to your library!'),
              action: SnackBarAction(
                label: 'View',
                onPressed: () => AppEventBus.instance.fire(const SwitchTabEvent(2)),
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Blend failed: $e')),
        );
      }
    }
  }
}

class _ConnectionTile extends StatelessWidget {
  final String name;
  final String subtitle;
  final String status;
  final VoidCallback? onSync;

  const _ConnectionTile({
    required this.name,
    required this.subtitle,
    required this.status,
    this.onSync,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      color: cs.surfaceContainer,
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: onSync != null 
          ? TextButton.icon(
              onPressed: onSync,
              icon: const Icon(Icons.sync_rounded, size: 18),
              label: const Text('Sync'),
            )
          : Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: status == 'Online' ? Colors.green.withAlpha(40) : Colors.grey.withAlpha(40),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                status,
                style: TextStyle(
                  fontSize: 10,
                  color: status == 'Online' ? Colors.green : Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Text(
      title.toUpperCase(),
      style: GoogleFonts.outfit(
        fontWeight: FontWeight.w600,
        fontSize: 11,
        letterSpacing: 1.1,
        color: cs.primary,
      ),
    );
  }
}
