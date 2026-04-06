import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'models/song.dart';

class PlayerController extends ChangeNotifier {
  Song? _currentSong;
  bool _isPlaying = false;
  double _progress = 0.0;
  bool _isShuffle = false;
  bool _isRepeat = false;
  double _volume = 0.7;

  final Set<String> _likedSongIds = {};
  final List<Song> _recentlyPlayed = [];
  List<Song> _queue = [];
  int _queueIndex = -1;

  Timer? _progressTimer;

  Song? get currentSong => _currentSong;
  bool get isPlaying => _isPlaying;
  double get progress => _progress;
  bool get isShuffle => _isShuffle;
  bool get isRepeat => _isRepeat;
  double get volume => _volume;
  int get likedSongsCount => _likedSongIds.length;
  List<Song> get recentlyPlayed => List.unmodifiable(_recentlyPlayed);

  bool isLiked(Song song) => _likedSongIds.contains(song.id);

  String get currentTimeString {
    if (_currentSong == null) return '0:00';
    final total = _currentSong!.duration.inSeconds;
    final current = (total * _progress).round();
    return '${current ~/ 60}:${(current % 60).toString().padLeft(2, '0')}';
  }

  String get totalTimeString {
    if (_currentSong == null) return '0:00';
    final total = _currentSong!.duration.inSeconds;
    return '${total ~/ 60}:${(total % 60).toString().padLeft(2, '0')}';
  }

  void playQueue(List<Song> songs, {int startIndex = 0}) {
    _queue = List.from(songs);
    _queueIndex = startIndex.clamp(0, songs.length - 1);
    _playSong(_queue[_queueIndex]);
  }

  void play(Song song) {
    _queue = [song];
    _queueIndex = 0;
    _playSong(song);
  }

  void _playSong(Song song) {
    _currentSong = song;
    _isPlaying = true;
    _progress = 0.0;
    _recentlyPlayed.removeWhere((s) => s.id == song.id);
    _recentlyPlayed.insert(0, song);
    if (_recentlyPlayed.length > 20) _recentlyPlayed.removeLast();
    _startTimer();
    notifyListeners();
  }

  void togglePlayPause() {
    if (_isPlaying) {
      _isPlaying = false;
      _progressTimer?.cancel();
    } else {
      _isPlaying = true;
      _startTimer();
    }
    notifyListeners();
  }

  void seekTo(double value) {
    _progress = value.clamp(0.0, 1.0);
    notifyListeners();
  }

  void next() {
    if (_queue.isEmpty) return;
    if (_isShuffle) {
      _queueIndex = Random().nextInt(_queue.length);
    } else {
      _queueIndex = (_queueIndex + 1) % _queue.length;
    }
    _playSong(_queue[_queueIndex]);
  }

  void previous() {
    if (_progress > 0.05) {
      seekTo(0.0);
      return;
    }
    if (_queue.isEmpty) return;
    _queueIndex = (_queueIndex - 1 + _queue.length) % _queue.length;
    _playSong(_queue[_queueIndex]);
  }

  void toggleShuffle() {
    _isShuffle = !_isShuffle;
    notifyListeners();
  }

  void toggleRepeat() {
    _isRepeat = !_isRepeat;
    notifyListeners();
  }

  void toggleLike(Song song) {
    if (_likedSongIds.contains(song.id)) {
      _likedSongIds.remove(song.id);
    } else {
      _likedSongIds.add(song.id);
    }
    notifyListeners();
  }

  void setVolume(double value) {
    _volume = value.clamp(0.0, 1.0);
    notifyListeners();
  }

  void _startTimer() {
    _progressTimer?.cancel();
    if (_currentSong == null) return;

    final totalMs = _currentSong!.duration.inMilliseconds;
    const tickMs = 500;

    _progressTimer = Timer.periodic(const Duration(milliseconds: tickMs), (_) {
      if (!_isPlaying) return;
      _progress += tickMs / totalMs;
      if (_progress >= 1.0) {
        if (_isRepeat) {
          _progress = 0.0;
        } else if (_queue.length > 1) {
          next();
          return;
        } else {
          _progress = 1.0;
          _isPlaying = false;
          _progressTimer?.cancel();
        }
      }
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    super.dispose();
  }
}
