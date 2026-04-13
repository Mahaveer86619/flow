import 'song.dart';

class HistoryData {
  final List<Song> today;
  final List<Song> thisWeek;
  final List<Song> thisMonth;
  final Map<String, List<Song>> byMonth;

  const HistoryData({
    required this.today,
    required this.thisWeek,
    required this.thisMonth,
    required this.byMonth,
  });

  const HistoryData.empty()
    : today = const [],
      thisWeek = const [],
      thisMonth = const [],
      byMonth = const {};
}
