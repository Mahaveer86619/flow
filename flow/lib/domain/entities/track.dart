import 'package:equatable/equatable.dart';
import 'song.dart';

class Track extends Equatable {
  final String id; // internal UUID or hash
  final String title;
  final String artist;
  final String artistId;
  final String? album;
  final String? albumId;
  final String? year;
  final List<String> genres;
  final List<String> tags; // mood, energy, tempo descriptors
  final String? youtubeId; // videoId for stream resolution
  final String? ytmBrowseId; // for YTM metadata navigation
  final String? spotifyId; // metadata only, never for audio
  final String? sourceChannelId; // YT channel ID
  final String? artworkUrl;
  final String? localArtworkPath;
  final TrackAudioFeatures? audio;

  // Behavioral state
  final int playCount;
  final int skipCount;
  final int replayCount;
  final DateTime? lastPlayed;
  final bool liked;
  final bool downloaded;
  final String? downloadedPath;
  final bool cachedAudio;
  final double graphScore; // maintained by ScoringGraph

  const Track({
    required this.id,
    required this.title,
    required this.artist,
    required this.artistId,
    this.album,
    this.albumId,
    this.year,
    this.genres = const [],
    this.tags = const [],
    this.youtubeId,
    this.ytmBrowseId,
    this.spotifyId,
    this.sourceChannelId,
    this.artworkUrl,
    this.localArtworkPath,
    this.audio,
    this.playCount = 0,
    this.skipCount = 0,
    this.replayCount = 0,
    this.lastPlayed,
    this.liked = false,
    this.downloaded = false,
    this.downloadedPath,
    this.cachedAudio = false,
    this.graphScore = 0.0,
  });

  factory Track.fromSong(Song song) {
    final extras = song.extras ?? {};
    return Track(
      id: song.id,
      title: song.title,
      artist: song.artist,
      artistId: extras['artistId'] as String? ?? song.artist,
      album: song.album,
      albumId: extras['albumId'] as String?,
      year: extras['year'] as String?,
      genres: (extras['genres'] as List?)?.cast<String>() ?? const [],
      tags: (extras['tags'] as List?)?.cast<String>() ?? const [],
      youtubeId: song.id,
      ytmBrowseId: extras['ytmBrowseId'] as String?,
      spotifyId: extras['spotifyId'] as String?,
      sourceChannelId: extras['sourceChannelId'] as String?,
      artworkUrl: song.thumbnailUrl,
      downloaded: song.isDownloaded,
      lastPlayed: song.playedAt,
      playCount: extras['playCount'] as int? ?? 0,
      skipCount: extras['skipCount'] as int? ?? 0,
      replayCount: extras['replayCount'] as int? ?? 0,
      graphScore: extras['graphScore'] as double? ?? 0.0,
    );
  }

  String get fingerprint => trackFingerprint(artist, title);

  static String trackFingerprint(String artist, String title) =>
      '${_normalize(artist)}::${_normalize(title)}';

  static String _normalize(String s) => s
      .toLowerCase()
      .replaceAll(RegExp(r"[^\w\s]"), '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  Track copyWith({
    String? id,
    String? title,
    String? artist,
    String? artistId,
    String? album,
    String? albumId,
    String? year,
    List<String>? genres,
    List<String>? tags,
    String? youtubeId,
    String? ytmBrowseId,
    String? spotifyId,
    String? sourceChannelId,
    String? artworkUrl,
    String? localArtworkPath,
    TrackAudioFeatures? audio,
    int? playCount,
    int? skipCount,
    int? replayCount,
    DateTime? lastPlayed,
    bool? liked,
    bool? downloaded,
    String? downloadedPath,
    bool? cachedAudio,
    double? graphScore,
  }) {
    return Track(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      artistId: artistId ?? this.artistId,
      album: album ?? this.album,
      albumId: albumId ?? this.albumId,
      year: year ?? this.year,
      genres: genres ?? this.genres,
      tags: tags ?? this.tags,
      youtubeId: youtubeId ?? this.youtubeId,
      ytmBrowseId: ytmBrowseId ?? this.ytmBrowseId,
      spotifyId: spotifyId ?? this.spotifyId,
      sourceChannelId: sourceChannelId ?? this.sourceChannelId,
      artworkUrl: artworkUrl ?? this.artworkUrl,
      localArtworkPath: localArtworkPath ?? this.localArtworkPath,
      audio: audio ?? this.audio,
      playCount: playCount ?? this.playCount,
      skipCount: skipCount ?? this.skipCount,
      replayCount: replayCount ?? this.replayCount,
      lastPlayed: lastPlayed ?? this.lastPlayed,
      liked: liked ?? this.liked,
      downloaded: downloaded ?? this.downloaded,
      downloadedPath: downloadedPath ?? this.downloadedPath,
      cachedAudio: cachedAudio ?? this.cachedAudio,
      graphScore: graphScore ?? this.graphScore,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        artist,
        artistId,
        album,
        albumId,
        year,
        genres,
        tags,
        youtubeId,
        ytmBrowseId,
        spotifyId,
        sourceChannelId,
        artworkUrl,
        localArtworkPath,
        audio,
        playCount,
        skipCount,
        replayCount,
        lastPlayed,
        liked,
        downloaded,
        downloadedPath,
        cachedAudio,
        graphScore,
      ];
}

class TrackAudioFeatures extends Equatable {
  final double bpm;
  final double energy; // 0.0–1.0
  final double danceability; // 0.0–1.0
  final String key;
  final String mode; // major | minor

  const TrackAudioFeatures({
    required this.bpm,
    required this.energy,
    required this.danceability,
    required this.key,
    required this.mode,
  });

  @override
  List<Object?> get props => [bpm, energy, danceability, key, mode];
}
