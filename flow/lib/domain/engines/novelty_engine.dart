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

  Future<List<Track>> fetchNovel({
    required List<RankedSource> sources,
    required Set<String> exclude,
    required Future<List<Track>> Function(RankedSource) fetcher,
    int limit = 30,
  }) async {
    final results = <Track>[];
    for (final src in sources.take(10)) {
      final candidates = await fetcher(src);
      results.addAll(candidates.where((t) => !exclude.contains(t.id)));
      if (results.length >= limit * 2) break;
    }
    
    // Sort by some heuristic or shuffle
    results.shuffle();
    return results.take(limit).toList();
  }
}

