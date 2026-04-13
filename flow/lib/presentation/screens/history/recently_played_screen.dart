import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../domain/entities/history_data.dart';
import '../../../domain/entities/song.dart';
import '../../../domain/repositories/song_repository.dart';
import '../../widgets/song_tile.dart';

class RecentlyPlayedScreen extends StatefulWidget {
  const RecentlyPlayedScreen({super.key});

  @override
  State<RecentlyPlayedScreen> createState() => _RecentlyPlayedScreenState();
}

class _RecentlyPlayedScreenState extends State<RecentlyPlayedScreen> {
  late Future<HistoryData> _historyFuture;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    setState(() {
      _historyFuture = context.read<SongRepository>().getPersistentHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Recently Played',
          style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700),
        ),
      ),
      body: FutureBuilder<HistoryData>(
        future: _historyFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final data = snapshot.data!;
          if (data.today.isEmpty &&
              data.thisWeek.isEmpty &&
              data.thisMonth.isEmpty &&
              data.byMonth.isEmpty) {
            return const Center(child: Text('No history yet.'));
          }

          final allHistorySongs = [
            ...data.today,
            ...data.thisWeek,
            ...data.thisMonth,
            for (var m in data.byMonth.values) ...m,
          ];

          return RefreshIndicator(
            onRefresh: () async {
              _refresh();
              await _historyFuture;
            },
            child: ListView(
              padding: const EdgeInsets.only(bottom: 100),
              children: [
                if (data.today.isNotEmpty) ...[
                  _SectionHeader(title: 'Today'),
                  ...data.today.map(
                    (s) => SongTile(
                      song: s,
                      queue: allHistorySongs,
                      index: allHistorySongs.indexOf(s),
                    ),
                  ),
                ],
                if (data.thisWeek.isNotEmpty) ...[
                  _SectionHeader(title: 'This Week'),
                  ...data.thisWeek.map(
                    (s) => SongTile(
                      song: s,
                      queue: allHistorySongs,
                      index: allHistorySongs.indexOf(s),
                    ),
                  ),
                ],
                if (data.thisMonth.isNotEmpty) ...[
                  _SectionHeader(title: 'This Month'),
                  ...data.thisMonth.map(
                    (s) => SongTile(
                      song: s,
                      queue: allHistorySongs,
                      index: allHistorySongs.indexOf(s),
                    ),
                  ),
                ],
                ...data.byMonth.entries.map(
                  (entry) => Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SectionHeader(title: entry.key),
                      ...entry.value.map(
                        (s) => SongTile(
                          song: s,
                          queue: allHistorySongs,
                          index: allHistorySongs.indexOf(s),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: GoogleFonts.outfit(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}
