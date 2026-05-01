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
    final familiarCount = (familiarTracks.length * ratio).floor();
    final novelCount = novelTracks.length; // We take what we have
    
    // Interleave novel tracks, not clumped
    // Example for radio (55/45): [F N F N F N ...]
    
    final fIter = familiarTracks.iterator;
    final nIter = novelTracks.iterator;
    
    int fIndex = 0;
    int nIndex = 0;
    
    double currentRatio = 0.0;
    
    while (fIter.moveNext() || nIter.moveNext()) {
      bool shouldTakeNovel = false;
      
      if (!fIter.moveNext()) {
        shouldTakeNovel = true;
      } else if (!nIter.moveNext()) {
        shouldTakeNovel = false;
      } else {
        // Decide based on target ratio
        // currentRatio = nIndex / (fIndex + nIndex)
        // If currentRatio < targetNovelRatio, take novel
        final targetNovelRatio = 1.0 - ratio;
        if ((nIndex + fIndex) == 0) {
          shouldTakeNovel = false; // start with familiar
        } else {
          shouldTakeNovel = (nIndex / (fIndex + nIndex)) < targetNovelRatio;
        }
      }
      
      if (shouldTakeNovel && nIter.current != null) {
        result.add(nIter.current);
        nIndex++;
      } else if (fIter.current != null) {
        result.add(fIter.current);
        fIndex++;
      }
      
      // Safety break
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
