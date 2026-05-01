// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'local_database.dart';

// ignore_for_file: type=lint
class $TracksTable extends Tracks with TableInfo<$TracksTable, TrackEntity> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TracksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _artistMeta = const VerificationMeta('artist');
  @override
  late final GeneratedColumn<String> artist = GeneratedColumn<String>(
    'artist',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _artistIdMeta = const VerificationMeta(
    'artistId',
  );
  @override
  late final GeneratedColumn<String> artistId = GeneratedColumn<String>(
    'artist_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _albumMeta = const VerificationMeta('album');
  @override
  late final GeneratedColumn<String> album = GeneratedColumn<String>(
    'album',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _albumIdMeta = const VerificationMeta(
    'albumId',
  );
  @override
  late final GeneratedColumn<String> albumId = GeneratedColumn<String>(
    'album_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _yearMeta = const VerificationMeta('year');
  @override
  late final GeneratedColumn<String> year = GeneratedColumn<String>(
    'year',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _genresMeta = const VerificationMeta('genres');
  @override
  late final GeneratedColumn<String> genres = GeneratedColumn<String>(
    'genres',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _tagsMeta = const VerificationMeta('tags');
  @override
  late final GeneratedColumn<String> tags = GeneratedColumn<String>(
    'tags',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _youtubeIdMeta = const VerificationMeta(
    'youtubeId',
  );
  @override
  late final GeneratedColumn<String> youtubeId = GeneratedColumn<String>(
    'youtube_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _ytmBrowseIdMeta = const VerificationMeta(
    'ytmBrowseId',
  );
  @override
  late final GeneratedColumn<String> ytmBrowseId = GeneratedColumn<String>(
    'ytm_browse_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _spotifyIdMeta = const VerificationMeta(
    'spotifyId',
  );
  @override
  late final GeneratedColumn<String> spotifyId = GeneratedColumn<String>(
    'spotify_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sourceChannelIdMeta = const VerificationMeta(
    'sourceChannelId',
  );
  @override
  late final GeneratedColumn<String> sourceChannelId = GeneratedColumn<String>(
    'source_channel_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _artworkUrlMeta = const VerificationMeta(
    'artworkUrl',
  );
  @override
  late final GeneratedColumn<String> artworkUrl = GeneratedColumn<String>(
    'artwork_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _localArtworkPathMeta = const VerificationMeta(
    'localArtworkPath',
  );
  @override
  late final GeneratedColumn<String> localArtworkPath = GeneratedColumn<String>(
    'local_artwork_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _bpmMeta = const VerificationMeta('bpm');
  @override
  late final GeneratedColumn<double> bpm = GeneratedColumn<double>(
    'bpm',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _energyMeta = const VerificationMeta('energy');
  @override
  late final GeneratedColumn<double> energy = GeneratedColumn<double>(
    'energy',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _danceabilityMeta = const VerificationMeta(
    'danceability',
  );
  @override
  late final GeneratedColumn<double> danceability = GeneratedColumn<double>(
    'danceability',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _modeMeta = const VerificationMeta('mode');
  @override
  late final GeneratedColumn<String> mode = GeneratedColumn<String>(
    'mode',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _playCountMeta = const VerificationMeta(
    'playCount',
  );
  @override
  late final GeneratedColumn<int> playCount = GeneratedColumn<int>(
    'play_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _skipCountMeta = const VerificationMeta(
    'skipCount',
  );
  @override
  late final GeneratedColumn<int> skipCount = GeneratedColumn<int>(
    'skip_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _replayCountMeta = const VerificationMeta(
    'replayCount',
  );
  @override
  late final GeneratedColumn<int> replayCount = GeneratedColumn<int>(
    'replay_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastPlayedMeta = const VerificationMeta(
    'lastPlayed',
  );
  @override
  late final GeneratedColumn<int> lastPlayed = GeneratedColumn<int>(
    'last_played',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _likedMeta = const VerificationMeta('liked');
  @override
  late final GeneratedColumn<bool> liked = GeneratedColumn<bool>(
    'liked',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("liked" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _downloadedMeta = const VerificationMeta(
    'downloaded',
  );
  @override
  late final GeneratedColumn<bool> downloaded = GeneratedColumn<bool>(
    'downloaded',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("downloaded" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _downloadedPathMeta = const VerificationMeta(
    'downloadedPath',
  );
  @override
  late final GeneratedColumn<String> downloadedPath = GeneratedColumn<String>(
    'downloaded_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _cachedAudioMeta = const VerificationMeta(
    'cachedAudio',
  );
  @override
  late final GeneratedColumn<bool> cachedAudio = GeneratedColumn<bool>(
    'cached_audio',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("cached_audio" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _graphScoreMeta = const VerificationMeta(
    'graphScore',
  );
  @override
  late final GeneratedColumn<double> graphScore = GeneratedColumn<double>(
    'graph_score',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
  );
  @override
  List<GeneratedColumn> get $columns => [
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
    bpm,
    energy,
    danceability,
    key,
    mode,
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
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tracks';
  @override
  VerificationContext validateIntegrity(
    Insertable<TrackEntity> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('artist')) {
      context.handle(
        _artistMeta,
        artist.isAcceptableOrUnknown(data['artist']!, _artistMeta),
      );
    } else if (isInserting) {
      context.missing(_artistMeta);
    }
    if (data.containsKey('artist_id')) {
      context.handle(
        _artistIdMeta,
        artistId.isAcceptableOrUnknown(data['artist_id']!, _artistIdMeta),
      );
    } else if (isInserting) {
      context.missing(_artistIdMeta);
    }
    if (data.containsKey('album')) {
      context.handle(
        _albumMeta,
        album.isAcceptableOrUnknown(data['album']!, _albumMeta),
      );
    }
    if (data.containsKey('album_id')) {
      context.handle(
        _albumIdMeta,
        albumId.isAcceptableOrUnknown(data['album_id']!, _albumIdMeta),
      );
    }
    if (data.containsKey('year')) {
      context.handle(
        _yearMeta,
        year.isAcceptableOrUnknown(data['year']!, _yearMeta),
      );
    }
    if (data.containsKey('genres')) {
      context.handle(
        _genresMeta,
        genres.isAcceptableOrUnknown(data['genres']!, _genresMeta),
      );
    }
    if (data.containsKey('tags')) {
      context.handle(
        _tagsMeta,
        tags.isAcceptableOrUnknown(data['tags']!, _tagsMeta),
      );
    }
    if (data.containsKey('youtube_id')) {
      context.handle(
        _youtubeIdMeta,
        youtubeId.isAcceptableOrUnknown(data['youtube_id']!, _youtubeIdMeta),
      );
    }
    if (data.containsKey('ytm_browse_id')) {
      context.handle(
        _ytmBrowseIdMeta,
        ytmBrowseId.isAcceptableOrUnknown(
          data['ytm_browse_id']!,
          _ytmBrowseIdMeta,
        ),
      );
    }
    if (data.containsKey('spotify_id')) {
      context.handle(
        _spotifyIdMeta,
        spotifyId.isAcceptableOrUnknown(data['spotify_id']!, _spotifyIdMeta),
      );
    }
    if (data.containsKey('source_channel_id')) {
      context.handle(
        _sourceChannelIdMeta,
        sourceChannelId.isAcceptableOrUnknown(
          data['source_channel_id']!,
          _sourceChannelIdMeta,
        ),
      );
    }
    if (data.containsKey('artwork_url')) {
      context.handle(
        _artworkUrlMeta,
        artworkUrl.isAcceptableOrUnknown(data['artwork_url']!, _artworkUrlMeta),
      );
    }
    if (data.containsKey('local_artwork_path')) {
      context.handle(
        _localArtworkPathMeta,
        localArtworkPath.isAcceptableOrUnknown(
          data['local_artwork_path']!,
          _localArtworkPathMeta,
        ),
      );
    }
    if (data.containsKey('bpm')) {
      context.handle(
        _bpmMeta,
        bpm.isAcceptableOrUnknown(data['bpm']!, _bpmMeta),
      );
    }
    if (data.containsKey('energy')) {
      context.handle(
        _energyMeta,
        energy.isAcceptableOrUnknown(data['energy']!, _energyMeta),
      );
    }
    if (data.containsKey('danceability')) {
      context.handle(
        _danceabilityMeta,
        danceability.isAcceptableOrUnknown(
          data['danceability']!,
          _danceabilityMeta,
        ),
      );
    }
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    }
    if (data.containsKey('mode')) {
      context.handle(
        _modeMeta,
        mode.isAcceptableOrUnknown(data['mode']!, _modeMeta),
      );
    }
    if (data.containsKey('play_count')) {
      context.handle(
        _playCountMeta,
        playCount.isAcceptableOrUnknown(data['play_count']!, _playCountMeta),
      );
    }
    if (data.containsKey('skip_count')) {
      context.handle(
        _skipCountMeta,
        skipCount.isAcceptableOrUnknown(data['skip_count']!, _skipCountMeta),
      );
    }
    if (data.containsKey('replay_count')) {
      context.handle(
        _replayCountMeta,
        replayCount.isAcceptableOrUnknown(
          data['replay_count']!,
          _replayCountMeta,
        ),
      );
    }
    if (data.containsKey('last_played')) {
      context.handle(
        _lastPlayedMeta,
        lastPlayed.isAcceptableOrUnknown(data['last_played']!, _lastPlayedMeta),
      );
    }
    if (data.containsKey('liked')) {
      context.handle(
        _likedMeta,
        liked.isAcceptableOrUnknown(data['liked']!, _likedMeta),
      );
    }
    if (data.containsKey('downloaded')) {
      context.handle(
        _downloadedMeta,
        downloaded.isAcceptableOrUnknown(data['downloaded']!, _downloadedMeta),
      );
    }
    if (data.containsKey('downloaded_path')) {
      context.handle(
        _downloadedPathMeta,
        downloadedPath.isAcceptableOrUnknown(
          data['downloaded_path']!,
          _downloadedPathMeta,
        ),
      );
    }
    if (data.containsKey('cached_audio')) {
      context.handle(
        _cachedAudioMeta,
        cachedAudio.isAcceptableOrUnknown(
          data['cached_audio']!,
          _cachedAudioMeta,
        ),
      );
    }
    if (data.containsKey('graph_score')) {
      context.handle(
        _graphScoreMeta,
        graphScore.isAcceptableOrUnknown(data['graph_score']!, _graphScoreMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TrackEntity map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TrackEntity(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      artist: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}artist'],
      )!,
      artistId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}artist_id'],
      )!,
      album: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}album'],
      ),
      albumId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}album_id'],
      ),
      year: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}year'],
      ),
      genres: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}genres'],
      ),
      tags: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tags'],
      ),
      youtubeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}youtube_id'],
      ),
      ytmBrowseId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ytm_browse_id'],
      ),
      spotifyId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}spotify_id'],
      ),
      sourceChannelId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_channel_id'],
      ),
      artworkUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}artwork_url'],
      ),
      localArtworkPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_artwork_path'],
      ),
      bpm: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}bpm'],
      ),
      energy: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}energy'],
      ),
      danceability: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}danceability'],
      ),
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      ),
      mode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mode'],
      ),
      playCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}play_count'],
      )!,
      skipCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}skip_count'],
      )!,
      replayCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}replay_count'],
      )!,
      lastPlayed: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_played'],
      ),
      liked: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}liked'],
      )!,
      downloaded: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}downloaded'],
      )!,
      downloadedPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}downloaded_path'],
      ),
      cachedAudio: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}cached_audio'],
      )!,
      graphScore: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}graph_score'],
      )!,
    );
  }

  @override
  $TracksTable createAlias(String alias) {
    return $TracksTable(attachedDatabase, alias);
  }
}

class TrackEntity extends DataClass implements Insertable<TrackEntity> {
  final String id;
  final String title;
  final String artist;
  final String artistId;
  final String? album;
  final String? albumId;
  final String? year;
  final String? genres;
  final String? tags;
  final String? youtubeId;
  final String? ytmBrowseId;
  final String? spotifyId;
  final String? sourceChannelId;
  final String? artworkUrl;
  final String? localArtworkPath;
  final double? bpm;
  final double? energy;
  final double? danceability;
  final String? key;
  final String? mode;
  final int playCount;
  final int skipCount;
  final int replayCount;
  final int? lastPlayed;
  final bool liked;
  final bool downloaded;
  final String? downloadedPath;
  final bool cachedAudio;
  final double graphScore;
  const TrackEntity({
    required this.id,
    required this.title,
    required this.artist,
    required this.artistId,
    this.album,
    this.albumId,
    this.year,
    this.genres,
    this.tags,
    this.youtubeId,
    this.ytmBrowseId,
    this.spotifyId,
    this.sourceChannelId,
    this.artworkUrl,
    this.localArtworkPath,
    this.bpm,
    this.energy,
    this.danceability,
    this.key,
    this.mode,
    required this.playCount,
    required this.skipCount,
    required this.replayCount,
    this.lastPlayed,
    required this.liked,
    required this.downloaded,
    this.downloadedPath,
    required this.cachedAudio,
    required this.graphScore,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['title'] = Variable<String>(title);
    map['artist'] = Variable<String>(artist);
    map['artist_id'] = Variable<String>(artistId);
    if (!nullToAbsent || album != null) {
      map['album'] = Variable<String>(album);
    }
    if (!nullToAbsent || albumId != null) {
      map['album_id'] = Variable<String>(albumId);
    }
    if (!nullToAbsent || year != null) {
      map['year'] = Variable<String>(year);
    }
    if (!nullToAbsent || genres != null) {
      map['genres'] = Variable<String>(genres);
    }
    if (!nullToAbsent || tags != null) {
      map['tags'] = Variable<String>(tags);
    }
    if (!nullToAbsent || youtubeId != null) {
      map['youtube_id'] = Variable<String>(youtubeId);
    }
    if (!nullToAbsent || ytmBrowseId != null) {
      map['ytm_browse_id'] = Variable<String>(ytmBrowseId);
    }
    if (!nullToAbsent || spotifyId != null) {
      map['spotify_id'] = Variable<String>(spotifyId);
    }
    if (!nullToAbsent || sourceChannelId != null) {
      map['source_channel_id'] = Variable<String>(sourceChannelId);
    }
    if (!nullToAbsent || artworkUrl != null) {
      map['artwork_url'] = Variable<String>(artworkUrl);
    }
    if (!nullToAbsent || localArtworkPath != null) {
      map['local_artwork_path'] = Variable<String>(localArtworkPath);
    }
    if (!nullToAbsent || bpm != null) {
      map['bpm'] = Variable<double>(bpm);
    }
    if (!nullToAbsent || energy != null) {
      map['energy'] = Variable<double>(energy);
    }
    if (!nullToAbsent || danceability != null) {
      map['danceability'] = Variable<double>(danceability);
    }
    if (!nullToAbsent || key != null) {
      map['key'] = Variable<String>(key);
    }
    if (!nullToAbsent || mode != null) {
      map['mode'] = Variable<String>(mode);
    }
    map['play_count'] = Variable<int>(playCount);
    map['skip_count'] = Variable<int>(skipCount);
    map['replay_count'] = Variable<int>(replayCount);
    if (!nullToAbsent || lastPlayed != null) {
      map['last_played'] = Variable<int>(lastPlayed);
    }
    map['liked'] = Variable<bool>(liked);
    map['downloaded'] = Variable<bool>(downloaded);
    if (!nullToAbsent || downloadedPath != null) {
      map['downloaded_path'] = Variable<String>(downloadedPath);
    }
    map['cached_audio'] = Variable<bool>(cachedAudio);
    map['graph_score'] = Variable<double>(graphScore);
    return map;
  }

  TracksCompanion toCompanion(bool nullToAbsent) {
    return TracksCompanion(
      id: Value(id),
      title: Value(title),
      artist: Value(artist),
      artistId: Value(artistId),
      album: album == null && nullToAbsent
          ? const Value.absent()
          : Value(album),
      albumId: albumId == null && nullToAbsent
          ? const Value.absent()
          : Value(albumId),
      year: year == null && nullToAbsent ? const Value.absent() : Value(year),
      genres: genres == null && nullToAbsent
          ? const Value.absent()
          : Value(genres),
      tags: tags == null && nullToAbsent ? const Value.absent() : Value(tags),
      youtubeId: youtubeId == null && nullToAbsent
          ? const Value.absent()
          : Value(youtubeId),
      ytmBrowseId: ytmBrowseId == null && nullToAbsent
          ? const Value.absent()
          : Value(ytmBrowseId),
      spotifyId: spotifyId == null && nullToAbsent
          ? const Value.absent()
          : Value(spotifyId),
      sourceChannelId: sourceChannelId == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceChannelId),
      artworkUrl: artworkUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(artworkUrl),
      localArtworkPath: localArtworkPath == null && nullToAbsent
          ? const Value.absent()
          : Value(localArtworkPath),
      bpm: bpm == null && nullToAbsent ? const Value.absent() : Value(bpm),
      energy: energy == null && nullToAbsent
          ? const Value.absent()
          : Value(energy),
      danceability: danceability == null && nullToAbsent
          ? const Value.absent()
          : Value(danceability),
      key: key == null && nullToAbsent ? const Value.absent() : Value(key),
      mode: mode == null && nullToAbsent ? const Value.absent() : Value(mode),
      playCount: Value(playCount),
      skipCount: Value(skipCount),
      replayCount: Value(replayCount),
      lastPlayed: lastPlayed == null && nullToAbsent
          ? const Value.absent()
          : Value(lastPlayed),
      liked: Value(liked),
      downloaded: Value(downloaded),
      downloadedPath: downloadedPath == null && nullToAbsent
          ? const Value.absent()
          : Value(downloadedPath),
      cachedAudio: Value(cachedAudio),
      graphScore: Value(graphScore),
    );
  }

  factory TrackEntity.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TrackEntity(
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      artist: serializer.fromJson<String>(json['artist']),
      artistId: serializer.fromJson<String>(json['artistId']),
      album: serializer.fromJson<String?>(json['album']),
      albumId: serializer.fromJson<String?>(json['albumId']),
      year: serializer.fromJson<String?>(json['year']),
      genres: serializer.fromJson<String?>(json['genres']),
      tags: serializer.fromJson<String?>(json['tags']),
      youtubeId: serializer.fromJson<String?>(json['youtubeId']),
      ytmBrowseId: serializer.fromJson<String?>(json['ytmBrowseId']),
      spotifyId: serializer.fromJson<String?>(json['spotifyId']),
      sourceChannelId: serializer.fromJson<String?>(json['sourceChannelId']),
      artworkUrl: serializer.fromJson<String?>(json['artworkUrl']),
      localArtworkPath: serializer.fromJson<String?>(json['localArtworkPath']),
      bpm: serializer.fromJson<double?>(json['bpm']),
      energy: serializer.fromJson<double?>(json['energy']),
      danceability: serializer.fromJson<double?>(json['danceability']),
      key: serializer.fromJson<String?>(json['key']),
      mode: serializer.fromJson<String?>(json['mode']),
      playCount: serializer.fromJson<int>(json['playCount']),
      skipCount: serializer.fromJson<int>(json['skipCount']),
      replayCount: serializer.fromJson<int>(json['replayCount']),
      lastPlayed: serializer.fromJson<int?>(json['lastPlayed']),
      liked: serializer.fromJson<bool>(json['liked']),
      downloaded: serializer.fromJson<bool>(json['downloaded']),
      downloadedPath: serializer.fromJson<String?>(json['downloadedPath']),
      cachedAudio: serializer.fromJson<bool>(json['cachedAudio']),
      graphScore: serializer.fromJson<double>(json['graphScore']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String>(title),
      'artist': serializer.toJson<String>(artist),
      'artistId': serializer.toJson<String>(artistId),
      'album': serializer.toJson<String?>(album),
      'albumId': serializer.toJson<String?>(albumId),
      'year': serializer.toJson<String?>(year),
      'genres': serializer.toJson<String?>(genres),
      'tags': serializer.toJson<String?>(tags),
      'youtubeId': serializer.toJson<String?>(youtubeId),
      'ytmBrowseId': serializer.toJson<String?>(ytmBrowseId),
      'spotifyId': serializer.toJson<String?>(spotifyId),
      'sourceChannelId': serializer.toJson<String?>(sourceChannelId),
      'artworkUrl': serializer.toJson<String?>(artworkUrl),
      'localArtworkPath': serializer.toJson<String?>(localArtworkPath),
      'bpm': serializer.toJson<double?>(bpm),
      'energy': serializer.toJson<double?>(energy),
      'danceability': serializer.toJson<double?>(danceability),
      'key': serializer.toJson<String?>(key),
      'mode': serializer.toJson<String?>(mode),
      'playCount': serializer.toJson<int>(playCount),
      'skipCount': serializer.toJson<int>(skipCount),
      'replayCount': serializer.toJson<int>(replayCount),
      'lastPlayed': serializer.toJson<int?>(lastPlayed),
      'liked': serializer.toJson<bool>(liked),
      'downloaded': serializer.toJson<bool>(downloaded),
      'downloadedPath': serializer.toJson<String?>(downloadedPath),
      'cachedAudio': serializer.toJson<bool>(cachedAudio),
      'graphScore': serializer.toJson<double>(graphScore),
    };
  }

  TrackEntity copyWith({
    String? id,
    String? title,
    String? artist,
    String? artistId,
    Value<String?> album = const Value.absent(),
    Value<String?> albumId = const Value.absent(),
    Value<String?> year = const Value.absent(),
    Value<String?> genres = const Value.absent(),
    Value<String?> tags = const Value.absent(),
    Value<String?> youtubeId = const Value.absent(),
    Value<String?> ytmBrowseId = const Value.absent(),
    Value<String?> spotifyId = const Value.absent(),
    Value<String?> sourceChannelId = const Value.absent(),
    Value<String?> artworkUrl = const Value.absent(),
    Value<String?> localArtworkPath = const Value.absent(),
    Value<double?> bpm = const Value.absent(),
    Value<double?> energy = const Value.absent(),
    Value<double?> danceability = const Value.absent(),
    Value<String?> key = const Value.absent(),
    Value<String?> mode = const Value.absent(),
    int? playCount,
    int? skipCount,
    int? replayCount,
    Value<int?> lastPlayed = const Value.absent(),
    bool? liked,
    bool? downloaded,
    Value<String?> downloadedPath = const Value.absent(),
    bool? cachedAudio,
    double? graphScore,
  }) => TrackEntity(
    id: id ?? this.id,
    title: title ?? this.title,
    artist: artist ?? this.artist,
    artistId: artistId ?? this.artistId,
    album: album.present ? album.value : this.album,
    albumId: albumId.present ? albumId.value : this.albumId,
    year: year.present ? year.value : this.year,
    genres: genres.present ? genres.value : this.genres,
    tags: tags.present ? tags.value : this.tags,
    youtubeId: youtubeId.present ? youtubeId.value : this.youtubeId,
    ytmBrowseId: ytmBrowseId.present ? ytmBrowseId.value : this.ytmBrowseId,
    spotifyId: spotifyId.present ? spotifyId.value : this.spotifyId,
    sourceChannelId: sourceChannelId.present
        ? sourceChannelId.value
        : this.sourceChannelId,
    artworkUrl: artworkUrl.present ? artworkUrl.value : this.artworkUrl,
    localArtworkPath: localArtworkPath.present
        ? localArtworkPath.value
        : this.localArtworkPath,
    bpm: bpm.present ? bpm.value : this.bpm,
    energy: energy.present ? energy.value : this.energy,
    danceability: danceability.present ? danceability.value : this.danceability,
    key: key.present ? key.value : this.key,
    mode: mode.present ? mode.value : this.mode,
    playCount: playCount ?? this.playCount,
    skipCount: skipCount ?? this.skipCount,
    replayCount: replayCount ?? this.replayCount,
    lastPlayed: lastPlayed.present ? lastPlayed.value : this.lastPlayed,
    liked: liked ?? this.liked,
    downloaded: downloaded ?? this.downloaded,
    downloadedPath: downloadedPath.present
        ? downloadedPath.value
        : this.downloadedPath,
    cachedAudio: cachedAudio ?? this.cachedAudio,
    graphScore: graphScore ?? this.graphScore,
  );
  TrackEntity copyWithCompanion(TracksCompanion data) {
    return TrackEntity(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      artist: data.artist.present ? data.artist.value : this.artist,
      artistId: data.artistId.present ? data.artistId.value : this.artistId,
      album: data.album.present ? data.album.value : this.album,
      albumId: data.albumId.present ? data.albumId.value : this.albumId,
      year: data.year.present ? data.year.value : this.year,
      genres: data.genres.present ? data.genres.value : this.genres,
      tags: data.tags.present ? data.tags.value : this.tags,
      youtubeId: data.youtubeId.present ? data.youtubeId.value : this.youtubeId,
      ytmBrowseId: data.ytmBrowseId.present
          ? data.ytmBrowseId.value
          : this.ytmBrowseId,
      spotifyId: data.spotifyId.present ? data.spotifyId.value : this.spotifyId,
      sourceChannelId: data.sourceChannelId.present
          ? data.sourceChannelId.value
          : this.sourceChannelId,
      artworkUrl: data.artworkUrl.present
          ? data.artworkUrl.value
          : this.artworkUrl,
      localArtworkPath: data.localArtworkPath.present
          ? data.localArtworkPath.value
          : this.localArtworkPath,
      bpm: data.bpm.present ? data.bpm.value : this.bpm,
      energy: data.energy.present ? data.energy.value : this.energy,
      danceability: data.danceability.present
          ? data.danceability.value
          : this.danceability,
      key: data.key.present ? data.key.value : this.key,
      mode: data.mode.present ? data.mode.value : this.mode,
      playCount: data.playCount.present ? data.playCount.value : this.playCount,
      skipCount: data.skipCount.present ? data.skipCount.value : this.skipCount,
      replayCount: data.replayCount.present
          ? data.replayCount.value
          : this.replayCount,
      lastPlayed: data.lastPlayed.present
          ? data.lastPlayed.value
          : this.lastPlayed,
      liked: data.liked.present ? data.liked.value : this.liked,
      downloaded: data.downloaded.present
          ? data.downloaded.value
          : this.downloaded,
      downloadedPath: data.downloadedPath.present
          ? data.downloadedPath.value
          : this.downloadedPath,
      cachedAudio: data.cachedAudio.present
          ? data.cachedAudio.value
          : this.cachedAudio,
      graphScore: data.graphScore.present
          ? data.graphScore.value
          : this.graphScore,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TrackEntity(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('artist: $artist, ')
          ..write('artistId: $artistId, ')
          ..write('album: $album, ')
          ..write('albumId: $albumId, ')
          ..write('year: $year, ')
          ..write('genres: $genres, ')
          ..write('tags: $tags, ')
          ..write('youtubeId: $youtubeId, ')
          ..write('ytmBrowseId: $ytmBrowseId, ')
          ..write('spotifyId: $spotifyId, ')
          ..write('sourceChannelId: $sourceChannelId, ')
          ..write('artworkUrl: $artworkUrl, ')
          ..write('localArtworkPath: $localArtworkPath, ')
          ..write('bpm: $bpm, ')
          ..write('energy: $energy, ')
          ..write('danceability: $danceability, ')
          ..write('key: $key, ')
          ..write('mode: $mode, ')
          ..write('playCount: $playCount, ')
          ..write('skipCount: $skipCount, ')
          ..write('replayCount: $replayCount, ')
          ..write('lastPlayed: $lastPlayed, ')
          ..write('liked: $liked, ')
          ..write('downloaded: $downloaded, ')
          ..write('downloadedPath: $downloadedPath, ')
          ..write('cachedAudio: $cachedAudio, ')
          ..write('graphScore: $graphScore')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
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
    bpm,
    energy,
    danceability,
    key,
    mode,
    playCount,
    skipCount,
    replayCount,
    lastPlayed,
    liked,
    downloaded,
    downloadedPath,
    cachedAudio,
    graphScore,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TrackEntity &&
          other.id == this.id &&
          other.title == this.title &&
          other.artist == this.artist &&
          other.artistId == this.artistId &&
          other.album == this.album &&
          other.albumId == this.albumId &&
          other.year == this.year &&
          other.genres == this.genres &&
          other.tags == this.tags &&
          other.youtubeId == this.youtubeId &&
          other.ytmBrowseId == this.ytmBrowseId &&
          other.spotifyId == this.spotifyId &&
          other.sourceChannelId == this.sourceChannelId &&
          other.artworkUrl == this.artworkUrl &&
          other.localArtworkPath == this.localArtworkPath &&
          other.bpm == this.bpm &&
          other.energy == this.energy &&
          other.danceability == this.danceability &&
          other.key == this.key &&
          other.mode == this.mode &&
          other.playCount == this.playCount &&
          other.skipCount == this.skipCount &&
          other.replayCount == this.replayCount &&
          other.lastPlayed == this.lastPlayed &&
          other.liked == this.liked &&
          other.downloaded == this.downloaded &&
          other.downloadedPath == this.downloadedPath &&
          other.cachedAudio == this.cachedAudio &&
          other.graphScore == this.graphScore);
}

class TracksCompanion extends UpdateCompanion<TrackEntity> {
  final Value<String> id;
  final Value<String> title;
  final Value<String> artist;
  final Value<String> artistId;
  final Value<String?> album;
  final Value<String?> albumId;
  final Value<String?> year;
  final Value<String?> genres;
  final Value<String?> tags;
  final Value<String?> youtubeId;
  final Value<String?> ytmBrowseId;
  final Value<String?> spotifyId;
  final Value<String?> sourceChannelId;
  final Value<String?> artworkUrl;
  final Value<String?> localArtworkPath;
  final Value<double?> bpm;
  final Value<double?> energy;
  final Value<double?> danceability;
  final Value<String?> key;
  final Value<String?> mode;
  final Value<int> playCount;
  final Value<int> skipCount;
  final Value<int> replayCount;
  final Value<int?> lastPlayed;
  final Value<bool> liked;
  final Value<bool> downloaded;
  final Value<String?> downloadedPath;
  final Value<bool> cachedAudio;
  final Value<double> graphScore;
  final Value<int> rowid;
  const TracksCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.artist = const Value.absent(),
    this.artistId = const Value.absent(),
    this.album = const Value.absent(),
    this.albumId = const Value.absent(),
    this.year = const Value.absent(),
    this.genres = const Value.absent(),
    this.tags = const Value.absent(),
    this.youtubeId = const Value.absent(),
    this.ytmBrowseId = const Value.absent(),
    this.spotifyId = const Value.absent(),
    this.sourceChannelId = const Value.absent(),
    this.artworkUrl = const Value.absent(),
    this.localArtworkPath = const Value.absent(),
    this.bpm = const Value.absent(),
    this.energy = const Value.absent(),
    this.danceability = const Value.absent(),
    this.key = const Value.absent(),
    this.mode = const Value.absent(),
    this.playCount = const Value.absent(),
    this.skipCount = const Value.absent(),
    this.replayCount = const Value.absent(),
    this.lastPlayed = const Value.absent(),
    this.liked = const Value.absent(),
    this.downloaded = const Value.absent(),
    this.downloadedPath = const Value.absent(),
    this.cachedAudio = const Value.absent(),
    this.graphScore = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TracksCompanion.insert({
    required String id,
    required String title,
    required String artist,
    required String artistId,
    this.album = const Value.absent(),
    this.albumId = const Value.absent(),
    this.year = const Value.absent(),
    this.genres = const Value.absent(),
    this.tags = const Value.absent(),
    this.youtubeId = const Value.absent(),
    this.ytmBrowseId = const Value.absent(),
    this.spotifyId = const Value.absent(),
    this.sourceChannelId = const Value.absent(),
    this.artworkUrl = const Value.absent(),
    this.localArtworkPath = const Value.absent(),
    this.bpm = const Value.absent(),
    this.energy = const Value.absent(),
    this.danceability = const Value.absent(),
    this.key = const Value.absent(),
    this.mode = const Value.absent(),
    this.playCount = const Value.absent(),
    this.skipCount = const Value.absent(),
    this.replayCount = const Value.absent(),
    this.lastPlayed = const Value.absent(),
    this.liked = const Value.absent(),
    this.downloaded = const Value.absent(),
    this.downloadedPath = const Value.absent(),
    this.cachedAudio = const Value.absent(),
    this.graphScore = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       title = Value(title),
       artist = Value(artist),
       artistId = Value(artistId);
  static Insertable<TrackEntity> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<String>? artist,
    Expression<String>? artistId,
    Expression<String>? album,
    Expression<String>? albumId,
    Expression<String>? year,
    Expression<String>? genres,
    Expression<String>? tags,
    Expression<String>? youtubeId,
    Expression<String>? ytmBrowseId,
    Expression<String>? spotifyId,
    Expression<String>? sourceChannelId,
    Expression<String>? artworkUrl,
    Expression<String>? localArtworkPath,
    Expression<double>? bpm,
    Expression<double>? energy,
    Expression<double>? danceability,
    Expression<String>? key,
    Expression<String>? mode,
    Expression<int>? playCount,
    Expression<int>? skipCount,
    Expression<int>? replayCount,
    Expression<int>? lastPlayed,
    Expression<bool>? liked,
    Expression<bool>? downloaded,
    Expression<String>? downloadedPath,
    Expression<bool>? cachedAudio,
    Expression<double>? graphScore,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (artist != null) 'artist': artist,
      if (artistId != null) 'artist_id': artistId,
      if (album != null) 'album': album,
      if (albumId != null) 'album_id': albumId,
      if (year != null) 'year': year,
      if (genres != null) 'genres': genres,
      if (tags != null) 'tags': tags,
      if (youtubeId != null) 'youtube_id': youtubeId,
      if (ytmBrowseId != null) 'ytm_browse_id': ytmBrowseId,
      if (spotifyId != null) 'spotify_id': spotifyId,
      if (sourceChannelId != null) 'source_channel_id': sourceChannelId,
      if (artworkUrl != null) 'artwork_url': artworkUrl,
      if (localArtworkPath != null) 'local_artwork_path': localArtworkPath,
      if (bpm != null) 'bpm': bpm,
      if (energy != null) 'energy': energy,
      if (danceability != null) 'danceability': danceability,
      if (key != null) 'key': key,
      if (mode != null) 'mode': mode,
      if (playCount != null) 'play_count': playCount,
      if (skipCount != null) 'skip_count': skipCount,
      if (replayCount != null) 'replay_count': replayCount,
      if (lastPlayed != null) 'last_played': lastPlayed,
      if (liked != null) 'liked': liked,
      if (downloaded != null) 'downloaded': downloaded,
      if (downloadedPath != null) 'downloaded_path': downloadedPath,
      if (cachedAudio != null) 'cached_audio': cachedAudio,
      if (graphScore != null) 'graph_score': graphScore,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TracksCompanion copyWith({
    Value<String>? id,
    Value<String>? title,
    Value<String>? artist,
    Value<String>? artistId,
    Value<String?>? album,
    Value<String?>? albumId,
    Value<String?>? year,
    Value<String?>? genres,
    Value<String?>? tags,
    Value<String?>? youtubeId,
    Value<String?>? ytmBrowseId,
    Value<String?>? spotifyId,
    Value<String?>? sourceChannelId,
    Value<String?>? artworkUrl,
    Value<String?>? localArtworkPath,
    Value<double?>? bpm,
    Value<double?>? energy,
    Value<double?>? danceability,
    Value<String?>? key,
    Value<String?>? mode,
    Value<int>? playCount,
    Value<int>? skipCount,
    Value<int>? replayCount,
    Value<int?>? lastPlayed,
    Value<bool>? liked,
    Value<bool>? downloaded,
    Value<String?>? downloadedPath,
    Value<bool>? cachedAudio,
    Value<double>? graphScore,
    Value<int>? rowid,
  }) {
    return TracksCompanion(
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
      bpm: bpm ?? this.bpm,
      energy: energy ?? this.energy,
      danceability: danceability ?? this.danceability,
      key: key ?? this.key,
      mode: mode ?? this.mode,
      playCount: playCount ?? this.playCount,
      skipCount: skipCount ?? this.skipCount,
      replayCount: replayCount ?? this.replayCount,
      lastPlayed: lastPlayed ?? this.lastPlayed,
      liked: liked ?? this.liked,
      downloaded: downloaded ?? this.downloaded,
      downloadedPath: downloadedPath ?? this.downloadedPath,
      cachedAudio: cachedAudio ?? this.cachedAudio,
      graphScore: graphScore ?? this.graphScore,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (artist.present) {
      map['artist'] = Variable<String>(artist.value);
    }
    if (artistId.present) {
      map['artist_id'] = Variable<String>(artistId.value);
    }
    if (album.present) {
      map['album'] = Variable<String>(album.value);
    }
    if (albumId.present) {
      map['album_id'] = Variable<String>(albumId.value);
    }
    if (year.present) {
      map['year'] = Variable<String>(year.value);
    }
    if (genres.present) {
      map['genres'] = Variable<String>(genres.value);
    }
    if (tags.present) {
      map['tags'] = Variable<String>(tags.value);
    }
    if (youtubeId.present) {
      map['youtube_id'] = Variable<String>(youtubeId.value);
    }
    if (ytmBrowseId.present) {
      map['ytm_browse_id'] = Variable<String>(ytmBrowseId.value);
    }
    if (spotifyId.present) {
      map['spotify_id'] = Variable<String>(spotifyId.value);
    }
    if (sourceChannelId.present) {
      map['source_channel_id'] = Variable<String>(sourceChannelId.value);
    }
    if (artworkUrl.present) {
      map['artwork_url'] = Variable<String>(artworkUrl.value);
    }
    if (localArtworkPath.present) {
      map['local_artwork_path'] = Variable<String>(localArtworkPath.value);
    }
    if (bpm.present) {
      map['bpm'] = Variable<double>(bpm.value);
    }
    if (energy.present) {
      map['energy'] = Variable<double>(energy.value);
    }
    if (danceability.present) {
      map['danceability'] = Variable<double>(danceability.value);
    }
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (mode.present) {
      map['mode'] = Variable<String>(mode.value);
    }
    if (playCount.present) {
      map['play_count'] = Variable<int>(playCount.value);
    }
    if (skipCount.present) {
      map['skip_count'] = Variable<int>(skipCount.value);
    }
    if (replayCount.present) {
      map['replay_count'] = Variable<int>(replayCount.value);
    }
    if (lastPlayed.present) {
      map['last_played'] = Variable<int>(lastPlayed.value);
    }
    if (liked.present) {
      map['liked'] = Variable<bool>(liked.value);
    }
    if (downloaded.present) {
      map['downloaded'] = Variable<bool>(downloaded.value);
    }
    if (downloadedPath.present) {
      map['downloaded_path'] = Variable<String>(downloadedPath.value);
    }
    if (cachedAudio.present) {
      map['cached_audio'] = Variable<bool>(cachedAudio.value);
    }
    if (graphScore.present) {
      map['graph_score'] = Variable<double>(graphScore.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TracksCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('artist: $artist, ')
          ..write('artistId: $artistId, ')
          ..write('album: $album, ')
          ..write('albumId: $albumId, ')
          ..write('year: $year, ')
          ..write('genres: $genres, ')
          ..write('tags: $tags, ')
          ..write('youtubeId: $youtubeId, ')
          ..write('ytmBrowseId: $ytmBrowseId, ')
          ..write('spotifyId: $spotifyId, ')
          ..write('sourceChannelId: $sourceChannelId, ')
          ..write('artworkUrl: $artworkUrl, ')
          ..write('localArtworkPath: $localArtworkPath, ')
          ..write('bpm: $bpm, ')
          ..write('energy: $energy, ')
          ..write('danceability: $danceability, ')
          ..write('key: $key, ')
          ..write('mode: $mode, ')
          ..write('playCount: $playCount, ')
          ..write('skipCount: $skipCount, ')
          ..write('replayCount: $replayCount, ')
          ..write('lastPlayed: $lastPlayed, ')
          ..write('liked: $liked, ')
          ..write('downloaded: $downloaded, ')
          ..write('downloadedPath: $downloadedPath, ')
          ..write('cachedAudio: $cachedAudio, ')
          ..write('graphScore: $graphScore, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ListenEventsTable extends ListenEvents
    with TableInfo<$ListenEventsTable, ListenEventEntity> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ListenEventsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _trackIdMeta = const VerificationMeta(
    'trackId',
  );
  @override
  late final GeneratedColumn<String> trackId = GeneratedColumn<String>(
    'track_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _eventTypeMeta = const VerificationMeta(
    'eventType',
  );
  @override
  late final GeneratedColumn<String> eventType = GeneratedColumn<String>(
    'event_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _timestampMeta = const VerificationMeta(
    'timestamp',
  );
  @override
  late final GeneratedColumn<int> timestamp = GeneratedColumn<int>(
    'timestamp',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _listenDurationSecondsMeta =
      const VerificationMeta('listenDurationSeconds');
  @override
  late final GeneratedColumn<int> listenDurationSeconds = GeneratedColumn<int>(
    'listen_duration_seconds',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sourceUserIdMeta = const VerificationMeta(
    'sourceUserId',
  );
  @override
  late final GeneratedColumn<String> sourceUserId = GeneratedColumn<String>(
    'source_user_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    trackId,
    eventType,
    timestamp,
    listenDurationSeconds,
    sourceUserId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'listen_events';
  @override
  VerificationContext validateIntegrity(
    Insertable<ListenEventEntity> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('track_id')) {
      context.handle(
        _trackIdMeta,
        trackId.isAcceptableOrUnknown(data['track_id']!, _trackIdMeta),
      );
    } else if (isInserting) {
      context.missing(_trackIdMeta);
    }
    if (data.containsKey('event_type')) {
      context.handle(
        _eventTypeMeta,
        eventType.isAcceptableOrUnknown(data['event_type']!, _eventTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_eventTypeMeta);
    }
    if (data.containsKey('timestamp')) {
      context.handle(
        _timestampMeta,
        timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta),
      );
    } else if (isInserting) {
      context.missing(_timestampMeta);
    }
    if (data.containsKey('listen_duration_seconds')) {
      context.handle(
        _listenDurationSecondsMeta,
        listenDurationSeconds.isAcceptableOrUnknown(
          data['listen_duration_seconds']!,
          _listenDurationSecondsMeta,
        ),
      );
    }
    if (data.containsKey('source_user_id')) {
      context.handle(
        _sourceUserIdMeta,
        sourceUserId.isAcceptableOrUnknown(
          data['source_user_id']!,
          _sourceUserIdMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ListenEventEntity map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ListenEventEntity(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      trackId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}track_id'],
      )!,
      eventType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}event_type'],
      )!,
      timestamp: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}timestamp'],
      )!,
      listenDurationSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}listen_duration_seconds'],
      ),
      sourceUserId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_user_id'],
      ),
    );
  }

  @override
  $ListenEventsTable createAlias(String alias) {
    return $ListenEventsTable(attachedDatabase, alias);
  }
}

class ListenEventEntity extends DataClass
    implements Insertable<ListenEventEntity> {
  final String id;
  final String trackId;
  final String eventType;
  final int timestamp;
  final int? listenDurationSeconds;
  final String? sourceUserId;
  const ListenEventEntity({
    required this.id,
    required this.trackId,
    required this.eventType,
    required this.timestamp,
    this.listenDurationSeconds,
    this.sourceUserId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['track_id'] = Variable<String>(trackId);
    map['event_type'] = Variable<String>(eventType);
    map['timestamp'] = Variable<int>(timestamp);
    if (!nullToAbsent || listenDurationSeconds != null) {
      map['listen_duration_seconds'] = Variable<int>(listenDurationSeconds);
    }
    if (!nullToAbsent || sourceUserId != null) {
      map['source_user_id'] = Variable<String>(sourceUserId);
    }
    return map;
  }

  ListenEventsCompanion toCompanion(bool nullToAbsent) {
    return ListenEventsCompanion(
      id: Value(id),
      trackId: Value(trackId),
      eventType: Value(eventType),
      timestamp: Value(timestamp),
      listenDurationSeconds: listenDurationSeconds == null && nullToAbsent
          ? const Value.absent()
          : Value(listenDurationSeconds),
      sourceUserId: sourceUserId == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceUserId),
    );
  }

  factory ListenEventEntity.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ListenEventEntity(
      id: serializer.fromJson<String>(json['id']),
      trackId: serializer.fromJson<String>(json['trackId']),
      eventType: serializer.fromJson<String>(json['eventType']),
      timestamp: serializer.fromJson<int>(json['timestamp']),
      listenDurationSeconds: serializer.fromJson<int?>(
        json['listenDurationSeconds'],
      ),
      sourceUserId: serializer.fromJson<String?>(json['sourceUserId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'trackId': serializer.toJson<String>(trackId),
      'eventType': serializer.toJson<String>(eventType),
      'timestamp': serializer.toJson<int>(timestamp),
      'listenDurationSeconds': serializer.toJson<int?>(listenDurationSeconds),
      'sourceUserId': serializer.toJson<String?>(sourceUserId),
    };
  }

  ListenEventEntity copyWith({
    String? id,
    String? trackId,
    String? eventType,
    int? timestamp,
    Value<int?> listenDurationSeconds = const Value.absent(),
    Value<String?> sourceUserId = const Value.absent(),
  }) => ListenEventEntity(
    id: id ?? this.id,
    trackId: trackId ?? this.trackId,
    eventType: eventType ?? this.eventType,
    timestamp: timestamp ?? this.timestamp,
    listenDurationSeconds: listenDurationSeconds.present
        ? listenDurationSeconds.value
        : this.listenDurationSeconds,
    sourceUserId: sourceUserId.present ? sourceUserId.value : this.sourceUserId,
  );
  ListenEventEntity copyWithCompanion(ListenEventsCompanion data) {
    return ListenEventEntity(
      id: data.id.present ? data.id.value : this.id,
      trackId: data.trackId.present ? data.trackId.value : this.trackId,
      eventType: data.eventType.present ? data.eventType.value : this.eventType,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
      listenDurationSeconds: data.listenDurationSeconds.present
          ? data.listenDurationSeconds.value
          : this.listenDurationSeconds,
      sourceUserId: data.sourceUserId.present
          ? data.sourceUserId.value
          : this.sourceUserId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ListenEventEntity(')
          ..write('id: $id, ')
          ..write('trackId: $trackId, ')
          ..write('eventType: $eventType, ')
          ..write('timestamp: $timestamp, ')
          ..write('listenDurationSeconds: $listenDurationSeconds, ')
          ..write('sourceUserId: $sourceUserId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    trackId,
    eventType,
    timestamp,
    listenDurationSeconds,
    sourceUserId,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ListenEventEntity &&
          other.id == this.id &&
          other.trackId == this.trackId &&
          other.eventType == this.eventType &&
          other.timestamp == this.timestamp &&
          other.listenDurationSeconds == this.listenDurationSeconds &&
          other.sourceUserId == this.sourceUserId);
}

class ListenEventsCompanion extends UpdateCompanion<ListenEventEntity> {
  final Value<String> id;
  final Value<String> trackId;
  final Value<String> eventType;
  final Value<int> timestamp;
  final Value<int?> listenDurationSeconds;
  final Value<String?> sourceUserId;
  final Value<int> rowid;
  const ListenEventsCompanion({
    this.id = const Value.absent(),
    this.trackId = const Value.absent(),
    this.eventType = const Value.absent(),
    this.timestamp = const Value.absent(),
    this.listenDurationSeconds = const Value.absent(),
    this.sourceUserId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ListenEventsCompanion.insert({
    required String id,
    required String trackId,
    required String eventType,
    required int timestamp,
    this.listenDurationSeconds = const Value.absent(),
    this.sourceUserId = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       trackId = Value(trackId),
       eventType = Value(eventType),
       timestamp = Value(timestamp);
  static Insertable<ListenEventEntity> custom({
    Expression<String>? id,
    Expression<String>? trackId,
    Expression<String>? eventType,
    Expression<int>? timestamp,
    Expression<int>? listenDurationSeconds,
    Expression<String>? sourceUserId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (trackId != null) 'track_id': trackId,
      if (eventType != null) 'event_type': eventType,
      if (timestamp != null) 'timestamp': timestamp,
      if (listenDurationSeconds != null)
        'listen_duration_seconds': listenDurationSeconds,
      if (sourceUserId != null) 'source_user_id': sourceUserId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ListenEventsCompanion copyWith({
    Value<String>? id,
    Value<String>? trackId,
    Value<String>? eventType,
    Value<int>? timestamp,
    Value<int?>? listenDurationSeconds,
    Value<String?>? sourceUserId,
    Value<int>? rowid,
  }) {
    return ListenEventsCompanion(
      id: id ?? this.id,
      trackId: trackId ?? this.trackId,
      eventType: eventType ?? this.eventType,
      timestamp: timestamp ?? this.timestamp,
      listenDurationSeconds:
          listenDurationSeconds ?? this.listenDurationSeconds,
      sourceUserId: sourceUserId ?? this.sourceUserId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (trackId.present) {
      map['track_id'] = Variable<String>(trackId.value);
    }
    if (eventType.present) {
      map['event_type'] = Variable<String>(eventType.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<int>(timestamp.value);
    }
    if (listenDurationSeconds.present) {
      map['listen_duration_seconds'] = Variable<int>(
        listenDurationSeconds.value,
      );
    }
    if (sourceUserId.present) {
      map['source_user_id'] = Variable<String>(sourceUserId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ListenEventsCompanion(')
          ..write('id: $id, ')
          ..write('trackId: $trackId, ')
          ..write('eventType: $eventType, ')
          ..write('timestamp: $timestamp, ')
          ..write('listenDurationSeconds: $listenDurationSeconds, ')
          ..write('sourceUserId: $sourceUserId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $GraphNodesTable extends GraphNodes
    with TableInfo<$GraphNodesTable, GraphNodeEntity> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GraphNodesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nodeTypeMeta = const VerificationMeta(
    'nodeType',
  );
  @override
  late final GeneratedColumn<String> nodeType = GeneratedColumn<String>(
    'node_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _scoreMeta = const VerificationMeta('score');
  @override
  late final GeneratedColumn<double> score = GeneratedColumn<double>(
    'score',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
  );
  static const VerificationMeta _lastUpdatedMeta = const VerificationMeta(
    'lastUpdated',
  );
  @override
  late final GeneratedColumn<int> lastUpdated = GeneratedColumn<int>(
    'last_updated',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [id, nodeType, score, lastUpdated];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'graph_nodes';
  @override
  VerificationContext validateIntegrity(
    Insertable<GraphNodeEntity> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('node_type')) {
      context.handle(
        _nodeTypeMeta,
        nodeType.isAcceptableOrUnknown(data['node_type']!, _nodeTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_nodeTypeMeta);
    }
    if (data.containsKey('score')) {
      context.handle(
        _scoreMeta,
        score.isAcceptableOrUnknown(data['score']!, _scoreMeta),
      );
    }
    if (data.containsKey('last_updated')) {
      context.handle(
        _lastUpdatedMeta,
        lastUpdated.isAcceptableOrUnknown(
          data['last_updated']!,
          _lastUpdatedMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  GraphNodeEntity map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return GraphNodeEntity(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      nodeType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}node_type'],
      )!,
      score: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}score'],
      )!,
      lastUpdated: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_updated'],
      ),
    );
  }

  @override
  $GraphNodesTable createAlias(String alias) {
    return $GraphNodesTable(attachedDatabase, alias);
  }
}

class GraphNodeEntity extends DataClass implements Insertable<GraphNodeEntity> {
  final String id;
  final String nodeType;
  final double score;
  final int? lastUpdated;
  const GraphNodeEntity({
    required this.id,
    required this.nodeType,
    required this.score,
    this.lastUpdated,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['node_type'] = Variable<String>(nodeType);
    map['score'] = Variable<double>(score);
    if (!nullToAbsent || lastUpdated != null) {
      map['last_updated'] = Variable<int>(lastUpdated);
    }
    return map;
  }

  GraphNodesCompanion toCompanion(bool nullToAbsent) {
    return GraphNodesCompanion(
      id: Value(id),
      nodeType: Value(nodeType),
      score: Value(score),
      lastUpdated: lastUpdated == null && nullToAbsent
          ? const Value.absent()
          : Value(lastUpdated),
    );
  }

  factory GraphNodeEntity.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GraphNodeEntity(
      id: serializer.fromJson<String>(json['id']),
      nodeType: serializer.fromJson<String>(json['nodeType']),
      score: serializer.fromJson<double>(json['score']),
      lastUpdated: serializer.fromJson<int?>(json['lastUpdated']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'nodeType': serializer.toJson<String>(nodeType),
      'score': serializer.toJson<double>(score),
      'lastUpdated': serializer.toJson<int?>(lastUpdated),
    };
  }

  GraphNodeEntity copyWith({
    String? id,
    String? nodeType,
    double? score,
    Value<int?> lastUpdated = const Value.absent(),
  }) => GraphNodeEntity(
    id: id ?? this.id,
    nodeType: nodeType ?? this.nodeType,
    score: score ?? this.score,
    lastUpdated: lastUpdated.present ? lastUpdated.value : this.lastUpdated,
  );
  GraphNodeEntity copyWithCompanion(GraphNodesCompanion data) {
    return GraphNodeEntity(
      id: data.id.present ? data.id.value : this.id,
      nodeType: data.nodeType.present ? data.nodeType.value : this.nodeType,
      score: data.score.present ? data.score.value : this.score,
      lastUpdated: data.lastUpdated.present
          ? data.lastUpdated.value
          : this.lastUpdated,
    );
  }

  @override
  String toString() {
    return (StringBuffer('GraphNodeEntity(')
          ..write('id: $id, ')
          ..write('nodeType: $nodeType, ')
          ..write('score: $score, ')
          ..write('lastUpdated: $lastUpdated')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, nodeType, score, lastUpdated);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GraphNodeEntity &&
          other.id == this.id &&
          other.nodeType == this.nodeType &&
          other.score == this.score &&
          other.lastUpdated == this.lastUpdated);
}

class GraphNodesCompanion extends UpdateCompanion<GraphNodeEntity> {
  final Value<String> id;
  final Value<String> nodeType;
  final Value<double> score;
  final Value<int?> lastUpdated;
  final Value<int> rowid;
  const GraphNodesCompanion({
    this.id = const Value.absent(),
    this.nodeType = const Value.absent(),
    this.score = const Value.absent(),
    this.lastUpdated = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  GraphNodesCompanion.insert({
    required String id,
    required String nodeType,
    this.score = const Value.absent(),
    this.lastUpdated = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       nodeType = Value(nodeType);
  static Insertable<GraphNodeEntity> custom({
    Expression<String>? id,
    Expression<String>? nodeType,
    Expression<double>? score,
    Expression<int>? lastUpdated,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (nodeType != null) 'node_type': nodeType,
      if (score != null) 'score': score,
      if (lastUpdated != null) 'last_updated': lastUpdated,
      if (rowid != null) 'rowid': rowid,
    });
  }

  GraphNodesCompanion copyWith({
    Value<String>? id,
    Value<String>? nodeType,
    Value<double>? score,
    Value<int?>? lastUpdated,
    Value<int>? rowid,
  }) {
    return GraphNodesCompanion(
      id: id ?? this.id,
      nodeType: nodeType ?? this.nodeType,
      score: score ?? this.score,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (nodeType.present) {
      map['node_type'] = Variable<String>(nodeType.value);
    }
    if (score.present) {
      map['score'] = Variable<double>(score.value);
    }
    if (lastUpdated.present) {
      map['last_updated'] = Variable<int>(lastUpdated.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GraphNodesCompanion(')
          ..write('id: $id, ')
          ..write('nodeType: $nodeType, ')
          ..write('score: $score, ')
          ..write('lastUpdated: $lastUpdated, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $GraphEdgesTable extends GraphEdges
    with TableInfo<$GraphEdgesTable, GraphEdgeEntity> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GraphEdgesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _fromIdMeta = const VerificationMeta('fromId');
  @override
  late final GeneratedColumn<String> fromId = GeneratedColumn<String>(
    'from_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _toIdMeta = const VerificationMeta('toId');
  @override
  late final GeneratedColumn<String> toId = GeneratedColumn<String>(
    'to_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _weightMeta = const VerificationMeta('weight');
  @override
  late final GeneratedColumn<double> weight = GeneratedColumn<double>(
    'weight',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.1),
  );
  @override
  List<GeneratedColumn> get $columns => [fromId, toId, weight];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'graph_edges';
  @override
  VerificationContext validateIntegrity(
    Insertable<GraphEdgeEntity> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('from_id')) {
      context.handle(
        _fromIdMeta,
        fromId.isAcceptableOrUnknown(data['from_id']!, _fromIdMeta),
      );
    } else if (isInserting) {
      context.missing(_fromIdMeta);
    }
    if (data.containsKey('to_id')) {
      context.handle(
        _toIdMeta,
        toId.isAcceptableOrUnknown(data['to_id']!, _toIdMeta),
      );
    } else if (isInserting) {
      context.missing(_toIdMeta);
    }
    if (data.containsKey('weight')) {
      context.handle(
        _weightMeta,
        weight.isAcceptableOrUnknown(data['weight']!, _weightMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {fromId, toId};
  @override
  GraphEdgeEntity map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return GraphEdgeEntity(
      fromId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}from_id'],
      )!,
      toId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}to_id'],
      )!,
      weight: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}weight'],
      )!,
    );
  }

  @override
  $GraphEdgesTable createAlias(String alias) {
    return $GraphEdgesTable(attachedDatabase, alias);
  }
}

class GraphEdgeEntity extends DataClass implements Insertable<GraphEdgeEntity> {
  final String fromId;
  final String toId;
  final double weight;
  const GraphEdgeEntity({
    required this.fromId,
    required this.toId,
    required this.weight,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['from_id'] = Variable<String>(fromId);
    map['to_id'] = Variable<String>(toId);
    map['weight'] = Variable<double>(weight);
    return map;
  }

  GraphEdgesCompanion toCompanion(bool nullToAbsent) {
    return GraphEdgesCompanion(
      fromId: Value(fromId),
      toId: Value(toId),
      weight: Value(weight),
    );
  }

  factory GraphEdgeEntity.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GraphEdgeEntity(
      fromId: serializer.fromJson<String>(json['fromId']),
      toId: serializer.fromJson<String>(json['toId']),
      weight: serializer.fromJson<double>(json['weight']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'fromId': serializer.toJson<String>(fromId),
      'toId': serializer.toJson<String>(toId),
      'weight': serializer.toJson<double>(weight),
    };
  }

  GraphEdgeEntity copyWith({String? fromId, String? toId, double? weight}) =>
      GraphEdgeEntity(
        fromId: fromId ?? this.fromId,
        toId: toId ?? this.toId,
        weight: weight ?? this.weight,
      );
  GraphEdgeEntity copyWithCompanion(GraphEdgesCompanion data) {
    return GraphEdgeEntity(
      fromId: data.fromId.present ? data.fromId.value : this.fromId,
      toId: data.toId.present ? data.toId.value : this.toId,
      weight: data.weight.present ? data.weight.value : this.weight,
    );
  }

  @override
  String toString() {
    return (StringBuffer('GraphEdgeEntity(')
          ..write('fromId: $fromId, ')
          ..write('toId: $toId, ')
          ..write('weight: $weight')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(fromId, toId, weight);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GraphEdgeEntity &&
          other.fromId == this.fromId &&
          other.toId == this.toId &&
          other.weight == this.weight);
}

class GraphEdgesCompanion extends UpdateCompanion<GraphEdgeEntity> {
  final Value<String> fromId;
  final Value<String> toId;
  final Value<double> weight;
  final Value<int> rowid;
  const GraphEdgesCompanion({
    this.fromId = const Value.absent(),
    this.toId = const Value.absent(),
    this.weight = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  GraphEdgesCompanion.insert({
    required String fromId,
    required String toId,
    this.weight = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : fromId = Value(fromId),
       toId = Value(toId);
  static Insertable<GraphEdgeEntity> custom({
    Expression<String>? fromId,
    Expression<String>? toId,
    Expression<double>? weight,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (fromId != null) 'from_id': fromId,
      if (toId != null) 'to_id': toId,
      if (weight != null) 'weight': weight,
      if (rowid != null) 'rowid': rowid,
    });
  }

  GraphEdgesCompanion copyWith({
    Value<String>? fromId,
    Value<String>? toId,
    Value<double>? weight,
    Value<int>? rowid,
  }) {
    return GraphEdgesCompanion(
      fromId: fromId ?? this.fromId,
      toId: toId ?? this.toId,
      weight: weight ?? this.weight,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (fromId.present) {
      map['from_id'] = Variable<String>(fromId.value);
    }
    if (toId.present) {
      map['to_id'] = Variable<String>(toId.value);
    }
    if (weight.present) {
      map['weight'] = Variable<double>(weight.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GraphEdgesCompanion(')
          ..write('fromId: $fromId, ')
          ..write('toId: $toId, ')
          ..write('weight: $weight, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PlaylistsTable extends Playlists
    with TableInfo<$PlaylistsTable, PlaylistEntity> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlaylistsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sourceIdMeta = const VerificationMeta(
    'sourceId',
  );
  @override
  late final GeneratedColumn<String> sourceId = GeneratedColumn<String>(
    'source_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _ownerIdsMeta = const VerificationMeta(
    'ownerIds',
  );
  @override
  late final GeneratedColumn<String> ownerIds = GeneratedColumn<String>(
    'owner_ids',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    description,
    createdAt,
    type,
    sourceId,
    ownerIds,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'playlists';
  @override
  VerificationContext validateIntegrity(
    Insertable<PlaylistEntity> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    }
    if (data.containsKey('source_id')) {
      context.handle(
        _sourceIdMeta,
        sourceId.isAcceptableOrUnknown(data['source_id']!, _sourceIdMeta),
      );
    }
    if (data.containsKey('owner_ids')) {
      context.handle(
        _ownerIdsMeta,
        ownerIds.isAcceptableOrUnknown(data['owner_ids']!, _ownerIdsMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PlaylistEntity map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PlaylistEntity(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      ),
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      ),
      sourceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_id'],
      ),
      ownerIds: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}owner_ids'],
      ),
    );
  }

  @override
  $PlaylistsTable createAlias(String alias) {
    return $PlaylistsTable(attachedDatabase, alias);
  }
}

class PlaylistEntity extends DataClass implements Insertable<PlaylistEntity> {
  final String id;
  final String name;
  final String? description;
  final int? createdAt;
  final String? type;
  final String? sourceId;
  final String? ownerIds;
  const PlaylistEntity({
    required this.id,
    required this.name,
    this.description,
    this.createdAt,
    this.type,
    this.sourceId,
    this.ownerIds,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    if (!nullToAbsent || createdAt != null) {
      map['created_at'] = Variable<int>(createdAt);
    }
    if (!nullToAbsent || type != null) {
      map['type'] = Variable<String>(type);
    }
    if (!nullToAbsent || sourceId != null) {
      map['source_id'] = Variable<String>(sourceId);
    }
    if (!nullToAbsent || ownerIds != null) {
      map['owner_ids'] = Variable<String>(ownerIds);
    }
    return map;
  }

  PlaylistsCompanion toCompanion(bool nullToAbsent) {
    return PlaylistsCompanion(
      id: Value(id),
      name: Value(name),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      createdAt: createdAt == null && nullToAbsent
          ? const Value.absent()
          : Value(createdAt),
      type: type == null && nullToAbsent ? const Value.absent() : Value(type),
      sourceId: sourceId == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceId),
      ownerIds: ownerIds == null && nullToAbsent
          ? const Value.absent()
          : Value(ownerIds),
    );
  }

  factory PlaylistEntity.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PlaylistEntity(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      description: serializer.fromJson<String?>(json['description']),
      createdAt: serializer.fromJson<int?>(json['createdAt']),
      type: serializer.fromJson<String?>(json['type']),
      sourceId: serializer.fromJson<String?>(json['sourceId']),
      ownerIds: serializer.fromJson<String?>(json['ownerIds']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'description': serializer.toJson<String?>(description),
      'createdAt': serializer.toJson<int?>(createdAt),
      'type': serializer.toJson<String?>(type),
      'sourceId': serializer.toJson<String?>(sourceId),
      'ownerIds': serializer.toJson<String?>(ownerIds),
    };
  }

  PlaylistEntity copyWith({
    String? id,
    String? name,
    Value<String?> description = const Value.absent(),
    Value<int?> createdAt = const Value.absent(),
    Value<String?> type = const Value.absent(),
    Value<String?> sourceId = const Value.absent(),
    Value<String?> ownerIds = const Value.absent(),
  }) => PlaylistEntity(
    id: id ?? this.id,
    name: name ?? this.name,
    description: description.present ? description.value : this.description,
    createdAt: createdAt.present ? createdAt.value : this.createdAt,
    type: type.present ? type.value : this.type,
    sourceId: sourceId.present ? sourceId.value : this.sourceId,
    ownerIds: ownerIds.present ? ownerIds.value : this.ownerIds,
  );
  PlaylistEntity copyWithCompanion(PlaylistsCompanion data) {
    return PlaylistEntity(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      description: data.description.present
          ? data.description.value
          : this.description,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      type: data.type.present ? data.type.value : this.type,
      sourceId: data.sourceId.present ? data.sourceId.value : this.sourceId,
      ownerIds: data.ownerIds.present ? data.ownerIds.value : this.ownerIds,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PlaylistEntity(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('createdAt: $createdAt, ')
          ..write('type: $type, ')
          ..write('sourceId: $sourceId, ')
          ..write('ownerIds: $ownerIds')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, name, description, createdAt, type, sourceId, ownerIds);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlaylistEntity &&
          other.id == this.id &&
          other.name == this.name &&
          other.description == this.description &&
          other.createdAt == this.createdAt &&
          other.type == this.type &&
          other.sourceId == this.sourceId &&
          other.ownerIds == this.ownerIds);
}

class PlaylistsCompanion extends UpdateCompanion<PlaylistEntity> {
  final Value<String> id;
  final Value<String> name;
  final Value<String?> description;
  final Value<int?> createdAt;
  final Value<String?> type;
  final Value<String?> sourceId;
  final Value<String?> ownerIds;
  final Value<int> rowid;
  const PlaylistsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.description = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.type = const Value.absent(),
    this.sourceId = const Value.absent(),
    this.ownerIds = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PlaylistsCompanion.insert({
    required String id,
    required String name,
    this.description = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.type = const Value.absent(),
    this.sourceId = const Value.absent(),
    this.ownerIds = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name);
  static Insertable<PlaylistEntity> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? description,
    Expression<int>? createdAt,
    Expression<String>? type,
    Expression<String>? sourceId,
    Expression<String>? ownerIds,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (createdAt != null) 'created_at': createdAt,
      if (type != null) 'type': type,
      if (sourceId != null) 'source_id': sourceId,
      if (ownerIds != null) 'owner_ids': ownerIds,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PlaylistsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String?>? description,
    Value<int?>? createdAt,
    Value<String?>? type,
    Value<String?>? sourceId,
    Value<String?>? ownerIds,
    Value<int>? rowid,
  }) {
    return PlaylistsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      type: type ?? this.type,
      sourceId: sourceId ?? this.sourceId,
      ownerIds: ownerIds ?? this.ownerIds,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (sourceId.present) {
      map['source_id'] = Variable<String>(sourceId.value);
    }
    if (ownerIds.present) {
      map['owner_ids'] = Variable<String>(ownerIds.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlaylistsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('createdAt: $createdAt, ')
          ..write('type: $type, ')
          ..write('sourceId: $sourceId, ')
          ..write('ownerIds: $ownerIds, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PlaylistTracksTable extends PlaylistTracks
    with TableInfo<$PlaylistTracksTable, PlaylistTrackEntity> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlaylistTracksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _playlistIdMeta = const VerificationMeta(
    'playlistId',
  );
  @override
  late final GeneratedColumn<String> playlistId = GeneratedColumn<String>(
    'playlist_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _trackIdMeta = const VerificationMeta(
    'trackId',
  );
  @override
  late final GeneratedColumn<String> trackId = GeneratedColumn<String>(
    'track_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _addedByMeta = const VerificationMeta(
    'addedBy',
  );
  @override
  late final GeneratedColumn<String> addedBy = GeneratedColumn<String>(
    'added_by',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _addedAtMeta = const VerificationMeta(
    'addedAt',
  );
  @override
  late final GeneratedColumn<int> addedAt = GeneratedColumn<int>(
    'added_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    playlistId,
    trackId,
    position,
    addedBy,
    addedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'playlist_tracks';
  @override
  VerificationContext validateIntegrity(
    Insertable<PlaylistTrackEntity> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('playlist_id')) {
      context.handle(
        _playlistIdMeta,
        playlistId.isAcceptableOrUnknown(data['playlist_id']!, _playlistIdMeta),
      );
    } else if (isInserting) {
      context.missing(_playlistIdMeta);
    }
    if (data.containsKey('track_id')) {
      context.handle(
        _trackIdMeta,
        trackId.isAcceptableOrUnknown(data['track_id']!, _trackIdMeta),
      );
    } else if (isInserting) {
      context.missing(_trackIdMeta);
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    if (data.containsKey('added_by')) {
      context.handle(
        _addedByMeta,
        addedBy.isAcceptableOrUnknown(data['added_by']!, _addedByMeta),
      );
    }
    if (data.containsKey('added_at')) {
      context.handle(
        _addedAtMeta,
        addedAt.isAcceptableOrUnknown(data['added_at']!, _addedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {playlistId, trackId};
  @override
  PlaylistTrackEntity map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PlaylistTrackEntity(
      playlistId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}playlist_id'],
      )!,
      trackId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}track_id'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
      addedBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}added_by'],
      ),
      addedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}added_at'],
      ),
    );
  }

  @override
  $PlaylistTracksTable createAlias(String alias) {
    return $PlaylistTracksTable(attachedDatabase, alias);
  }
}

class PlaylistTrackEntity extends DataClass
    implements Insertable<PlaylistTrackEntity> {
  final String playlistId;
  final String trackId;
  final int position;
  final String? addedBy;
  final int? addedAt;
  const PlaylistTrackEntity({
    required this.playlistId,
    required this.trackId,
    required this.position,
    this.addedBy,
    this.addedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['playlist_id'] = Variable<String>(playlistId);
    map['track_id'] = Variable<String>(trackId);
    map['position'] = Variable<int>(position);
    if (!nullToAbsent || addedBy != null) {
      map['added_by'] = Variable<String>(addedBy);
    }
    if (!nullToAbsent || addedAt != null) {
      map['added_at'] = Variable<int>(addedAt);
    }
    return map;
  }

  PlaylistTracksCompanion toCompanion(bool nullToAbsent) {
    return PlaylistTracksCompanion(
      playlistId: Value(playlistId),
      trackId: Value(trackId),
      position: Value(position),
      addedBy: addedBy == null && nullToAbsent
          ? const Value.absent()
          : Value(addedBy),
      addedAt: addedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(addedAt),
    );
  }

  factory PlaylistTrackEntity.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PlaylistTrackEntity(
      playlistId: serializer.fromJson<String>(json['playlistId']),
      trackId: serializer.fromJson<String>(json['trackId']),
      position: serializer.fromJson<int>(json['position']),
      addedBy: serializer.fromJson<String?>(json['addedBy']),
      addedAt: serializer.fromJson<int?>(json['addedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'playlistId': serializer.toJson<String>(playlistId),
      'trackId': serializer.toJson<String>(trackId),
      'position': serializer.toJson<int>(position),
      'addedBy': serializer.toJson<String?>(addedBy),
      'addedAt': serializer.toJson<int?>(addedAt),
    };
  }

  PlaylistTrackEntity copyWith({
    String? playlistId,
    String? trackId,
    int? position,
    Value<String?> addedBy = const Value.absent(),
    Value<int?> addedAt = const Value.absent(),
  }) => PlaylistTrackEntity(
    playlistId: playlistId ?? this.playlistId,
    trackId: trackId ?? this.trackId,
    position: position ?? this.position,
    addedBy: addedBy.present ? addedBy.value : this.addedBy,
    addedAt: addedAt.present ? addedAt.value : this.addedAt,
  );
  PlaylistTrackEntity copyWithCompanion(PlaylistTracksCompanion data) {
    return PlaylistTrackEntity(
      playlistId: data.playlistId.present
          ? data.playlistId.value
          : this.playlistId,
      trackId: data.trackId.present ? data.trackId.value : this.trackId,
      position: data.position.present ? data.position.value : this.position,
      addedBy: data.addedBy.present ? data.addedBy.value : this.addedBy,
      addedAt: data.addedAt.present ? data.addedAt.value : this.addedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PlaylistTrackEntity(')
          ..write('playlistId: $playlistId, ')
          ..write('trackId: $trackId, ')
          ..write('position: $position, ')
          ..write('addedBy: $addedBy, ')
          ..write('addedAt: $addedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(playlistId, trackId, position, addedBy, addedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlaylistTrackEntity &&
          other.playlistId == this.playlistId &&
          other.trackId == this.trackId &&
          other.position == this.position &&
          other.addedBy == this.addedBy &&
          other.addedAt == this.addedAt);
}

class PlaylistTracksCompanion extends UpdateCompanion<PlaylistTrackEntity> {
  final Value<String> playlistId;
  final Value<String> trackId;
  final Value<int> position;
  final Value<String?> addedBy;
  final Value<int?> addedAt;
  final Value<int> rowid;
  const PlaylistTracksCompanion({
    this.playlistId = const Value.absent(),
    this.trackId = const Value.absent(),
    this.position = const Value.absent(),
    this.addedBy = const Value.absent(),
    this.addedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PlaylistTracksCompanion.insert({
    required String playlistId,
    required String trackId,
    required int position,
    this.addedBy = const Value.absent(),
    this.addedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : playlistId = Value(playlistId),
       trackId = Value(trackId),
       position = Value(position);
  static Insertable<PlaylistTrackEntity> custom({
    Expression<String>? playlistId,
    Expression<String>? trackId,
    Expression<int>? position,
    Expression<String>? addedBy,
    Expression<int>? addedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (playlistId != null) 'playlist_id': playlistId,
      if (trackId != null) 'track_id': trackId,
      if (position != null) 'position': position,
      if (addedBy != null) 'added_by': addedBy,
      if (addedAt != null) 'added_at': addedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PlaylistTracksCompanion copyWith({
    Value<String>? playlistId,
    Value<String>? trackId,
    Value<int>? position,
    Value<String?>? addedBy,
    Value<int?>? addedAt,
    Value<int>? rowid,
  }) {
    return PlaylistTracksCompanion(
      playlistId: playlistId ?? this.playlistId,
      trackId: trackId ?? this.trackId,
      position: position ?? this.position,
      addedBy: addedBy ?? this.addedBy,
      addedAt: addedAt ?? this.addedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (playlistId.present) {
      map['playlist_id'] = Variable<String>(playlistId.value);
    }
    if (trackId.present) {
      map['track_id'] = Variable<String>(trackId.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (addedBy.present) {
      map['added_by'] = Variable<String>(addedBy.value);
    }
    if (addedAt.present) {
      map['added_at'] = Variable<int>(addedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlaylistTracksCompanion(')
          ..write('playlistId: $playlistId, ')
          ..write('trackId: $trackId, ')
          ..write('position: $position, ')
          ..write('addedBy: $addedBy, ')
          ..write('addedAt: $addedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$LocalDatabase extends GeneratedDatabase {
  _$LocalDatabase(QueryExecutor e) : super(e);
  $LocalDatabaseManager get managers => $LocalDatabaseManager(this);
  late final $TracksTable tracks = $TracksTable(this);
  late final $ListenEventsTable listenEvents = $ListenEventsTable(this);
  late final $GraphNodesTable graphNodes = $GraphNodesTable(this);
  late final $GraphEdgesTable graphEdges = $GraphEdgesTable(this);
  late final $PlaylistsTable playlists = $PlaylistsTable(this);
  late final $PlaylistTracksTable playlistTracks = $PlaylistTracksTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    tracks,
    listenEvents,
    graphNodes,
    graphEdges,
    playlists,
    playlistTracks,
  ];
}

typedef $$TracksTableCreateCompanionBuilder =
    TracksCompanion Function({
      required String id,
      required String title,
      required String artist,
      required String artistId,
      Value<String?> album,
      Value<String?> albumId,
      Value<String?> year,
      Value<String?> genres,
      Value<String?> tags,
      Value<String?> youtubeId,
      Value<String?> ytmBrowseId,
      Value<String?> spotifyId,
      Value<String?> sourceChannelId,
      Value<String?> artworkUrl,
      Value<String?> localArtworkPath,
      Value<double?> bpm,
      Value<double?> energy,
      Value<double?> danceability,
      Value<String?> key,
      Value<String?> mode,
      Value<int> playCount,
      Value<int> skipCount,
      Value<int> replayCount,
      Value<int?> lastPlayed,
      Value<bool> liked,
      Value<bool> downloaded,
      Value<String?> downloadedPath,
      Value<bool> cachedAudio,
      Value<double> graphScore,
      Value<int> rowid,
    });
typedef $$TracksTableUpdateCompanionBuilder =
    TracksCompanion Function({
      Value<String> id,
      Value<String> title,
      Value<String> artist,
      Value<String> artistId,
      Value<String?> album,
      Value<String?> albumId,
      Value<String?> year,
      Value<String?> genres,
      Value<String?> tags,
      Value<String?> youtubeId,
      Value<String?> ytmBrowseId,
      Value<String?> spotifyId,
      Value<String?> sourceChannelId,
      Value<String?> artworkUrl,
      Value<String?> localArtworkPath,
      Value<double?> bpm,
      Value<double?> energy,
      Value<double?> danceability,
      Value<String?> key,
      Value<String?> mode,
      Value<int> playCount,
      Value<int> skipCount,
      Value<int> replayCount,
      Value<int?> lastPlayed,
      Value<bool> liked,
      Value<bool> downloaded,
      Value<String?> downloadedPath,
      Value<bool> cachedAudio,
      Value<double> graphScore,
      Value<int> rowid,
    });

class $$TracksTableFilterComposer
    extends Composer<_$LocalDatabase, $TracksTable> {
  $$TracksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get artist => $composableBuilder(
    column: $table.artist,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get artistId => $composableBuilder(
    column: $table.artistId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get album => $composableBuilder(
    column: $table.album,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get albumId => $composableBuilder(
    column: $table.albumId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get year => $composableBuilder(
    column: $table.year,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get genres => $composableBuilder(
    column: $table.genres,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tags => $composableBuilder(
    column: $table.tags,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get youtubeId => $composableBuilder(
    column: $table.youtubeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ytmBrowseId => $composableBuilder(
    column: $table.ytmBrowseId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get spotifyId => $composableBuilder(
    column: $table.spotifyId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceChannelId => $composableBuilder(
    column: $table.sourceChannelId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get artworkUrl => $composableBuilder(
    column: $table.artworkUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get localArtworkPath => $composableBuilder(
    column: $table.localArtworkPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get bpm => $composableBuilder(
    column: $table.bpm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get energy => $composableBuilder(
    column: $table.energy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get danceability => $composableBuilder(
    column: $table.danceability,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mode => $composableBuilder(
    column: $table.mode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get playCount => $composableBuilder(
    column: $table.playCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get skipCount => $composableBuilder(
    column: $table.skipCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get replayCount => $composableBuilder(
    column: $table.replayCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastPlayed => $composableBuilder(
    column: $table.lastPlayed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get liked => $composableBuilder(
    column: $table.liked,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get downloaded => $composableBuilder(
    column: $table.downloaded,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get downloadedPath => $composableBuilder(
    column: $table.downloadedPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get cachedAudio => $composableBuilder(
    column: $table.cachedAudio,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get graphScore => $composableBuilder(
    column: $table.graphScore,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TracksTableOrderingComposer
    extends Composer<_$LocalDatabase, $TracksTable> {
  $$TracksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get artist => $composableBuilder(
    column: $table.artist,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get artistId => $composableBuilder(
    column: $table.artistId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get album => $composableBuilder(
    column: $table.album,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get albumId => $composableBuilder(
    column: $table.albumId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get year => $composableBuilder(
    column: $table.year,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get genres => $composableBuilder(
    column: $table.genres,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tags => $composableBuilder(
    column: $table.tags,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get youtubeId => $composableBuilder(
    column: $table.youtubeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ytmBrowseId => $composableBuilder(
    column: $table.ytmBrowseId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get spotifyId => $composableBuilder(
    column: $table.spotifyId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceChannelId => $composableBuilder(
    column: $table.sourceChannelId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get artworkUrl => $composableBuilder(
    column: $table.artworkUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get localArtworkPath => $composableBuilder(
    column: $table.localArtworkPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get bpm => $composableBuilder(
    column: $table.bpm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get energy => $composableBuilder(
    column: $table.energy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get danceability => $composableBuilder(
    column: $table.danceability,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mode => $composableBuilder(
    column: $table.mode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get playCount => $composableBuilder(
    column: $table.playCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get skipCount => $composableBuilder(
    column: $table.skipCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get replayCount => $composableBuilder(
    column: $table.replayCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastPlayed => $composableBuilder(
    column: $table.lastPlayed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get liked => $composableBuilder(
    column: $table.liked,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get downloaded => $composableBuilder(
    column: $table.downloaded,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get downloadedPath => $composableBuilder(
    column: $table.downloadedPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get cachedAudio => $composableBuilder(
    column: $table.cachedAudio,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get graphScore => $composableBuilder(
    column: $table.graphScore,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TracksTableAnnotationComposer
    extends Composer<_$LocalDatabase, $TracksTable> {
  $$TracksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get artist =>
      $composableBuilder(column: $table.artist, builder: (column) => column);

  GeneratedColumn<String> get artistId =>
      $composableBuilder(column: $table.artistId, builder: (column) => column);

  GeneratedColumn<String> get album =>
      $composableBuilder(column: $table.album, builder: (column) => column);

  GeneratedColumn<String> get albumId =>
      $composableBuilder(column: $table.albumId, builder: (column) => column);

  GeneratedColumn<String> get year =>
      $composableBuilder(column: $table.year, builder: (column) => column);

  GeneratedColumn<String> get genres =>
      $composableBuilder(column: $table.genres, builder: (column) => column);

  GeneratedColumn<String> get tags =>
      $composableBuilder(column: $table.tags, builder: (column) => column);

  GeneratedColumn<String> get youtubeId =>
      $composableBuilder(column: $table.youtubeId, builder: (column) => column);

  GeneratedColumn<String> get ytmBrowseId => $composableBuilder(
    column: $table.ytmBrowseId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get spotifyId =>
      $composableBuilder(column: $table.spotifyId, builder: (column) => column);

  GeneratedColumn<String> get sourceChannelId => $composableBuilder(
    column: $table.sourceChannelId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get artworkUrl => $composableBuilder(
    column: $table.artworkUrl,
    builder: (column) => column,
  );

  GeneratedColumn<String> get localArtworkPath => $composableBuilder(
    column: $table.localArtworkPath,
    builder: (column) => column,
  );

  GeneratedColumn<double> get bpm =>
      $composableBuilder(column: $table.bpm, builder: (column) => column);

  GeneratedColumn<double> get energy =>
      $composableBuilder(column: $table.energy, builder: (column) => column);

  GeneratedColumn<double> get danceability => $composableBuilder(
    column: $table.danceability,
    builder: (column) => column,
  );

  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get mode =>
      $composableBuilder(column: $table.mode, builder: (column) => column);

  GeneratedColumn<int> get playCount =>
      $composableBuilder(column: $table.playCount, builder: (column) => column);

  GeneratedColumn<int> get skipCount =>
      $composableBuilder(column: $table.skipCount, builder: (column) => column);

  GeneratedColumn<int> get replayCount => $composableBuilder(
    column: $table.replayCount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get lastPlayed => $composableBuilder(
    column: $table.lastPlayed,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get liked =>
      $composableBuilder(column: $table.liked, builder: (column) => column);

  GeneratedColumn<bool> get downloaded => $composableBuilder(
    column: $table.downloaded,
    builder: (column) => column,
  );

  GeneratedColumn<String> get downloadedPath => $composableBuilder(
    column: $table.downloadedPath,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get cachedAudio => $composableBuilder(
    column: $table.cachedAudio,
    builder: (column) => column,
  );

  GeneratedColumn<double> get graphScore => $composableBuilder(
    column: $table.graphScore,
    builder: (column) => column,
  );
}

class $$TracksTableTableManager
    extends
        RootTableManager<
          _$LocalDatabase,
          $TracksTable,
          TrackEntity,
          $$TracksTableFilterComposer,
          $$TracksTableOrderingComposer,
          $$TracksTableAnnotationComposer,
          $$TracksTableCreateCompanionBuilder,
          $$TracksTableUpdateCompanionBuilder,
          (
            TrackEntity,
            BaseReferences<_$LocalDatabase, $TracksTable, TrackEntity>,
          ),
          TrackEntity,
          PrefetchHooks Function()
        > {
  $$TracksTableTableManager(_$LocalDatabase db, $TracksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TracksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TracksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TracksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> artist = const Value.absent(),
                Value<String> artistId = const Value.absent(),
                Value<String?> album = const Value.absent(),
                Value<String?> albumId = const Value.absent(),
                Value<String?> year = const Value.absent(),
                Value<String?> genres = const Value.absent(),
                Value<String?> tags = const Value.absent(),
                Value<String?> youtubeId = const Value.absent(),
                Value<String?> ytmBrowseId = const Value.absent(),
                Value<String?> spotifyId = const Value.absent(),
                Value<String?> sourceChannelId = const Value.absent(),
                Value<String?> artworkUrl = const Value.absent(),
                Value<String?> localArtworkPath = const Value.absent(),
                Value<double?> bpm = const Value.absent(),
                Value<double?> energy = const Value.absent(),
                Value<double?> danceability = const Value.absent(),
                Value<String?> key = const Value.absent(),
                Value<String?> mode = const Value.absent(),
                Value<int> playCount = const Value.absent(),
                Value<int> skipCount = const Value.absent(),
                Value<int> replayCount = const Value.absent(),
                Value<int?> lastPlayed = const Value.absent(),
                Value<bool> liked = const Value.absent(),
                Value<bool> downloaded = const Value.absent(),
                Value<String?> downloadedPath = const Value.absent(),
                Value<bool> cachedAudio = const Value.absent(),
                Value<double> graphScore = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TracksCompanion(
                id: id,
                title: title,
                artist: artist,
                artistId: artistId,
                album: album,
                albumId: albumId,
                year: year,
                genres: genres,
                tags: tags,
                youtubeId: youtubeId,
                ytmBrowseId: ytmBrowseId,
                spotifyId: spotifyId,
                sourceChannelId: sourceChannelId,
                artworkUrl: artworkUrl,
                localArtworkPath: localArtworkPath,
                bpm: bpm,
                energy: energy,
                danceability: danceability,
                key: key,
                mode: mode,
                playCount: playCount,
                skipCount: skipCount,
                replayCount: replayCount,
                lastPlayed: lastPlayed,
                liked: liked,
                downloaded: downloaded,
                downloadedPath: downloadedPath,
                cachedAudio: cachedAudio,
                graphScore: graphScore,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String title,
                required String artist,
                required String artistId,
                Value<String?> album = const Value.absent(),
                Value<String?> albumId = const Value.absent(),
                Value<String?> year = const Value.absent(),
                Value<String?> genres = const Value.absent(),
                Value<String?> tags = const Value.absent(),
                Value<String?> youtubeId = const Value.absent(),
                Value<String?> ytmBrowseId = const Value.absent(),
                Value<String?> spotifyId = const Value.absent(),
                Value<String?> sourceChannelId = const Value.absent(),
                Value<String?> artworkUrl = const Value.absent(),
                Value<String?> localArtworkPath = const Value.absent(),
                Value<double?> bpm = const Value.absent(),
                Value<double?> energy = const Value.absent(),
                Value<double?> danceability = const Value.absent(),
                Value<String?> key = const Value.absent(),
                Value<String?> mode = const Value.absent(),
                Value<int> playCount = const Value.absent(),
                Value<int> skipCount = const Value.absent(),
                Value<int> replayCount = const Value.absent(),
                Value<int?> lastPlayed = const Value.absent(),
                Value<bool> liked = const Value.absent(),
                Value<bool> downloaded = const Value.absent(),
                Value<String?> downloadedPath = const Value.absent(),
                Value<bool> cachedAudio = const Value.absent(),
                Value<double> graphScore = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TracksCompanion.insert(
                id: id,
                title: title,
                artist: artist,
                artistId: artistId,
                album: album,
                albumId: albumId,
                year: year,
                genres: genres,
                tags: tags,
                youtubeId: youtubeId,
                ytmBrowseId: ytmBrowseId,
                spotifyId: spotifyId,
                sourceChannelId: sourceChannelId,
                artworkUrl: artworkUrl,
                localArtworkPath: localArtworkPath,
                bpm: bpm,
                energy: energy,
                danceability: danceability,
                key: key,
                mode: mode,
                playCount: playCount,
                skipCount: skipCount,
                replayCount: replayCount,
                lastPlayed: lastPlayed,
                liked: liked,
                downloaded: downloaded,
                downloadedPath: downloadedPath,
                cachedAudio: cachedAudio,
                graphScore: graphScore,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TracksTableProcessedTableManager =
    ProcessedTableManager<
      _$LocalDatabase,
      $TracksTable,
      TrackEntity,
      $$TracksTableFilterComposer,
      $$TracksTableOrderingComposer,
      $$TracksTableAnnotationComposer,
      $$TracksTableCreateCompanionBuilder,
      $$TracksTableUpdateCompanionBuilder,
      (TrackEntity, BaseReferences<_$LocalDatabase, $TracksTable, TrackEntity>),
      TrackEntity,
      PrefetchHooks Function()
    >;
typedef $$ListenEventsTableCreateCompanionBuilder =
    ListenEventsCompanion Function({
      required String id,
      required String trackId,
      required String eventType,
      required int timestamp,
      Value<int?> listenDurationSeconds,
      Value<String?> sourceUserId,
      Value<int> rowid,
    });
typedef $$ListenEventsTableUpdateCompanionBuilder =
    ListenEventsCompanion Function({
      Value<String> id,
      Value<String> trackId,
      Value<String> eventType,
      Value<int> timestamp,
      Value<int?> listenDurationSeconds,
      Value<String?> sourceUserId,
      Value<int> rowid,
    });

class $$ListenEventsTableFilterComposer
    extends Composer<_$LocalDatabase, $ListenEventsTable> {
  $$ListenEventsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get trackId => $composableBuilder(
    column: $table.trackId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get eventType => $composableBuilder(
    column: $table.eventType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get listenDurationSeconds => $composableBuilder(
    column: $table.listenDurationSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceUserId => $composableBuilder(
    column: $table.sourceUserId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ListenEventsTableOrderingComposer
    extends Composer<_$LocalDatabase, $ListenEventsTable> {
  $$ListenEventsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get trackId => $composableBuilder(
    column: $table.trackId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get eventType => $composableBuilder(
    column: $table.eventType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get listenDurationSeconds => $composableBuilder(
    column: $table.listenDurationSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceUserId => $composableBuilder(
    column: $table.sourceUserId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ListenEventsTableAnnotationComposer
    extends Composer<_$LocalDatabase, $ListenEventsTable> {
  $$ListenEventsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get trackId =>
      $composableBuilder(column: $table.trackId, builder: (column) => column);

  GeneratedColumn<String> get eventType =>
      $composableBuilder(column: $table.eventType, builder: (column) => column);

  GeneratedColumn<int> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);

  GeneratedColumn<int> get listenDurationSeconds => $composableBuilder(
    column: $table.listenDurationSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sourceUserId => $composableBuilder(
    column: $table.sourceUserId,
    builder: (column) => column,
  );
}

class $$ListenEventsTableTableManager
    extends
        RootTableManager<
          _$LocalDatabase,
          $ListenEventsTable,
          ListenEventEntity,
          $$ListenEventsTableFilterComposer,
          $$ListenEventsTableOrderingComposer,
          $$ListenEventsTableAnnotationComposer,
          $$ListenEventsTableCreateCompanionBuilder,
          $$ListenEventsTableUpdateCompanionBuilder,
          (
            ListenEventEntity,
            BaseReferences<
              _$LocalDatabase,
              $ListenEventsTable,
              ListenEventEntity
            >,
          ),
          ListenEventEntity,
          PrefetchHooks Function()
        > {
  $$ListenEventsTableTableManager(_$LocalDatabase db, $ListenEventsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ListenEventsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ListenEventsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ListenEventsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> trackId = const Value.absent(),
                Value<String> eventType = const Value.absent(),
                Value<int> timestamp = const Value.absent(),
                Value<int?> listenDurationSeconds = const Value.absent(),
                Value<String?> sourceUserId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ListenEventsCompanion(
                id: id,
                trackId: trackId,
                eventType: eventType,
                timestamp: timestamp,
                listenDurationSeconds: listenDurationSeconds,
                sourceUserId: sourceUserId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String trackId,
                required String eventType,
                required int timestamp,
                Value<int?> listenDurationSeconds = const Value.absent(),
                Value<String?> sourceUserId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ListenEventsCompanion.insert(
                id: id,
                trackId: trackId,
                eventType: eventType,
                timestamp: timestamp,
                listenDurationSeconds: listenDurationSeconds,
                sourceUserId: sourceUserId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ListenEventsTableProcessedTableManager =
    ProcessedTableManager<
      _$LocalDatabase,
      $ListenEventsTable,
      ListenEventEntity,
      $$ListenEventsTableFilterComposer,
      $$ListenEventsTableOrderingComposer,
      $$ListenEventsTableAnnotationComposer,
      $$ListenEventsTableCreateCompanionBuilder,
      $$ListenEventsTableUpdateCompanionBuilder,
      (
        ListenEventEntity,
        BaseReferences<_$LocalDatabase, $ListenEventsTable, ListenEventEntity>,
      ),
      ListenEventEntity,
      PrefetchHooks Function()
    >;
typedef $$GraphNodesTableCreateCompanionBuilder =
    GraphNodesCompanion Function({
      required String id,
      required String nodeType,
      Value<double> score,
      Value<int?> lastUpdated,
      Value<int> rowid,
    });
typedef $$GraphNodesTableUpdateCompanionBuilder =
    GraphNodesCompanion Function({
      Value<String> id,
      Value<String> nodeType,
      Value<double> score,
      Value<int?> lastUpdated,
      Value<int> rowid,
    });

class $$GraphNodesTableFilterComposer
    extends Composer<_$LocalDatabase, $GraphNodesTable> {
  $$GraphNodesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nodeType => $composableBuilder(
    column: $table.nodeType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get score => $composableBuilder(
    column: $table.score,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastUpdated => $composableBuilder(
    column: $table.lastUpdated,
    builder: (column) => ColumnFilters(column),
  );
}

class $$GraphNodesTableOrderingComposer
    extends Composer<_$LocalDatabase, $GraphNodesTable> {
  $$GraphNodesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nodeType => $composableBuilder(
    column: $table.nodeType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get score => $composableBuilder(
    column: $table.score,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastUpdated => $composableBuilder(
    column: $table.lastUpdated,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$GraphNodesTableAnnotationComposer
    extends Composer<_$LocalDatabase, $GraphNodesTable> {
  $$GraphNodesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get nodeType =>
      $composableBuilder(column: $table.nodeType, builder: (column) => column);

  GeneratedColumn<double> get score =>
      $composableBuilder(column: $table.score, builder: (column) => column);

  GeneratedColumn<int> get lastUpdated => $composableBuilder(
    column: $table.lastUpdated,
    builder: (column) => column,
  );
}

class $$GraphNodesTableTableManager
    extends
        RootTableManager<
          _$LocalDatabase,
          $GraphNodesTable,
          GraphNodeEntity,
          $$GraphNodesTableFilterComposer,
          $$GraphNodesTableOrderingComposer,
          $$GraphNodesTableAnnotationComposer,
          $$GraphNodesTableCreateCompanionBuilder,
          $$GraphNodesTableUpdateCompanionBuilder,
          (
            GraphNodeEntity,
            BaseReferences<_$LocalDatabase, $GraphNodesTable, GraphNodeEntity>,
          ),
          GraphNodeEntity,
          PrefetchHooks Function()
        > {
  $$GraphNodesTableTableManager(_$LocalDatabase db, $GraphNodesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GraphNodesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GraphNodesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GraphNodesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> nodeType = const Value.absent(),
                Value<double> score = const Value.absent(),
                Value<int?> lastUpdated = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => GraphNodesCompanion(
                id: id,
                nodeType: nodeType,
                score: score,
                lastUpdated: lastUpdated,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String nodeType,
                Value<double> score = const Value.absent(),
                Value<int?> lastUpdated = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => GraphNodesCompanion.insert(
                id: id,
                nodeType: nodeType,
                score: score,
                lastUpdated: lastUpdated,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$GraphNodesTableProcessedTableManager =
    ProcessedTableManager<
      _$LocalDatabase,
      $GraphNodesTable,
      GraphNodeEntity,
      $$GraphNodesTableFilterComposer,
      $$GraphNodesTableOrderingComposer,
      $$GraphNodesTableAnnotationComposer,
      $$GraphNodesTableCreateCompanionBuilder,
      $$GraphNodesTableUpdateCompanionBuilder,
      (
        GraphNodeEntity,
        BaseReferences<_$LocalDatabase, $GraphNodesTable, GraphNodeEntity>,
      ),
      GraphNodeEntity,
      PrefetchHooks Function()
    >;
typedef $$GraphEdgesTableCreateCompanionBuilder =
    GraphEdgesCompanion Function({
      required String fromId,
      required String toId,
      Value<double> weight,
      Value<int> rowid,
    });
typedef $$GraphEdgesTableUpdateCompanionBuilder =
    GraphEdgesCompanion Function({
      Value<String> fromId,
      Value<String> toId,
      Value<double> weight,
      Value<int> rowid,
    });

class $$GraphEdgesTableFilterComposer
    extends Composer<_$LocalDatabase, $GraphEdgesTable> {
  $$GraphEdgesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get fromId => $composableBuilder(
    column: $table.fromId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get toId => $composableBuilder(
    column: $table.toId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get weight => $composableBuilder(
    column: $table.weight,
    builder: (column) => ColumnFilters(column),
  );
}

class $$GraphEdgesTableOrderingComposer
    extends Composer<_$LocalDatabase, $GraphEdgesTable> {
  $$GraphEdgesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get fromId => $composableBuilder(
    column: $table.fromId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get toId => $composableBuilder(
    column: $table.toId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get weight => $composableBuilder(
    column: $table.weight,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$GraphEdgesTableAnnotationComposer
    extends Composer<_$LocalDatabase, $GraphEdgesTable> {
  $$GraphEdgesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get fromId =>
      $composableBuilder(column: $table.fromId, builder: (column) => column);

  GeneratedColumn<String> get toId =>
      $composableBuilder(column: $table.toId, builder: (column) => column);

  GeneratedColumn<double> get weight =>
      $composableBuilder(column: $table.weight, builder: (column) => column);
}

class $$GraphEdgesTableTableManager
    extends
        RootTableManager<
          _$LocalDatabase,
          $GraphEdgesTable,
          GraphEdgeEntity,
          $$GraphEdgesTableFilterComposer,
          $$GraphEdgesTableOrderingComposer,
          $$GraphEdgesTableAnnotationComposer,
          $$GraphEdgesTableCreateCompanionBuilder,
          $$GraphEdgesTableUpdateCompanionBuilder,
          (
            GraphEdgeEntity,
            BaseReferences<_$LocalDatabase, $GraphEdgesTable, GraphEdgeEntity>,
          ),
          GraphEdgeEntity,
          PrefetchHooks Function()
        > {
  $$GraphEdgesTableTableManager(_$LocalDatabase db, $GraphEdgesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GraphEdgesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GraphEdgesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GraphEdgesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> fromId = const Value.absent(),
                Value<String> toId = const Value.absent(),
                Value<double> weight = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => GraphEdgesCompanion(
                fromId: fromId,
                toId: toId,
                weight: weight,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String fromId,
                required String toId,
                Value<double> weight = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => GraphEdgesCompanion.insert(
                fromId: fromId,
                toId: toId,
                weight: weight,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$GraphEdgesTableProcessedTableManager =
    ProcessedTableManager<
      _$LocalDatabase,
      $GraphEdgesTable,
      GraphEdgeEntity,
      $$GraphEdgesTableFilterComposer,
      $$GraphEdgesTableOrderingComposer,
      $$GraphEdgesTableAnnotationComposer,
      $$GraphEdgesTableCreateCompanionBuilder,
      $$GraphEdgesTableUpdateCompanionBuilder,
      (
        GraphEdgeEntity,
        BaseReferences<_$LocalDatabase, $GraphEdgesTable, GraphEdgeEntity>,
      ),
      GraphEdgeEntity,
      PrefetchHooks Function()
    >;
typedef $$PlaylistsTableCreateCompanionBuilder =
    PlaylistsCompanion Function({
      required String id,
      required String name,
      Value<String?> description,
      Value<int?> createdAt,
      Value<String?> type,
      Value<String?> sourceId,
      Value<String?> ownerIds,
      Value<int> rowid,
    });
typedef $$PlaylistsTableUpdateCompanionBuilder =
    PlaylistsCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String?> description,
      Value<int?> createdAt,
      Value<String?> type,
      Value<String?> sourceId,
      Value<String?> ownerIds,
      Value<int> rowid,
    });

class $$PlaylistsTableFilterComposer
    extends Composer<_$LocalDatabase, $PlaylistsTable> {
  $$PlaylistsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceId => $composableBuilder(
    column: $table.sourceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ownerIds => $composableBuilder(
    column: $table.ownerIds,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PlaylistsTableOrderingComposer
    extends Composer<_$LocalDatabase, $PlaylistsTable> {
  $$PlaylistsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceId => $composableBuilder(
    column: $table.sourceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ownerIds => $composableBuilder(
    column: $table.ownerIds,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PlaylistsTableAnnotationComposer
    extends Composer<_$LocalDatabase, $PlaylistsTable> {
  $$PlaylistsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get sourceId =>
      $composableBuilder(column: $table.sourceId, builder: (column) => column);

  GeneratedColumn<String> get ownerIds =>
      $composableBuilder(column: $table.ownerIds, builder: (column) => column);
}

class $$PlaylistsTableTableManager
    extends
        RootTableManager<
          _$LocalDatabase,
          $PlaylistsTable,
          PlaylistEntity,
          $$PlaylistsTableFilterComposer,
          $$PlaylistsTableOrderingComposer,
          $$PlaylistsTableAnnotationComposer,
          $$PlaylistsTableCreateCompanionBuilder,
          $$PlaylistsTableUpdateCompanionBuilder,
          (
            PlaylistEntity,
            BaseReferences<_$LocalDatabase, $PlaylistsTable, PlaylistEntity>,
          ),
          PlaylistEntity,
          PrefetchHooks Function()
        > {
  $$PlaylistsTableTableManager(_$LocalDatabase db, $PlaylistsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlaylistsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PlaylistsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PlaylistsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<int?> createdAt = const Value.absent(),
                Value<String?> type = const Value.absent(),
                Value<String?> sourceId = const Value.absent(),
                Value<String?> ownerIds = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PlaylistsCompanion(
                id: id,
                name: name,
                description: description,
                createdAt: createdAt,
                type: type,
                sourceId: sourceId,
                ownerIds: ownerIds,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<String?> description = const Value.absent(),
                Value<int?> createdAt = const Value.absent(),
                Value<String?> type = const Value.absent(),
                Value<String?> sourceId = const Value.absent(),
                Value<String?> ownerIds = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PlaylistsCompanion.insert(
                id: id,
                name: name,
                description: description,
                createdAt: createdAt,
                type: type,
                sourceId: sourceId,
                ownerIds: ownerIds,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PlaylistsTableProcessedTableManager =
    ProcessedTableManager<
      _$LocalDatabase,
      $PlaylistsTable,
      PlaylistEntity,
      $$PlaylistsTableFilterComposer,
      $$PlaylistsTableOrderingComposer,
      $$PlaylistsTableAnnotationComposer,
      $$PlaylistsTableCreateCompanionBuilder,
      $$PlaylistsTableUpdateCompanionBuilder,
      (
        PlaylistEntity,
        BaseReferences<_$LocalDatabase, $PlaylistsTable, PlaylistEntity>,
      ),
      PlaylistEntity,
      PrefetchHooks Function()
    >;
typedef $$PlaylistTracksTableCreateCompanionBuilder =
    PlaylistTracksCompanion Function({
      required String playlistId,
      required String trackId,
      required int position,
      Value<String?> addedBy,
      Value<int?> addedAt,
      Value<int> rowid,
    });
typedef $$PlaylistTracksTableUpdateCompanionBuilder =
    PlaylistTracksCompanion Function({
      Value<String> playlistId,
      Value<String> trackId,
      Value<int> position,
      Value<String?> addedBy,
      Value<int?> addedAt,
      Value<int> rowid,
    });

class $$PlaylistTracksTableFilterComposer
    extends Composer<_$LocalDatabase, $PlaylistTracksTable> {
  $$PlaylistTracksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get playlistId => $composableBuilder(
    column: $table.playlistId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get trackId => $composableBuilder(
    column: $table.trackId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get addedBy => $composableBuilder(
    column: $table.addedBy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get addedAt => $composableBuilder(
    column: $table.addedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PlaylistTracksTableOrderingComposer
    extends Composer<_$LocalDatabase, $PlaylistTracksTable> {
  $$PlaylistTracksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get playlistId => $composableBuilder(
    column: $table.playlistId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get trackId => $composableBuilder(
    column: $table.trackId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get addedBy => $composableBuilder(
    column: $table.addedBy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get addedAt => $composableBuilder(
    column: $table.addedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PlaylistTracksTableAnnotationComposer
    extends Composer<_$LocalDatabase, $PlaylistTracksTable> {
  $$PlaylistTracksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get playlistId => $composableBuilder(
    column: $table.playlistId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get trackId =>
      $composableBuilder(column: $table.trackId, builder: (column) => column);

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  GeneratedColumn<String> get addedBy =>
      $composableBuilder(column: $table.addedBy, builder: (column) => column);

  GeneratedColumn<int> get addedAt =>
      $composableBuilder(column: $table.addedAt, builder: (column) => column);
}

class $$PlaylistTracksTableTableManager
    extends
        RootTableManager<
          _$LocalDatabase,
          $PlaylistTracksTable,
          PlaylistTrackEntity,
          $$PlaylistTracksTableFilterComposer,
          $$PlaylistTracksTableOrderingComposer,
          $$PlaylistTracksTableAnnotationComposer,
          $$PlaylistTracksTableCreateCompanionBuilder,
          $$PlaylistTracksTableUpdateCompanionBuilder,
          (
            PlaylistTrackEntity,
            BaseReferences<
              _$LocalDatabase,
              $PlaylistTracksTable,
              PlaylistTrackEntity
            >,
          ),
          PlaylistTrackEntity,
          PrefetchHooks Function()
        > {
  $$PlaylistTracksTableTableManager(
    _$LocalDatabase db,
    $PlaylistTracksTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlaylistTracksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PlaylistTracksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PlaylistTracksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> playlistId = const Value.absent(),
                Value<String> trackId = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<String?> addedBy = const Value.absent(),
                Value<int?> addedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PlaylistTracksCompanion(
                playlistId: playlistId,
                trackId: trackId,
                position: position,
                addedBy: addedBy,
                addedAt: addedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String playlistId,
                required String trackId,
                required int position,
                Value<String?> addedBy = const Value.absent(),
                Value<int?> addedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PlaylistTracksCompanion.insert(
                playlistId: playlistId,
                trackId: trackId,
                position: position,
                addedBy: addedBy,
                addedAt: addedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PlaylistTracksTableProcessedTableManager =
    ProcessedTableManager<
      _$LocalDatabase,
      $PlaylistTracksTable,
      PlaylistTrackEntity,
      $$PlaylistTracksTableFilterComposer,
      $$PlaylistTracksTableOrderingComposer,
      $$PlaylistTracksTableAnnotationComposer,
      $$PlaylistTracksTableCreateCompanionBuilder,
      $$PlaylistTracksTableUpdateCompanionBuilder,
      (
        PlaylistTrackEntity,
        BaseReferences<
          _$LocalDatabase,
          $PlaylistTracksTable,
          PlaylistTrackEntity
        >,
      ),
      PlaylistTrackEntity,
      PrefetchHooks Function()
    >;

class $LocalDatabaseManager {
  final _$LocalDatabase _db;
  $LocalDatabaseManager(this._db);
  $$TracksTableTableManager get tracks =>
      $$TracksTableTableManager(_db, _db.tracks);
  $$ListenEventsTableTableManager get listenEvents =>
      $$ListenEventsTableTableManager(_db, _db.listenEvents);
  $$GraphNodesTableTableManager get graphNodes =>
      $$GraphNodesTableTableManager(_db, _db.graphNodes);
  $$GraphEdgesTableTableManager get graphEdges =>
      $$GraphEdgesTableTableManager(_db, _db.graphEdges);
  $$PlaylistsTableTableManager get playlists =>
      $$PlaylistsTableTableManager(_db, _db.playlists);
  $$PlaylistTracksTableTableManager get playlistTracks =>
      $$PlaylistTracksTableTableManager(_db, _db.playlistTracks);
}
