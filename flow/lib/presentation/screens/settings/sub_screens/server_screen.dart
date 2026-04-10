import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import '../../../../core/config/server_config.dart';

class ServerScreen extends StatefulWidget {
  const ServerScreen({super.key});

  @override
  State<ServerScreen> createState() => _ServerScreenState();
}

class _ServerScreenState extends State<ServerScreen> {
  late final TextEditingController _ctrl;
  bool _testing = false;
  String? _testResult;
  bool _testOk = false;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(
      text: ServerConfig.instance.isCustom
          ? ServerConfig.instance.baseUrl
          : '',
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _testConnection() async {
    final raw = _ctrl.text.trim();
    if (raw.isEmpty) return;
    final url = raw.endsWith('/') ? raw.substring(0, raw.length - 1) : raw;
    setState(() {
      _testing = true;
      _testResult = null;
    });
    try {
      final uri = Uri.parse('$url/api/v1/home');
      final resp = await http.get(uri).timeout(const Duration(seconds: 6));
      setState(() {
        _testOk = resp.statusCode >= 200 && resp.statusCode < 300;
        _testResult = _testOk
            ? 'Connected — HTTP ${resp.statusCode}'
            : 'Server responded with HTTP ${resp.statusCode}';
      });
    } catch (e) {
      setState(() {
        _testOk = false;
        _testResult = 'Could not reach server: $e';
      });
    } finally {
      setState(() => _testing = false);
    }
  }

  void _save() {
    final raw = _ctrl.text.trim();
    if (raw.isEmpty) return;
    final url = raw.endsWith('/') ? raw.substring(0, raw.length - 1) : raw;
    ServerConfig.instance.setCustomUrl(url);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Server URL saved. Refresh data to apply.')),
    );
    setState(() {});
  }

  void _reset() {
    ServerConfig.instance.clearCustomUrl();
    _ctrl.clear();
    setState(() => _testResult = null);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Reset to default: ${ServerConfig.instance.fallbackUrl}'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isCustom = ServerConfig.instance.isCustom;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: cs.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'Server',
          style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Current URL info card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cs.surfaceContainer,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Active Server',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: cs.outline,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  ServerConfig.instance.baseUrl,
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                  ),
                ),
                if (isCustom) ...[
                  const SizedBox(height: 4),
                  Row(children: [
                    Icon(Icons.edit_outlined, size: 13, color: cs.primary),
                    const SizedBox(width: 4),
                    Text(
                      'Custom',
                      style: GoogleFonts.outfit(
                          fontSize: 12, color: cs.primary),
                    ),
                  ]),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Custom Server URL',
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              letterSpacing: 1.1,
              color: cs.primary,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _ctrl,
            keyboardType: TextInputType.url,
            autocorrect: false,
            decoration: InputDecoration(
              hintText: 'http://192.168.1.x:8000',
              filled: true,
              fillColor: cs.surfaceContainer,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: cs.primary),
              ),
              prefixIcon: const Icon(Icons.dns_outlined),
              suffixIcon: _ctrl.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded),
                      onPressed: () {
                        _ctrl.clear();
                        setState(() => _testResult = null);
                      },
                    )
                  : null,
            ),
            onChanged: (_) => setState(() => _testResult = null),
          ),
          const SizedBox(height: 12),
          // Test result
          if (_testResult != null)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: _testOk
                    ? Colors.green.withAlpha(30)
                    : cs.errorContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(
                    _testOk
                        ? Icons.check_circle_outline_rounded
                        : Icons.error_outline_rounded,
                    size: 16,
                    color: _testOk ? Colors.green : cs.error,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _testResult!,
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        color: _testOk ? Colors.green : cs.error,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _testing ? null : _testConnection,
                  icon: _testing
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.wifi_tethering_rounded, size: 18),
                  label: Text(_testing ? 'Testing…' : 'Test'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _ctrl.text.trim().isEmpty ? null : _save,
                  icon: const Icon(Icons.save_outlined, size: 18),
                  label: const Text('Save'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
          if (isCustom) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: _reset,
                icon: const Icon(Icons.restore_rounded, size: 18),
                label: Text('Reset to default (${ServerConfig.instance.fallbackUrl})'),
                style: TextButton.styleFrom(foregroundColor: cs.error),
              ),
            ),
          ],
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cs.surfaceContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline_rounded, size: 16, color: cs.outline),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Point this to your self-hosted flow-source instance. '
                    'Format: http://host:port — no trailing slash. '
                    'Changes apply to the next data fetch and stream.',
                    style: GoogleFonts.outfit(
                        fontSize: 12, color: cs.outline, height: 1.5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
