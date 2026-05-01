import '../entities/track.dart';
import '../entities/taste_profile.dart';

class RecommendationEngine {
  double scoreSimilarity(Track a, Track b, TasteProfile profile) {
    double score = 0;

    if (a.artistId == b.artistId) score += 2.0;
    if (a.albumId != null && a.albumId == b.albumId) score += 1.0;
    
    score += _jaccard(a.genres, b.genres) * 1.5;
    score += _jaccard(a.tags, b.tags) * 1.2;

    if (a.audio != null && b.audio != null) {
      score += (1 - (a.audio!.bpm - b.audio!.bpm).abs() / 200).clamp(0, 1) * 0.8;
      score += (1 - (a.audio!.energy - b.audio!.energy).abs()).clamp(0, 1) * 0.6;
    }

    // Boost by user's established affinity for this artist from the graph
    final artistAffinity = profile.artistScores[b.artistId] ?? 0.5;
    score *= artistAffinity.clamp(0.1, 5.0);
    
    return score;
  }

  double _jaccard(List<String> a, List<String> b) {
    if (a.isEmpty && b.isEmpty) return 1.0;
    if (a.isEmpty || b.isEmpty) return 0.0;
    
    final setA = a.toSet();
    final setB = b.toSet();
    
    final intersection = setA.intersection(setB).length;
    final union = setA.union(setB).length;
    
    return intersection / union;
  }
}
