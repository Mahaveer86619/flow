import '../entities/track.dart';

enum Mood { chill, energetic, focus, workout }

class MoodEngine {
  List<Track> filterByMood(List<Track> tracks, Mood mood) {
    return tracks.where((t) {
      if (t.audio == null) return true; // Keep if no audio features to avoid over-filtering
      
      final features = t.audio!;
      return switch (mood) {
        Mood.chill => features.energy < 0.4 && features.bpm < 100,
        Mood.energetic => features.energy > 0.7,
        Mood.focus => features.energy < 0.5 && features.danceability < 0.5,
        Mood.workout => features.energy > 0.8 && features.bpm > 120,
      };
    }).toList();
  }
}
