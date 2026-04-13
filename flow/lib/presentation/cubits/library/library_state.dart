import 'package:equatable/equatable.dart';
import '../../../core/error/app_exception.dart';
import '../../../domain/entities/song.dart';

class LibraryState extends Equatable {
  final bool isLoading;
  final bool error;
  final AppErrorType errorType;
  final List<Playlist> playlists;
  final List<Song> downloadedSongs;
  final List<Song> likedSongs;
  final List<Song> remoteLikedSongs;

  const LibraryState({
    this.isLoading = false,
    this.error = false,
    this.errorType = AppErrorType.unknown,
    required this.playlists,
    this.downloadedSongs = const [],
    this.likedSongs = const [],
    this.remoteLikedSongs = const [],
  });

  LibraryState copyWith({
    bool? isLoading,
    bool? error,
    AppErrorType? errorType,
    List<Playlist>? playlists,
    List<Song>? downloadedSongs,
    List<Song>? likedSongs,
    List<Song>? remoteLikedSongs,
  }) => LibraryState(
    isLoading: isLoading ?? this.isLoading,
    error: error ?? this.error,
    errorType: errorType ?? this.errorType,
    playlists: playlists ?? this.playlists,
    downloadedSongs: downloadedSongs ?? this.downloadedSongs,
    likedSongs: likedSongs ?? this.likedSongs,
    remoteLikedSongs: remoteLikedSongs ?? this.remoteLikedSongs,
  );

  @override
  List<Object?> get props => [
    isLoading,
    error,
    errorType,
    playlists,
    downloadedSongs,
    likedSongs,
    remoteLikedSongs,
  ];
}
