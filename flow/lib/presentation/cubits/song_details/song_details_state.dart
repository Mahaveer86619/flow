import 'package:equatable/equatable.dart';

enum SongDetailsStatus { idle, loading, success, error }

class SongDetailsState extends Equatable {
  final SongDetailsStatus status;
  final String? videoId;
  final Map<String, dynamic> songDetails;
  final Map<String, dynamic> artistDetails;
  final String? error;

  const SongDetailsState({
    this.status = SongDetailsStatus.idle,
    this.videoId,
    this.songDetails = const {},
    this.artistDetails = const {},
    this.error,
  });

  bool get isLoading => status == SongDetailsStatus.loading;
  bool get isSuccess => status == SongDetailsStatus.success;
  bool get isError => status == SongDetailsStatus.error;

  String? get biography => artistDetails['biography'] as String?;
  String? get songDescription => songDetails['description'] as String?;
  String? get artistThumbnail => artistDetails['thumbnailUrl'] as String?;

  SongDetailsState copyWith({
    SongDetailsStatus? status,
    String? videoId,
    Map<String, dynamic>? songDetails,
    Map<String, dynamic>? artistDetails,
    String? error,
  }) {
    return SongDetailsState(
      status: status ?? this.status,
      videoId: videoId ?? this.videoId,
      songDetails: songDetails ?? this.songDetails,
      artistDetails: artistDetails ?? this.artistDetails,
      error: error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [status, videoId, songDetails, artistDetails, error];
}
