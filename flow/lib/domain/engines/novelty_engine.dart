import '../entities/track.dart';

enum SourceType { artist, album, creator }

class RankedSource {
  final String id;
  final SourceType type;
  double score;

  RankedSource({
    required this.id,
    required this.type,
    this.score = 0.0,
  });
}

class NoveltyEngine {
  List<RankedSource> buildSourceRanking(List<Track> fromTracks) {
    final sources = <String, RankedSource>{};
    
    for (final t in fromTracks) {
      final w = _calculateTrackWeight(t);
      
      _accumulate(sources, t.artistId, SourceType.artist, w * 1.0);
      if (t.albumId != null) {
        _accumulate(sources, t.albumId!, SourceType.album, w * 0.6);
      }
      if (t.sourceChannelId != null) {
        _accumulate(sources, t.sourceChannelId!, SourceType.creator, w * 0.5);
      }
    }
    
    final result = sources.values.toList();
    result.sort((a, b) => b.score.compareTo(a.score));
    return result;
  }

  double _calculateTrackWeight(Track t) {
    // liked×3 + plays×0.5 + replays×1 - skips×0.3
    double w = 0.5; // baseline
    if (t.liked) w += 3.0;
    w += t.playCount * 0.5;
    w += t.replayCount * 1.0;
    w -= t.skipCount * 0.3;
    return w;
  }

  void _accumulate(Map<String, RankedSource> sources, String id, SourceType type, double delta) {
    final key = '${type.name}:$id';
    final src = sources[key] ??= RankedSource(id: id, type: type);
    src.score += delta;
  }

  // Note: fetchNovel and _fetchFromSource will require a MusicSourceAdapter 
  // which will be implemented in the Data layer later.
}
