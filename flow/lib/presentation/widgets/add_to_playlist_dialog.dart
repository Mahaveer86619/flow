import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../domain/entities/song.dart';
import '../../domain/repositories/music_repository.dart';
import '../../core/logger/app_logger.dart';
import '../cubits/library/library_cubit.dart';

class AddToPlaylistDialog extends StatefulWidget {
  final Song song;
  const AddToPlaylistDialog({super.key, required this.song});

  static Future<void> show(BuildContext context, Song song) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => BlocProvider.value(
        value: context.read<LibraryCubit>(),
        child: AddToPlaylistDialog(song: song),
      ),
    );
  }

  @override
  State<AddToPlaylistDialog> createState() => _AddToPlaylistDialogState();
}

class _AddToPlaylistDialogState extends State<AddToPlaylistDialog> {
  static const _tag = 'AddToPlaylistDialog';

  bool _isCreating = false;
  bool _isAdding = false;
  String? _addingToId;
  String? _error;
  final _newPlaylistController = TextEditingController();

  List<Playlist> get _flowPlaylists {
    final state = context.read<LibraryCubit>().state;
    return state.playlists.where((p) => p.type == 'flow').toList();
  }

  Future<void> _createAndAdd() async {
    final name = _newPlaylistController.text.trim();
    if (name.isEmpty) return;

    setState(() => _isCreating = true);

    try {
      final repo = context.read<MusicRepository>();
      final newPlaylist = await repo.createFlowPlaylist(title: name);
      await repo.addTrackToFlowPlaylist(newPlaylist.id, widget.song);

      if (mounted) {
        Navigator.pop(context, newPlaylist);
      }
    } catch (e) {
      AppLogger.e(_tag, 'Failed to create playlist', e);
      setState(() {
        _error = e.toString();
        _isCreating = false;
      });
    }
  }

  Future<void> _addToPlaylist(Playlist playlist) async {
    setState(() {
      _isAdding = true;
      _addingToId = playlist.id;
    });

    try {
      final repo = context.read<MusicRepository>();
      await repo.addTrackToFlowPlaylist(playlist.id, widget.song);

      if (mounted) {
        Navigator.pop(context, playlist);
      }
    } catch (e) {
      AppLogger.e(_tag, 'Failed to add to playlist', e);
      setState(() {
        _error = e.toString();
        _isAdding = false;
        _addingToId = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final playlists = _flowPlaylists;

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  'Add to Playlist',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          if (_error != null) ...[
            Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withAlpha(30),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              ),
            ),
          ],

          // Create new playlist option
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _newPlaylistController,
                    decoration: const InputDecoration(
                      hintText: 'New playlist name...',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    onSubmitted: (_) => _createAndAdd(),
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton(
                  onPressed: _isCreating ? null : _createAndAdd,
                  child: _isCreating
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.add),
                ),
              ],
            ),
          ),

          const Divider(),

          // Existing playlists
          Expanded(
            child: playlists.isEmpty
                ? Center(
                    child: Text(
                      'No Flow playlists yet.\nCreate one above!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: colorScheme.onSurface.withAlpha(140),
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: playlists.length,
                    itemBuilder: (context, i) {
                      final playlist = playlists[i];
                      final isAdding = _isAdding && _addingToId == playlist.id;

                      return ListTile(
                        leading: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: playlist.color,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: playlist.thumbnailUrl != null
                              ? Image.network(
                                  playlist.thumbnailUrl!,
                                  fit: BoxFit.cover,
                                )
                              : const Icon(
                                  Icons.playlist_play,
                                  color: Colors.white,
                                ),
                        ),
                        title: Text(playlist.name),
                        subtitle: Text('${playlist.songs.length} tracks'),
                        trailing: isAdding
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.add_circle_outline),
                        onTap: isAdding ? null : () => _addToPlaylist(playlist),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _newPlaylistController.dispose();
    super.dispose();
  }
}
