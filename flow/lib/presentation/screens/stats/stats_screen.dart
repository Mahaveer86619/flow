import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/intelligence/app_intelligence.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  List<Map<String, dynamic>> _topArtists = [];
  List<Map<String, dynamic>> _topGenres = [];
  Map<DateTime, int> _heatmap = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final intel = AppIntelligence.instance;
    final artists = await intel.getTopArtists();
    final genres = await intel.getTopGenres();
    final heatmap = await intel.getListeningHeatmap();

    if (mounted) {
      setState(() {
        _topArtists = artists;
        _topGenres = genres;
        _heatmap = heatmap;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: cs.surface,
        title: Text('Listening Insights', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _SectionTitle('Listening Activity'),
                const SizedBox(height: 12),
                _HeatmapCard(heatmap: _heatmap),
                const SizedBox(height: 32),
                _SectionTitle('Top Artists'),
                const SizedBox(height: 12),
                ..._topArtists.map((a) => _StatTile(
                      label: a['id'],
                      value: '${a['score'].toStringAsFixed(1)} pts',
                      icon: Icons.person_rounded,
                      color: cs.primary,
                    )),
                const SizedBox(height: 32),
                _SectionTitle('Top Genres'),
                const SizedBox(height: 12),
                ..._topGenres.map((g) => _StatTile(
                      label: g['id'],
                      value: '${g['score'].toStringAsFixed(1)} pts',
                      icon: Icons.category_rounded,
                      color: cs.secondary,
                    )),
              ],
            ),
    );
  }
}

class _HeatmapCard extends StatelessWidget {
  final Map<DateTime, int> heatmap;

  const _HeatmapCard({required this.heatmap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    // Simplified heatmap: just a row of boxes for the last 7 days
    final now = DateTime.now();
    final days = List.generate(7, (i) => DateTime(now.year, now.month, now.day).subtract(Duration(days: 6 - i)));

    return Card(
      color: cs.surfaceContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Last 7 Days', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: days.map((d) {
                final count = heatmap[d] ?? 0;
                final opacity = (count / 20).clamp(0.1, 1.0);
                return Column(
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: cs.primary.withOpacity(opacity),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      ['M', 'T', 'W', 'T', 'F', 'S', 'S'][d.weekday - 1],
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                  ],
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        tileColor: cs.surfaceContainer.withAlpha(100),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        leading: CircleAvatar(
          backgroundColor: color.withAlpha(30),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        trailing: Text(value, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: cs.primary)),
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
