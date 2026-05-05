import '../entities/taste_profile.dart';
import '../entities/scoring_graph.dart';

class TasteBlendEngine {
  // Produces a synthetic TasteProfile from two users' graphs
  TasteProfile computeBlend(
    ScoringGraph myGraph,
    Map<String, double> friendNodeScores, // received delta/scores
    {
      double myWeight = 0.5,
      double friendWeight = 0.5,
    }
  ) {
    final blendedArtists = <String, double>{};
    final blendedGenres = <String, double>{};
    final blendedTags = <String, double>{};

    // Merge artist nodes
    final myArtistIds = myGraph.nodes.values
        .where((n) => n.type == NodeType.artist)
        .map((n) => n.id.replaceFirst('artist:', ''))
        .toSet();
    
    final friendArtistIds = friendNodeScores.keys
        .where((k) => k.startsWith('artist:'))
        .map((k) => k.replaceFirst('artist:', ''))
        .toSet();

    final allArtistIds = {...myArtistIds, ...friendArtistIds};

    for (final id in allArtistIds) {
      final myScore = myGraph.nodes['artist:$id']?.score ?? 0;
      final friendScore = friendNodeScores['artist:$id'] ?? 0;
      blendedArtists[id] = (myScore * myWeight) + (friendScore * friendWeight);
    }

    // Merge genres
    final myGenreIds = myGraph.nodes.values
        .where((n) => n.type == NodeType.genre)
        .map((n) => n.id.replaceFirst('genre:', ''))
        .toSet();
    
    final friendGenreIds = friendNodeScores.keys
        .where((k) => k.startsWith('genre:'))
        .map((k) => k.replaceFirst('genre:', ''))
        .toSet();
    
    final allGenreIds = {...myGenreIds, ...friendGenreIds};

    for (final id in allGenreIds) {
      final myScore = myGraph.nodes['genre:$id']?.score ?? 0;
      final friendScore = friendNodeScores['genre:$id'] ?? 0;
      blendedGenres[id] = (myScore * myWeight) + (friendScore * friendWeight);
    }

    return TasteProfile(
      artistScores: blendedArtists,
      genreScores: blendedGenres,
      tagScores: blendedTags, // TODO: Merge tags as well
    );
  }
}
