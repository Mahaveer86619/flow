class TasteProfile {
  final Map<String, double> artistScores;
  final Map<String, double> genreScores;
  final Map<String, double> tagScores;

  const TasteProfile({
    this.artistScores = const {},
    this.genreScores = const {},
    this.tagScores = const {},
  });

  factory TasteProfile.fromGraph(Map<String, double> nodeScores) {
    final artists = <String, double>{};
    final genres = <String, double>{};
    final tags = <String, double>{};

    nodeScores.forEach((id, score) {
      if (id.startsWith('artist:')) {
        artists[id.replaceFirst('artist:', '')] = score;
      } else if (id.startsWith('genre:')) {
        genres[id.replaceFirst('genre:', '')] = score;
      } else if (id.startsWith('tag:')) {
        tags[id.replaceFirst('tag:', '')] = score;
      }
    });

    return TasteProfile(
      artistScores: artists,
      genreScores: genres,
      tagScores: tags,
    );
  }
}
