import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/platform/desktop_controller.dart';
import '../../../core/network/lan_stream_bridge.dart';
import '../../cubits/settings/settings_cubit.dart';
import '../../cubits/settings/settings_state.dart';

class ConnectionsScreen extends StatefulWidget {
  const ConnectionsScreen({super.key});

  @override
  State<ConnectionsScreen> createState() => _ConnectionsScreenState();
}

class _ConnectionsScreenState extends State<ConnectionsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
          _DevicesTab(state: state, cubit: cubit),
          _FriendsTab(),
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
              // TODO: Implement scanner
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
                data: 'flow:device_pairing:placeholder_id',
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

  const _DevicesTab({required this.state, required this.cubit});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _SectionTitle('Local Device'),
        const SizedBox(height: 12),
        _ConnectionTile(
          name: 'My ${DesktopController.instance.isMini ? "Desktop" : "Mobile"} (This Device)',
          subtitle: 'Streaming source active',
          isLocal: true,
          status: 'Online',
        ),
        const SizedBox(height: 24),
        _SectionTitle('Streaming Mode'),
        const SizedBox(height: 12),
        Card(
          color: cs.surfaceContainer,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: Column(
            children: [
              _RadioTile<StreamingMode>(
                title: 'Standalone',
                subtitle: 'Resolve streams on this device',
                value: StreamingMode.standalone,
                groupValue: state.streamingMode,
                onChanged: (v) => cubit.setStreamingMode(v!),
              ),
              const Divider(height: 1, indent: 16),
              _RadioTile<StreamingMode>(
                title: 'Relay from Peer',
                subtitle: 'Route through paired mobile (Mobile → Desktop)',
                value: StreamingMode.relayFromPeer,
                groupValue: state.streamingMode,
                onChanged: (v) => cubit.setStreamingMode(v!),
              ),
              const Divider(height: 1, indent: 16),
              _RadioTile<StreamingMode>(
                title: 'Hybrid',
                subtitle: 'Local first, then fallback to peer',
                value: StreamingMode.hybridPreferLocal,
                groupValue: state.streamingMode,
                onChanged: (v) => cubit.setStreamingMode(v!),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _SectionTitle('Paired Devices'),
        const SizedBox(height: 12),
        Center(
          child: Text(
            'No other devices paired',
            style: TextStyle(color: cs.outline, fontSize: 12),
          ),
        ),
      ],
    );
  }
}

class _FriendsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline_rounded, size: 64, color: Theme.of(context).colorScheme.outline),
          const SizedBox(height: 16),
          const Text('No friends linked yet'),
          const SizedBox(height: 8),
          const Text('Link with friends to share taste blends!', style: TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }
}

class _ConnectionTile extends StatelessWidget {
  final String name;
  final String subtitle;
  final String status;
  final bool isLocal;

  const _ConnectionTile({
    required this.name,
    required this.subtitle,
    required this.status,
    this.isLocal = false,
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
        trailing: Container(
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

class _RadioTile<T> extends StatelessWidget {
  final String title;
  final String subtitle;
  final T value;
  final T groupValue;
  final ValueChanged<T?> onChanged;

  const _RadioTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.groupValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return RadioListTile<T>(
      value: value,
      groupValue: groupValue,
      onChanged: onChanged,
      title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      activeColor: Theme.of(context).colorScheme.primary,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
