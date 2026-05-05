import 'dart:io';
import 'package:metadata_god/metadata_god.dart';
import '../../../domain/entities/track.dart';
import '../../../domain/repositories/music_source_adapter.dart';
import '../../../core/logger/app_logger.dart';

class LocalFilesAdapter implements MusicSourceAdapter {
  final List<String> libraryPaths;

  LocalFilesAdapter({required this.libraryPaths});

  static const _tag = 'LocalFilesAdapter';

  @override
  Future<List<Track>> search(String query) async {
    final library = await getUserLibrary();
    final q = query.toLowerCase();
    return library.where((t) => 
      t.title.toLowerCase().contains(q) || 
      t.artist.toLowerCase().contains(q) ||
      (t.album?.toLowerCase().contains(q) ?? false)
    ).toList();
  }

  @override
  Future<StreamUrl?> getStreamUrl(Track track, {Quality quality = Quality.high}) async {
    if (track.downloadedPath != null && await File(track.downloadedPath!).exists()) {
      return StreamUrl(
        url: Uri.file(track.downloadedPath!).toString(),
        quality: Quality.high,
        format: track.downloadedPath!.split('.').last,
      );
    }
    return null;
  }

  @override
  Future<List<Track>> getUserLibrary() async {
    final List<Track> tracks = [];
    
    for (final path in libraryPaths) {
      final dir = Directory(path);
      if (!await dir.exists()) continue;

      try {
        final files = await dir.list(recursive: true).toList();
        for (final entity in files) {
          if (entity is File && _isAudioFile(entity.path)) {
            final trackId = 'local:${entity.path.hashCode}';
            final fallbackTitle = entity.path.split(Platform.pathSeparator).last;
            
            try {
              final metadata = await MetadataGod.readMetadata(file: entity.path);
              String? localArtworkPath;
              
              if (metadata.picture != null) {
                try {
                  final artworkDir = Directory('${entity.parent.parent.path}/artwork');
                  if (!await artworkDir.exists()) await artworkDir.create(recursive: true);
                  final artworkFile = File('${artworkDir.path}/$trackId.jpg');
                  if (!await artworkFile.exists()) {
                    await artworkFile.writeAsBytes(metadata.picture!.data);
                  }
                  localArtworkPath = artworkFile.path;
                } catch (e) {
                  AppLogger.w(_tag, 'Failed to save artwork for $trackId: $e');
                }
              }

              tracks.add(Track(
                id: trackId,
                title: metadata.title ?? fallbackTitle,
                artist: metadata.artist ?? 'Unknown Artist',
                artistId: 'local:${metadata.artist ?? 'unknown'}',
                album: metadata.album,
                year: metadata.year?.toString(),
                downloaded: true,
                downloadedPath: entity.path,
                localArtworkPath: localArtworkPath,
                artworkUrl: null,
              ));
            } catch (e) {

              AppLogger.w(_tag, 'Failed to read metadata for ${entity.path}: $e');
              tracks.add(Track(
                id: trackId,
                title: fallbackTitle,
                artist: 'Unknown Artist',
                artistId: 'local:unknown',
                downloaded: true,
                downloadedPath: entity.path,
              ));
            }
          }
        }
      } catch (e) {
        AppLogger.e(_tag, 'Failed to scan directory $path', e);
      }
    }
    
    return tracks;
  }

  bool _isAudioFile(String path) {
    final ext = path.split('.').last.toLowerCase();
    return ['mp3', 'flac', 'm4a', 'wav', 'ogg', 'opus'].contains(ext);
  }

  @override
  Future<List<Track>> getCreatorTracks(String creatorId) async => [];

  @override
  Future<List<Track>> getAlbumTracks(String albumId) async {
    final library = await getUserLibrary();
    return library.where((t) => t.albumId == albumId || t.album == albumId).toList();
  }

  @override
  Future<List<Track>> getSimilar(Track seed) async => [];
}
