import '../entities/track.dart';

enum QueueMode { listenAgain, radio, discovery }

class QueueBuilder {
  /// familiar/novel ratio per mode:
  /// listenAgain → 85% / 15%  (resuming library feels safe)
  /// radio       → 55% / 45%  (balanced exploration)
  /// discovery   → 20% / 80%  (new music session)
  List<Track> build({
    required List<Track> familiarTracks,
    required List<Track> novelTracks,
    required QueueMode mode,
  }) {
    final result = <Track>[];
    
    final ratio = _getRatio(mode);
    
    final fIter = familiarTracks.iterator;
    final nIter = novelTracks.iterator;
    
    int fIndex = 0;
    int nIndex = 0;
    
    while (fIter.moveNext() || nIter.moveNext()) {
      bool shouldTakeNovel = false;
      
      final hasFamiliar = fIndex < familiarTracks.length;
      final hasNovel = nIndex < novelTracks.length;

      if (!hasFamiliar) {
        shouldTakeNovel = true;
      } else if (!hasNovel) {
        shouldTakeNovel = false;
      } else {
        final targetNovelRatio = 1.0 - ratio;
        if ((nIndex + fIndex) == 0) {
          shouldTakeNovel = false; // start with familiar
        } else {
          shouldTakeNovel = (nIndex / (fIndex + nIndex)) < targetNovelRatio;
        }
      }
      
      if (shouldTakeNovel && nIndex < novelTracks.length) {
        result.add(novelTracks[nIndex]);
        nIndex++;
      } else if (fIndex < familiarTracks.length) {
        result.add(familiarTracks[fIndex]);
        fIndex++;
      }
      
      if (result.length >= familiarTracks.length + novelTracks.length) break;
    }

    return result;
  }

  double _getRatio(QueueMode mode) => switch (mode) {
        QueueMode.listenAgain => 0.85,
        QueueMode.radio => 0.55,
        QueueMode.discovery => 0.20,
      };
}
