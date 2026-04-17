import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../domain/entities/song.dart';
import '../../../domain/repositories/song_repository.dart';
import '../../../core/logger/app_logger.dart';
import '../../../core/ui/app_snack_bar.dart';
import '../../blocs/player/player_bloc.dart';

class FlowPlaylistManageScreen extends StatefulWidget {
  final Playlist playlist;
  const FlowPlaylistManageScreen({super.key, required this.playlist});

  @override
  State<FlowPlaylistManageScreen> createState() =>
      _FlowPlaylistManageScreenState();
}

class _FlowPlaylistManageScreenState extends State<FlowPlaylistManageScreen> {
  static const _tag = 'FlowPlaylistManageScreen';

  late TextEditingController _titleController;
  late TextEditingController _descController;
  late TextEditingController _collabCodeController;
  bool _isPublic = false;
  bool _isSaving = false;
  bool _isDeleting = false;
  bool _isAddingCollab = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.playlist.name);
    _descController = TextEditingController(text: widget.playlist.description);
    _collabCodeController = TextEditingController();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _collabCodeController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (_titleController.text.trim().isEmpty) {
      setState(() => _error = 'Title cannot be empty');
      return;
    }

    setState(() {
      _isSaving = true;
      _error = null;
    });

    try {
      final repo = context.read<SongRepository>();
      await repo.updateFlowPlaylist(
        widget.playlist.id,
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        isPublic: _isPublic,
      );
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      AppLogger.e(_tag, 'Failed to update playlist', e);
      setState(() {
        _error = AppSnackBar.humanMessage(e);
        _isSaving = false;
      });
    }
  }

  Future<void> _deletePlaylist() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Playlist'),
        content: const Text(
          'Are you sure you want to delete this playlist? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isDeleting = true;
      _error = null;
    });

    try {
      final repo = context.read<SongRepository>();
      await repo.deleteFlowPlaylist(widget.playlist.id);
      if (mounted) {
        Navigator.pop(context, 'deleted');
      }
    } catch (e) {
      AppLogger.e(_tag, 'Failed to delete playlist', e);
      setState(() {
        _error = AppSnackBar.humanMessage(e);
        _isDeleting = false;
      });
    }
  }

  Future<void> _addCollaborator() async {
    final code = _collabCodeController.text.trim();
    if (code.isEmpty) return;

    setState(() {
      _isAddingCollab = true;
      _error = null;
    });

    try {
      final repo = context.read<SongRepository>();
      await repo.addCollaborator(widget.playlist.id, code);
      _collabCodeController.clear();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Added collaborator: $code')));
      }
    } catch (e) {
      AppLogger.e(_tag, 'Failed to add collaborator', e);
      setState(() {
        _error = AppSnackBar.humanMessage(e);
      });
    } finally {
      if (mounted) {
        setState(() => _isAddingCollab = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Playlist'),
        actions: [
          TextButton(
            onPressed: _isSaving || _isDeleting ? null : _saveChanges,
            child: _isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_error != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withAlpha(30),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(_error!, style: const TextStyle(color: Colors.red)),
            ),
            const SizedBox(height: 16),
          ],

          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Playlist Name',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),

          TextField(
            controller: _descController,
            decoration: const InputDecoration(
              labelText: 'Description',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 16),

          SwitchListTile(
            title: const Text('Public Playlist'),
            subtitle: const Text('Anyone with the link can view'),
            value: _isPublic,
            onChanged: (v) => setState(() => _isPublic = v),
          ),

          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),

          Text(
            'Collaborators',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add collaborators using their user code (e.g., mahaveer#1234)',
            style: TextStyle(
              color: colorScheme.onSurface.withAlpha(140),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _collabCodeController,
                  decoration: const InputDecoration(
                    labelText: 'User Code',
                    hintText: 'Enter user code',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              FilledButton(
                onPressed: _isAddingCollab ? null : _addCollaborator,
                child: _isAddingCollab
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Add'),
              ),
            ],
          ),

          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 16),

          Text(
            'Danger Zone',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 16),

          OutlinedButton.icon(
            onPressed: _isDeleting ? null : _deletePlaylist,
            icon: const Icon(Icons.delete_forever_rounded),
            label: _isDeleting
                ? const Text('Deleting...')
                : const Text('Delete Playlist'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
